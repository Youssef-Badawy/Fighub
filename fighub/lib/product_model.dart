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
  String? reservedBy;

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
    this.reservedBy,
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
      'reservedBy': reservedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return Product.fromMap(document.id, document.data() ?? {});
  }

  /// Parses product fields without requiring a live Firestore snapshot.
  /// Kept separate so legacy image-field fallbacks can be tested directly.
  factory Product.fromMap(String id, Map<String, dynamic> data) {
    final rawImagePaths = data['imagePaths'];

    List<String> parsedImagePaths = [];

    if (rawImagePaths is List) {
      parsedImagePaths = rawImagePaths
          .whereType<String>()
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList();
    }

    final rawOldImagePath = data['imagePath'];
    final oldImagePath = rawOldImagePath is String ? rawOldImagePath : null;

    String readString(String key, String fallback) {
      final value = data[key];
      if (value is String) return value;
      if (value is num) return value.toString();
      return fallback;
    }

    // Support old products that only have imagePath.
    if (parsedImagePaths.isEmpty &&
        oldImagePath != null &&
        oldImagePath.isNotEmpty) {
      parsedImagePaths = [oldImagePath];
    }

    return Product(
      id: id,
      sellerId: readString('sellerId', ''),
      name: readString('name', ''),
      price: readString('price', ''),
      category: readString('category', 'Other'),
      condition: readString('condition', 'Used'),
      description: readString('description', ''),
      paymentMethod: readString('paymentMethod', 'Cash on Delivery'),
      // A legacy empty imagePath must not mask valid imagePaths data.
      imagePath: oldImagePath != null && oldImagePath.trim().isNotEmpty
          ? oldImagePath.trim()
          : (parsedImagePaths.isNotEmpty ? parsedImagePaths.first : null),
      imagePaths: parsedImagePaths,
      status: readString('status', 'Available'),
      reservedBy: data['reservedBy'] is String ? data['reservedBy'] as String : null,
    );
  }
}
