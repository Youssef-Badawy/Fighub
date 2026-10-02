import 'package:flutter/material.dart';

class ProductDetailsPage extends StatefulWidget {
  final String name;
  final String price;
  final String category;
  final String condition;

  const ProductDetailsPage({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String _productStatus = 'Available';
  bool _reservationSent = false;

  Color _statusColor() {
    switch (_productStatus) {
      case 'Reserved':
        return Colors.orange;
      case 'Shipping':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _statusIcon() {
    switch (_productStatus) {
      case 'Reserved':
        return Icons.bookmark_rounded;
      case 'Shipping':
        return Icons.local_shipping_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _statusDescription() {
    switch (_productStatus) {
      case 'Reserved':
        return 'This product has been reserved by a buyer.';
      case 'Shipping':
        return 'This product is currently being shipped.';
      default:
        return 'This product is available for reservation.';
    }
  }

  void _reserveProduct() {
    if (_productStatus != 'Available' || _reservationSent) {
      return;
    }

    setState(() {
      _reservationSent = true;
      _productStatus = 'Reserved';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reservation request sent to the seller!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 330,
              color: const Color(0xFF252529),
              child: const Icon(
                Icons.image_outlined,
                size: 90,
                color: Colors.grey,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.category_outlined,
                        text: widget.category,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        text: widget.condition,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Seller',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          child: Icon(Icons.person_outline_rounded),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FigHub Seller',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Action figures collector',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Product Status',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(),
                          color: statusColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _productStatus,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _statusDescription(),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Seller Status Control',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _StatusButton(
                          title: 'Available',
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.green,
                          selected: _productStatus == 'Available',
                          onTap: () {
                            setState(() {
                              _productStatus = 'Available';
                              _reservationSent = false;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _StatusButton(
                          title: 'Reserved',
                          icon: Icons.bookmark_border_rounded,
                          color: Colors.orange,
                          selected: _productStatus == 'Reserved',
                          onTap: () {
                            setState(() {
                              _productStatus = 'Reserved';
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _StatusButton(
                          title: 'Shipping',
                          icon: Icons.local_shipping_outlined,
                          color: Colors.blue,
                          selected: _productStatus == 'Shipping',
                          onTap: () {
                            setState(() {
                              _productStatus = 'Shipping';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This collectible figure is listed on FigHub. '
                    'Contact the seller for more information about the '
                    'condition, accessories, packaging, and delivery.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Product payment: Cash on delivery',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.local_shipping_outlined),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Shipping fee: Paid on delivery',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed:
                          _productStatus == 'Available' &&
                                  !_reservationSent
                              ? _reserveProduct
                              : null,
                      icon: const Icon(
                        Icons.bookmark_border_rounded,
                      ),
                      label: Text(
                        _reservationSent
                            ? 'Reservation Sent'
                            : _productStatus == 'Reserved'
                                ? 'Product Reserved'
                                : _productStatus == 'Shipping'
                                    ? 'Product Is Shipping'
                                    : 'Reserve Product',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                      ),
                      label: const Text(
                        'Chat with Seller',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: selected ? color : Colors.grey,
        ),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: TextStyle(
              color: selected ? color : Colors.white,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          side: BorderSide(
            color: selected ? color : Colors.grey.shade800,
          ),
          backgroundColor: selected
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
