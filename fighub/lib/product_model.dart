import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String sellerId;
  final String name;
  final String price;
  final String category;
  final String condition;
  final String description;
  final String paymentMethod;

  // Kept for backward compatibility with existing products and UI.
  final String? imagePath;

  // New field for multiple product images.
  final List<String> imagePaths;

  String status;

  Product({
    this.id,
    required this.sellerId,
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.paymentMethod,
    this.imagePath,
    List<String>? imagePaths,
    this.status = 'Available',
  }) : imagePaths = List.unmodifiable(
          imagePaths ??
              (imagePath != null && imagePath.isNotEmpty
                  ? [imagePath]
                  : <String>[]),
        );

  Map<String, dynamic> toFirestore() {
    final images = imagePaths.isNotEmpty
        ? imagePaths
        : (imagePath != null && imagePath!.isNotEmpty
            ? [imagePath!]
            : <String>[]);

    return {
      'sellerId': sellerId,
      'name': name,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'paymentMethod': paymentMethod,

      // Keep the old field so existing code/data remains compatible.
      'imagePath': images.isNotEmpty ? images.first : imagePath,

      // New multiple-images field.
      'imagePaths': images,

      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final rawImagePaths = data['imagePaths'];

    List<String> parsedImagePaths = [];

    if (rawImagePaths is List) {
      parsedImagePaths = rawImagePaths
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toList();
    }

    final oldImagePath = data['imagePath'] as String?;

    // Support old products that only have imagePath.
    if (parsedImagePaths.isEmpty &&
        oldImagePath != null &&
        oldImagePath.isNotEmpty) {
      parsedImagePaths = [oldImagePath];
    }

    return Product(
      id: document.id,
      sellerId: data['sellerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      price: data['price'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      condition: data['condition'] as String? ?? 'Used',
      description: data['description'] as String? ?? '',
      paymentMethod:
          data['paymentMethod'] as String? ?? 'Cash on Delivery',
      imagePath: oldImagePath ??
          (parsedImagePaths.isNotEmpty
              ? parsedImagePaths.first
              : null),
      imagePaths: parsedImagePaths,
      status: data['status'] as String? ?? 'Available',
    );
  }
}