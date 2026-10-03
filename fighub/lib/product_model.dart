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
  final String? imagePath;
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
    this.status = 'Available',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'name': name,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'paymentMethod': paymentMethod,
      'imagePath': imagePath,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

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
      imagePath: data['imagePath'] as String?,
      status: data['status'] as String? ?? 'Available',
    );
  }
}