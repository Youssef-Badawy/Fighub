import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerRatingSummary {
  final double average;
  final int count;

  const SellerRatingSummary({required this.average, required this.count});
}

class SellerRatingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('seller_reviews');

  Stream<SellerRatingSummary> watchSummary(String sellerId) {
    return _reviews
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return const SellerRatingSummary(average: 0, count: 0);
      }
      final total = snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['rating'] as num?)?.round() ?? 0),
      );
      return SellerRatingSummary(
        average: total / snapshot.docs.length,
        count: snapshot.docs.length,
      );
    });
  }

  Future<String?> findEligibleProduct(String sellerId) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || user.uid == sellerId) return null;

    final products = await _db
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .get();

    for (final product in products.docs) {
      final data = product.data();
      if (data['status'] == 'Sold' && data['reservedBy'] == user.uid) {
        return product.id;
      }
    }
    return null;
  }

  Future<void> submitRating({
    required String sellerId,
    required String productId,
    required int rating,
    String comment = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('يجب تسجيل الدخول بحساب مسجل أولًا.');
    }
    if (sellerId.isEmpty || sellerId == user.uid) {
      throw ArgumentError('لا يمكنك تقييم حسابك الشخصي.');
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating');
    }
    if (comment.trim().length > 300) {
      throw ArgumentError('التعليق يجب ألا يزيد عن 300 حرف.');
    }

    final productRef = _db.collection('products').doc(productId);
    final reviewRef = _reviews.doc('${sellerId}_${user.uid}');

    await _db.runTransaction((transaction) async {
      final product = await transaction.get(productRef);
      final existingReview = await transaction.get(reviewRef);
      if (existingReview.exists) {
        throw StateError('لقد قيّمت هذا البائع من قبل.');
      }
      final data = product.data();
      if (!product.exists ||
          data?['sellerId'] != sellerId ||
          data?['reservedBy'] != user.uid ||
          data?['status'] != 'Sold') {
        throw StateError('التقييم متاح بعد إتمام عملية شراء مؤكدة فقط.');
      }

      transaction.set(reviewRef, {
        'sellerId': sellerId,
        'reviewerId': user.uid,
        'productId': productId,
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
