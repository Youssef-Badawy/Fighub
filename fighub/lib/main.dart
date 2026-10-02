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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            onPressed: () {},
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
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

            // Categories
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

            // Featured
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

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.68,
              children: [
                _ProductCard(
                  name: 'Batman',
                  price: '1,500 EGP',
                  category: 'DC',
                  condition: 'Used - Good',
                ),
                _ProductCard(
                  name: 'Jon Snow',
                  price: '2,000 EGP',
                  category: 'Game of Thrones',
                  condition: 'Rare',
                ),
                _ProductCard(
                  name: 'Spider-Man',
                  price: '1,200 EGP',
                  category: 'Marvel',
                  condition: 'New',
                ),
                _ProductCard(
                  name: 'Arya Stark',
                  price: '1,800 EGP',
                  category: 'Game of Thrones',
                  condition: 'Used - Excellent',
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Quick sell banner
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
                    onPressed: () {},
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
          backgroundColor:
              selected ? const Color(0xFFE53935) : const Color(0xFF1A1A1D),
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

  const _ProductCard({
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF18181B),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFF252529),
                child: const Icon(
                  Icons.image_outlined,
                  size: 65,
                  color: Colors.grey,
                ),
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