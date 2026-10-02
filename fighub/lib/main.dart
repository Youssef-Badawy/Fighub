import 'package:flutter/material.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FigHub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            TextField(
              decoration: InputDecoration(
                hintText: 'Search action figures...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFF1C1C1C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _category('Marvel'),
                  _category('DC'),
                  _category('Game of Thrones'),
                  _category('Anime'),
                  _category('Star Wars'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Featured Figures',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.72,
              children: [
                _productCard(
                  'Batman',
                  '1,500 EGP',
                  'DC',
                ),
                _productCard(
                  'Jon Snow',
                  '2,000 EGP',
                  'Game of Thrones',
                ),
                _productCard(
                  'Spider-Man',
                  '1,200 EGP',
                  'Marvel',
                ),
                _productCard(
                  'Arya Stark',
                  '1,800 EGP',
                  'Game of Thrones',
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  static Widget _category(String name) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: FilledButton.tonal(
        onPressed: () {},
        child: Text(name),
      ),
    );
  }

  static Widget _productCard(
    String name,
    String price,
    String category,
  ) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF252525),
              child: const Icon(
                Icons.image_outlined,
                size: 70,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}