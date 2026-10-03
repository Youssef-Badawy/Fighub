import 'package:flutter/material.dart';
import 'product_model.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({
  super.key,
  required this.products,
});

final List<Product> products;

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  late List<Product> _products;

@override
void initState() {
  super.initState();
  _products = List<Product>.from(widget.products);
}

  Color _statusColor(String status) {
    switch (status) {
      case 'Reserved':
        return Colors.orange;
      case 'Shipping':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Reserved':
        return Icons.bookmark_rounded;
      case 'Shipping':
        return Icons.local_shipping_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  void _changeStatus(int index, String newStatus) {
    setState(() {
      _products[index].status = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_products[index].name} is now $newStatus',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _products.isEmpty
          ? const Center(
              child: Text(
                'You have no products yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final statusColor = _statusColor(product.status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1D),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: const Color(0xFF252529),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              size: 38,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  product.price,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${product.category} • ${product.condition}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _statusIcon(product.status),
                              size: 20,
                              color: statusColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.status,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                _changeStatus(index, value);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'Available',
                                  child: Text('Available'),
                                ),
                                PopupMenuItem(
                                  value: 'Reserved',
                                  child: Text('Reserved'),
                                ),
                                PopupMenuItem(
                                  value: 'Shipping',
                                  child: Text('Shipping'),
                                ),
                              ],
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Change'),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }
}

