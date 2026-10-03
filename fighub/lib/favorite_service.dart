import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      _favoritesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites');
  }

  Future<void> addFavorite(String productId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (productId.isEmpty) {
      throw ArgumentError(
        'Product ID is required.',
      );
    }

    await _favoritesCollection(user.uid)
        .doc(productId)
        .set({
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String productId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (productId.isEmpty) {
      return;
    }

    await _favoritesCollection(user.uid)
        .doc(productId)
        .delete();
  }

  Future<bool> isFavorite(String productId) async {
    final user = _auth.currentUser;

    if (user == null || productId.isEmpty) {
      return false;
    }

    final document = await _favoritesCollection(user.uid)
        .doc(productId)
        .get();

    return document.exists;
  }

  Stream<List<String>> watchFavoriteIds() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <String>[]);
    }

    return _favoritesCollection(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  (document) =>
                      document.data()['productId'] as String? ??
                      document.id,
                )
                .toList();
          },
        );
  }
}