import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;

  const SellerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
  });

  factory SellerProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return SellerProfile(
      id: document.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
    );
  }
}

class SellerProfileService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _sellerProfilesCollection {
    return _firestore.collection('seller_profiles');
  }

  Future<void> saveMyProfile({
    required String name,
    required String email,
    required String phone,
    required String photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    await _sellerProfilesCollection.doc(user.uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<SellerProfile?> getSellerProfile(
    String sellerId,
  ) async {
    if (sellerId.isEmpty) {
      return null;
    }

    final document =
        await _sellerProfilesCollection.doc(sellerId).get();

    if (!document.exists) {
      return null;
    }

    return SellerProfile.fromFirestore(document);
  }

  Stream<SellerProfile?> watchSellerProfile(
    String sellerId,
  ) {
    if (sellerId.isEmpty) {
      return const Stream<SellerProfile?>.empty();
    }

    return _sellerProfilesCollection
        .doc(sellerId)
        .snapshots()
        .map((document) {
      if (!document.exists) {
        return null;
      }

      return SellerProfile.fromFirestore(document);
    });
  }
}