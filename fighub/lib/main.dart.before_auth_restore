import 'dart:io';

import 'package:flutter/material.dart';
import 'product_model.dart';
import 'product_details_page.dart';
import 'add_product_page.dart';
import 'seller_dashboard_page.dart';

void main() {
  runApp(const FigHubApp());
}

class FigHubApp extends StatelessWidget {
  const FigHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FigHub',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Product> _products = [
    Product(
      name: 'Batman',
      price: '1,500 EGP',
      category: 'DC',
      condition: 'Used - Good',
      description: 'Batman action figure.',
      paymentMethod: 'Cash on delivery',
    ),
    Product(
      name: 'Jon Snow',
      price: '2,000 EGP',
      category: 'Game of Thrones',
      condition: 'Rare',
      description: 'Jon Snow collectible figure.',
      paymentMethod: 'Cash on delivery',
    ),
    Product(
      name: 'Spider-Man',
      price: '1,200 EGP',
      category: 'Marvel',
      condition: 'New',
      description: 'Spider-Man action figure.',
      paymentMethod: 'Cash on delivery',
    ),
    Product(
      name: 'Arya Stark',
      price: '1,800 EGP',
      category: 'Game of Thrones',
      condition: 'Used - Excellent',
      description: 'Arya Stark collectible figure.',
      paymentMethod: 'Cash on delivery',
    ),
  ];

  Future<void> _openAddProduct() async {
    final Product? product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductPage(),
      ),
    );

    if (product != null) {
      setState(() {
        _products.insert(0, product);
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product published successfully!'),
        ),
      );
    }
  }

  void _openSellerDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellerDashboardPage(
          products: _products,
        ),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          name: product.name,
          price: product.price,
          category: product.category,
          condition: product.condition,
          imagePath: product.imagePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        title: const Text(
          'FigHub',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            onPressed: _openSellerDashboard,
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search figures, characters...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded),
                ),
                filled: true,
                fillColor: const Color(0xFF1A1A1D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _CategoryChip(
                    title: 'All',
                    icon: Icons.grid_view_rounded,
                    selected: true,
                  ),
                  _CategoryChip(
                    title: 'Marvel',
                    icon: Icons.auto_awesome,
                  ),
                  _CategoryChip(
                    title: 'DC',
                    icon: Icons.shield_outlined,
                  ),
                  _CategoryChip(
                    title: 'Anime',
                    icon: Icons.animation_outlined,
                  ),
                  _CategoryChip(
                    title: 'GOT',
                    icon: Icons.castle_outlined,
                  ),
                  _CategoryChip(
                    title: 'Star Wars',
                    icon: Icons.star_border_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Figures',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              itemCount: _products.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.64,
              ),
              itemBuilder: (context, index) {
                final product = _products[index];

                return _ProductCard(
                  name: product.name,
                  price: product.price,
                  category: product.category,
                  condition: product.condition,
                  status: product.status,
                  imagePath: product.imagePath,
                  onTap: () => _openProduct(product),
                );
              },
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF25252A),
                    Color(0xFF17171A),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.sell_outlined,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Have figures to sell?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'List your collectibles on FigHub.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: _openAddProduct,
                    child: const Text('Sell'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 2) {
            _openAddProduct();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box_rounded),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;

  const _CategoryChip({
    required this.title,
    required this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 9),
      child: FilledButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 17),
        label: Text(title),
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? const Color(0xFFE53935)
              : const Color(0xFF1A1A1D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String category;
  final String condition;
  final String status;
  final String? imagePath;
  final VoidCallback onTap;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.status,
    required this.imagePath,
    required this.onTap,
  });

  Color _statusColor() {
    if (status == 'Reserved') {
      return const Color(0xFFFF9800);
    }

    if (status == 'Shipping') {
      return const Color(0xFF2196F3);
    }

    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF18181B),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF252529),
                    child: imagePath != null
                        ? Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_outlined,
                                size: 65,
                                color: Colors.grey,
                              );
                            },
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 65,
                            color: Colors.grey,
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.favorite_border_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    condition,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}