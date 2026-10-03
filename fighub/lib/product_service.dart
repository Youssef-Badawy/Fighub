import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection {
    return _firestore.collection('products');
  }

  Future<String> addProduct(Product product) async {
    final document = await _productsCollection.add(
      product.toFirestore(),
    );

    return document.id;
  }

  Future<void> updateProduct(Product product) async {
    final productId = product.id;

    if (productId == null || productId.isEmpty) {
      throw ArgumentError('Product ID is required to update a product.');
    }

    await _productsCollection
        .doc(productId)
        .update(product.toFirestore());
  }

  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }

  Future<Product?> getProduct(String productId) async {
    final document =
        await _productsCollection.doc(productId).get();

    if (!document.exists) {
      return null;
    }

    return Product.fromFirestore(document);
  }

  Stream<List<Product>> watchProducts() {
    return _productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(Product.fromFirestore)
                .toList();
          },
        );
  }

  Stream<List<Product>> watchSellerProducts(String sellerId) {
    return _productsCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(
          (snapshot) {
            final products = snapshot.docs
                .map(Product.fromFirestore)
                .toList();

            products.sort(
              (a, b) {
                final aId = a.id ?? '';
                final bId = b.id ?? '';

                return bId.compareTo(aId);
              },
            );

            return products;
          },
        );
  }
}