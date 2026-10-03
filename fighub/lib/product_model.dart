class Product {
  final String name;
  final String price;
  final String category;
  final String condition;
  final String description;
  final String paymentMethod;
  String status;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.paymentMethod,
    this.status = 'Available',
  });
}
