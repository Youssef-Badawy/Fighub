import 'package:cloud_firestore/cloud_firestore.dart';

class OfferItem {
  final String? id;
  final String name;
  final String price;
  final String category;
  final String condition;
  final String description;
  final List<String> imagePaths;

  String status;
  String? reservedBy;
  DateTime? reservedAt;

  OfferItem({
    this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.imagePaths,
    this.status = 'Available',
    this.reservedBy,
    this.reservedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'imagePaths': imagePaths,
      'status': status,
      'reservedBy': reservedBy,
      'reservedAt': reservedAt,
    };
  }

  factory OfferItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final rawImages = data['imagePaths'];
    final images = rawImages is List
        ? rawImages.whereType<String>().toList()
        : <String>[];

    final timestamp = data['reservedAt'];

    return OfferItem(
      id: document.id,
      name: data['name'] as String? ?? '',
      price: data['price'] as String? ?? '',
      category: data['category'] as String? ?? 'Other',
      condition: data['condition'] as String? ?? 'Used',
      description: data['description'] as String? ?? '',
      imagePaths: images,
      status: data['status'] as String? ?? 'Available',
      reservedBy: data['reservedBy'] as String?,
      reservedAt:
          timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}

class Offer {
  final String? id;
  final String sellerId;
  final String title;
  final String description;
  final DateTime? scheduledAt;
  final String status;
  final DateTime? createdAt;

  Offer({
    this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    this.scheduledAt,
    this.status = 'Scheduled',
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt != null
          ? Timestamp.fromDate(scheduledAt!)
          : null,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Offer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final scheduled = data['scheduledAt'];
    final created = data['createdAt'];

    return Offer(
      id: document.id,
      sellerId: data['sellerId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      scheduledAt:
          scheduled is Timestamp ? scheduled.toDate() : null,
      status: data['status'] as String? ?? 'Scheduled',
      createdAt:
          created is Timestamp ? created.toDate() : null,
    );
  }
}
