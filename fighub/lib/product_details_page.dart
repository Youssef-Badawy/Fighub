import 'dart:io';

import 'package:flutter/material.dart';

class ProductDetailsPage extends StatefulWidget {
  final String name;
  final String price;
  final String category;
  final String condition;
  final String? imagePath;

  const ProductDetailsPage({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    this.imagePath,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  String _productStatus = 'Available';
  bool _reservationSent = false;

  void _reserveProduct() {
    if (_productStatus != 'Available' || _reservationSent) {
      return;
    }

    setState(() {
      _productStatus = 'Reserved';
      _reservationSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reservation sent successfully!'),
      ),
    );
  }

  void _setStatus(String status) {
    setState(() {
      _productStatus = status;
      if (status != 'Available') {
        _reservationSent = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product status changed to $status'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 330,
              decoration: BoxDecoration(
                color: const Color(0xFF252529),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.imagePath != null
                  ? Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image_outlined,
                          size: 90,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(
                      Icons.image_outlined,
                      size: 90,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.price,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  text: widget.category,
                ),
                _InfoChip(
                  icon: Icons.verified_outlined,
                  text: widget.condition,
                ),
                const _InfoChip(
                  icon: Icons.local_shipping_outlined,
                  text: 'Shipping COD',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Product Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    title: 'Available',
                    selected: _productStatus == 'Available',
                    onPressed: () => _setStatus('Available'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    title: 'Reserved',
                    selected: _productStatus == 'Reserved',
                    onPressed: () => _setStatus('Reserved'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    title: 'Shipping',
                    selected: _productStatus == 'Shipping',
                    onPressed: () => _setStatus('Shipping'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment & Shipping',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Product payment: Cash on delivery'),
                  SizedBox(height: 6),
                  Text('Shipping fee: Paid on delivery'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chat will be available soon.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Chat Seller'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _productStatus == 'Available' &&
                            !_reservationSent
                        ? _reserveProduct
                        : null,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(
                      _reservationSent ? 'Reserved' : 'Reserve',
                    ),
                  ),
                ),
              ],
            ),
          ],
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
    return Chip(
      avatar: Icon(icon, size: 17),
      label: Text(text),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onPressed;

  const _StatusButton({
    required this.title,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: selected
            ? const Color(0xFFE53935)
            : const Color(0xFF1A1A1D),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(title),
    );
  }
}