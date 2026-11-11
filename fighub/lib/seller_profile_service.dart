import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final String bio;
  final String coverUrl;

  const SellerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    this.bio = '',
    this.coverUrl = '',
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
      bio: data['bio'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
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
    required String phone,
    required String photoUrl,
    String bio = '',
    String coverUrl = '',
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    await _sellerProfilesCollection.doc(user.uid).set({
      'name': name,
      'nameSearch': name.trim().toLowerCase(),
      'email': FieldValue.delete(),
      'phone': phone,
      'photoUrl': photoUrl,
      'bio': bio,
      'coverUrl': coverUrl,
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

  Future<List<SellerProfile>> searchSellerProfiles(String query) async {
    final normalized = query.trim();
    if (normalized.length < 2) return const <SellerProfile>[];

    final lower = normalized.toLowerCase();
    final legacyPrefixes = <String>{
      normalized,
      '${normalized[0].toUpperCase()}${normalized.substring(1)}',
    };

    final snapshots = await Future.wait([
      _sellerProfilesCollection
          .orderBy('nameSearch')
          .startAt([lower])
          .endAt(['$lower\uf8ff'])
          .limit(30)
          .get(),
      ...legacyPrefixes.map(
        (prefix) => _sellerProfilesCollection
            .orderBy('name')
            .startAt([prefix])
            .endAt(['$prefix\uf8ff'])
            .limit(30)
            .get(),
      ),
    ]);

    final profilesById = <String, SellerProfile>{};
    for (final snapshot in snapshots) {
      for (final document in snapshot.docs) {
        profilesById.putIfAbsent(
          document.id,
          () => SellerProfile.fromFirestore(document),
        );
      }
    }

    return profilesById.values.take(30).toList();
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