import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'product_model.dart';
import 'cloudinary_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection {
    return _firestore.collection('products');
  }

  Future<String> addProduct(Product product) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (product.sellerId != user.uid) {
      throw StateError('You can only add products for your own account.');
    }

    final document = await _productsCollection.add(product.toFirestore());

    return document.id;
  }

  Future<void> updateProduct(Product product) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    final productId = product.id;

    if (productId == null || productId.isEmpty) {
      throw ArgumentError('Product ID is required to update a product.');
    }

    if (product.sellerId != user.uid) {
      throw StateError('You can only update your own products.');
    }

    final document = await _productsCollection.doc(productId).get();

    if (!document.exists) {
      throw StateError('Product not found.');
    }

    final data = document.data();

    final ownerId = data?['sellerId'] as String?;

    if (ownerId != user.uid) {
      throw StateError('You can only update your own products.');
    }

    final updates = product.toFirestore()..remove('createdAt');

    await _productsCollection.doc(productId).update(updates);
  }

  Future<void> reserveProduct(String productId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (productId.isEmpty) {
      throw ArgumentError('Product ID is required.');
    }

    final reference = _productsCollection.doc(productId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Product not found.');
      }

      final data = snapshot.data()!;
      final sellerId = data['sellerId'] as String? ?? '';
      final status = data['status'] as String? ?? 'Available';
      final reservedBy = data['reservedBy'] as String?;

      if (sellerId == user.uid) {
        throw StateError('You cannot reserve your own product.');
      }

      if (status != 'Available' ||
          (reservedBy != null && reservedBy.isNotEmpty)) {
        throw StateError('Product is no longer available.');
      }

      transaction.update(reference, {
        'status': 'Reserved',
        'reservedBy': user.uid,
        'reservedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> cancelReservation(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be signed in.');
    }
    if (productId.isEmpty) {
      throw ArgumentError('Product ID is required.');
    }

    final reference = _productsCollection.doc(productId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('Product not found.');

      final data = snapshot.data()!;
      if (data['reservedBy'] != user.uid || data['status'] != 'Reserved') {
        throw StateError('You do not own an active reservation for this product.');
      }

      transaction.update(reference, {
        'status': 'Available',
        'reservedBy': null,
        'reservedAt': null,
      });
    });
  }

  Future<void> deleteProduct(String productId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (productId.isEmpty) {
      throw ArgumentError('Product ID is required to delete a product.');
    }

    final document = await _productsCollection.doc(productId).get();

    if (!document.exists) {
      throw StateError('Product not found.');
    }

    final data = document.data();

    final ownerId = data?['sellerId'] as String?;

    if (ownerId != user.uid) {
      throw StateError('You can only delete your own products.');
    }

    final status = data?['status'] as String? ?? 'Available';
    if (status != 'Available') {
      throw StateError('Reserved or sold products cannot be deleted.');
    }

    final rawImages = data?['imagePaths'];
    final imageUrls = rawImages is List
        ? rawImages.whereType<String>().toList()
        : <String>[];
    final legacyImage = data?['imagePath'] as String?;
    if (legacyImage != null && legacyImage.isNotEmpty) {
      imageUrls.add(legacyImage);
    }

    // Delete the Firestore listing even if the Cloudinary Worker is temporarily
    // outdated or unavailable. Asset cleanup is best-effort and must not block
    // the seller from removing their product from the marketplace.
    await _productsCollection.doc(productId).delete();

    try {
      await CloudinaryService().deleteProductAssets(
        productId: productId,
        assetUrls: imageUrls,
      );
    } catch (error, stackTrace) {
      debugPrint('FIGHUB PRODUCT IMAGE CLEANUP PENDING ($productId): $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<Product?> getProduct(String productId) async {
    if (productId.isEmpty) {
      return null;
    }

    final document = await _productsCollection.doc(productId).get();

    if (!document.exists) {
      return null;
    }

    return Product.fromFirestore(document);
  }

  Stream<List<Product>> watchProducts() {
    return _productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((document) =>
                  document.data()['productType'] != 'print_order')
              .map(Product.fromFirestore)
              .toList();
        });
  }

  Stream<List<Product>> watchRecommendedProducts(List<String> interests) {
    final normalizedInterests = interests
        .map((interest) => interest.trim().toLowerCase())
        .where((interest) => interest.isNotEmpty)
        .toSet();

    return watchProducts().map((products) {
      if (normalizedInterests.isEmpty) {
        return products;
      }

      final recommended = <Product>[];
      final others = <Product>[];

      for (final product in products) {
        final category = product.category.trim().toLowerCase();

        if (normalizedInterests.contains(category)) {
          recommended.add(product);
        } else {
          others.add(product);
        }
      }

      return [...recommended, ...others];
    });
  }

  Stream<List<Product>> watchSellerProducts(String sellerId) {
    return _productsCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
              .where((document) =>
                  document.data()['productType'] != 'print_order')
              .map(Product.fromFirestore)
              .toList();

          products.sort((a, b) {
            final aId = a.id ?? '';
            final bId = b.id ?? '';

            return bId.compareTo(aId);
          });

          return products;
        });
  }
}
