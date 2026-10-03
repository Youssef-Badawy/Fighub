import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthManager extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoggedIn = false;
  String _name = '';
  String _email = '';
  String _phone = '';

  bool get isLoggedIn => _isLoggedIn;
  String get name => _name;
  String get email => _email;
  String get phone => _phone;

  Future<void> load() async {
    final user = _auth.currentUser;

    if (user == null) {
      _isLoggedIn = false;
      _name = '';
      _email = '';
      _phone = '';
      notifyListeners();
      return;
    }

    _isLoggedIn = true;
    _email = user.email ?? '';
    _phone = user.phoneNumber ?? '';

    try {
      final document = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (document.exists) {
        final data = document.data();

        _name = data?['name'] as String? ?? '';
        _phone = data?['phone'] as String? ?? _phone;
      } else {
        _name = user.displayName ?? '';
      }
    } catch (_) {
      _name = user.displayName ?? '';
    }

    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
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

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _isLoggedIn = true;
    _name = name;
    _email = email;
    _phone = phone;

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
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

    final document = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (document.exists) {
      final data = document.data();

      _name = data?['name'] as String? ?? '';
      _phone = data?['phone'] as String? ?? _phone;
    } else {
      _name = user.displayName ?? '';
    }

    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();

    _isLoggedIn = false;
    _name = '';
    _email = '';
    _phone = '';

    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
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

    await _firestore.collection('users').doc(user.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _name = name;
    _email = email;
    _phone = phone;

    notifyListeners();
  }
}