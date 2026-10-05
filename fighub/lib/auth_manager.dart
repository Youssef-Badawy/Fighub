import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';
import 'seller_profile_service.dart';

class AuthManager extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService =
      CloudinaryService();
  final SellerProfileService _sellerProfileService =
      SellerProfileService();

  bool _isLoggedIn = false;
  String _name = '';
  String _email = '';
  String _phone = '';
  String _photoUrl = '';
  List<String> _interests = [];

  bool get isLoggedIn => _isLoggedIn;
  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String get photoUrl => _photoUrl;
  List<String> get interests => List.unmodifiable(_interests);

  Future<void> load() async {
    final user = _auth.currentUser;

    if (user == null) {
      _isLoggedIn = false;
      _name = '';
      _email = '';
      _phone = '';
      _photoUrl = '';
      _interests = [];
      notifyListeners();
      return;
    }

    _isLoggedIn = true;
    _email = user.email ?? '';
    _phone = user.phoneNumber ?? '';
    _photoUrl = user.photoURL ?? '';

    try {
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (document.exists) {
        final data = document.data();

        _name = data?['name'] as String? ?? '';
        _phone =
            data?['phone'] as String? ?? _phone;
        _photoUrl =
            data?['photoUrl'] as String? ?? _photoUrl;

        final rawInterests = data?['interests'];

        _interests = rawInterests is List
            ? rawInterests.whereType<String>().toList()
            : [];
      } else {
        _name = user.displayName ?? '';
        _interests = [];
      }
    } catch (_) {
      _name = user.displayName ?? '';
      _interests = [];
    }

    await _syncSellerProfile();

    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    List<String> interests = const [],
  }) async {
    final credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Unable to create the account.',
      );
    }

    await user.updateDisplayName(name);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': '',
      'interests': interests,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _isLoggedIn = true;
    _name = name;
    _email = email;
    _phone = phone;
    _photoUrl = '';
    _interests = List<String>.from(interests);

    await _syncSellerProfile();

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final credential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to sign in.',
      );
    }

    _isLoggedIn = true;
    _email = user.email ?? email;
    _phone = user.phoneNumber ?? '';
    _photoUrl = user.photoURL ?? '';

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (document.exists) {
      final data = document.data();

      _name = data?['name'] as String? ?? '';
      _phone =
          data?['phone'] as String? ?? _phone;
      _photoUrl =
          data?['photoUrl'] as String? ?? _photoUrl;

      final rawInterests = data?['interests'];

      _interests = rawInterests is List
          ? rawInterests.whereType<String>().toList()
          : [];
    } else {
      _name = user.displayName ?? '';
      _interests = [];
    }

    await _syncSellerProfile();

    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();

    _isLoggedIn = false;
    _name = '';
    _email = '';
    _phone = '';
    _photoUrl = '';
    _interests = [];

    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    List<String>? interests,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not signed in.',
      );
    }

    if (email != user.email && email.isNotEmpty) {
      await user.verifyBeforeUpdateEmail(email);
    }

    await user.updateDisplayName(name);

    final updates = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': _photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (interests != null) {
      updates['interests'] = interests;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(
          updates,
          SetOptions(merge: true),
        );

    _name = name;
    _email = email;
    _phone = phone;

    if (interests != null) {
      _interests = List<String>.from(interests);
    }

    await _syncSellerProfile();

    notifyListeners();
  }

  Future<void> updateInterests(
    List<String> interests,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not signed in.',
      );
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'interests': interests,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _interests = List<String>.from(interests);

    notifyListeners();
  }

  Future<void> updateProfilePhoto(
    XFile imageFile,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not signed in.',
      );
    }

    final imageUrl =
        await _cloudinaryService.uploadImage(imageFile);

    await user.updatePhotoURL(imageUrl);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set({
      'photoUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _photoUrl = imageUrl;

    await _syncSellerProfile();

    notifyListeners();
  }

  Future<void> _syncSellerProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _sellerProfileService.saveMyProfile(
        name: _name,
        email: _email,
        phone: _phone,
        photoUrl: _photoUrl,
      );
    } catch (_) {
      // Keep authentication working even if
      // the public seller profile sync fails.
    }
  }
}
