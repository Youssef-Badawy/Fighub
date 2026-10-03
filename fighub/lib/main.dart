import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'app_settings.dart';
import 'auth_gate.dart';
import 'auth_manager.dart';
import 'add_product_page.dart';
import 'chat_list_page.dart';
import 'favorite_service.dart';
import 'favorites_page.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'notifications_page.dart';
import 'product_details_page.dart';
import 'product_model.dart';
import 'product_service.dart';
import 'profile_page.dart';
import 'seller_dashboard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final settings = AppSettings();
  await settings.loadSettings();

  final authManager = AuthManager();
  await authManager.load();

  runApp(
    FigHubApp(
      settings: settings,
      authManager: authManager,
    ),
  );
}

class FigHubApp extends StatefulWidget {
  final AppSettings settings;
  final AuthManager authManager;

  const FigHubApp({
    super.key,
    required this.settings,
    required this.authManager,
  });

  @override
  State<FigHubApp> createState() => _FigHubAppState();
}

class _FigHubAppState extends State<FigHubApp> {
  @override
  void initState() {
    super.initState();

    widget.settings.addListener(_refresh);
    widget.authManager.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_refresh);
    widget.authManager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
      brightness: Brightness.light,
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.blue,
      brightness: Brightness.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FigHub',
      locale: widget.settings.locale,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: widget.settings.themeMode,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: widget.settings.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AuthGate(
        authManager: widget.authManager,
        home: FigHubHome(
          settings: widget.settings,
          authManager: widget.authManager,
        ),
      ),
    );
  }
}

class FigHubHome extends StatefulWidget {
  final AppSettings settings;
  final AuthManager authManager;

  const FigHubHome({
    super.key,
    required this.settings,
    required this.authManager,
  });

  @override
  State<FigHubHome> createState() => _FigHubHomeState();
}

class _FigHubHomeState extends State<FigHubHome> {
  int _currentIndex = 0;

  final List<Product> _products = [];
  final List<Product> _favorites = [];
  final List<String> _notifications = [];

  final ProductService _productService = ProductService();
  final FavoriteService _favoriteService = FavoriteService();
  final NotificationService _notificationService =
      NotificationService();

  StreamSubscription<List<Product>>? _productsSubscription;
  StreamSubscription<List<String>>? _favoritesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>?
      _notificationsSubscription;

  final List<String> _favoriteIds = [];

  int _unreadNotificationsCount = 0;

  final List<String> _categories = const [
    'All',
    'Marvel',
    'DC',
    'Game of Thrones',
    'Anime',
    'Star Wars',
    'Other',
  ];

  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _productsSubscription = _productService
        .watchProducts()
        .listen((products) {
      if (!mounted) {
        return;
      }

      setState(() {
        _products
          ..clear()
          ..addAll(products);

        _refreshFavoritesList();
      });
    });

    _favoritesSubscription = _favoriteService
        .watchFavoriteIds()
        .listen((favoriteIds) {
      if (!mounted) {
        return;
      }

      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(favoriteIds);

        _refreshFavoritesList();
      });
    });

    _notificationsSubscription = _notificationService
        .watchMyNotifications()
        .listen((notificationList) {
      if (!mounted) {
        return;
      }

      final unreadCount = notificationList.where(
        (notification) {
          return !(notification['isRead'] as bool? ?? false);
        },
      ).length;

      setState(() {
        _unreadNotificationsCount = unreadCount;
      });
    });
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _favoritesSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _refreshFavoritesList() {
    _favorites
      ..clear()
      ..addAll(
        _products.where(
          (product) {
            final productId = product.id;

            return productId != null &&
                _favoriteIds.contains(productId);
          },
        ),
      );
  }

  bool _isFavorite(Product product) {
    final productId = product.id;

    if (productId == null || productId.isEmpty) {
      return false;
    }

    return _favoriteIds.contains(productId);
  }

  Future<void> _toggleFavorite(Product product) async {
    final productId = product.id;

    if (productId == null || productId.isEmpty) {
      return;
    }

    try {
      final isCurrentlyFavorite = _isFavorite(product);

      if (isCurrentlyFavorite) {
        await _favoriteService.removeFavorite(productId);
      } else {
        await _favoriteService.addFavorite(productId);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء تحديث المفضلة.',
          ),
        ),
      );
    }
  }

  Future<void> _removeFavorite(Product product) async {
    final productId = product.id;

    if (productId == null || productId.isEmpty) {
      return;
    }

    try {
      await _favoriteService.removeFavorite(productId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إزالة المنتج من المفضلة.',
          ),
        ),
      );
    }
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' ||
              product.category == _selectedCategory;

      final matchesSearch =
          _searchQuery.isEmpty ||
              product.name
                  .toLowerCase()
                  .contains(
                    _searchQuery.toLowerCase(),
                  );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get _chatProducts {
    return _products
        .map((product) => product.name)
        .toSet()
        .toList();
  }

  String _categoryLabel(
    BuildContext context,
    String category,
  ) {
    final localization = AppLocalizations.of(context);

    switch (category) {
      case 'Marvel':
        return localization.marvel;
      case 'DC':
        return localization.dc;
      case 'Game of Thrones':
        return localization.gameOfThrones;
      case 'Anime':
        return localization.anime;
      case 'Star Wars':
        return localization.starWars;
      case 'Other':
        return localization.other;
      default:
        return localization.all;
    }
  }

  Future<void> _openAddProduct() async {
    final product = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddProductPage(),
      ),
    );

    if (!mounted || product == null) {
      return;
    }

    setState(() {});
  }

  Future<void> _openProductDetails(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
          onStatusChanged: (status) {
            if (!mounted) {
              return;
            }

            setState(() {
              product.status = status;
            });
          },
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openSellerDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerDashboardPage(
          products: _products,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openFavorites() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritesPage(
          favorites: _favorites,
          onRemove: _removeFavorite,
          onOpenProduct: _openProductDetails,
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          products: _products,
          onMyProducts: _openSellerDashboard,
          onFavorites: _openFavorites,
          settings: widget.settings,
          authManager: widget.authManager,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openChat() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatListPage(
          productNames: _chatProducts,
        ),
      ),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationsPage(
          notifications: _notifications,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    final pages = [
      _buildHome(localization),
      _buildFavoritesTab(),
      _buildSellTab(localization),
      _buildChatTab(localization),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FigHub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openNotifications,
            icon: _buildNotificationIcon(),
          ),
          IconButton(
            onPressed: _openProfile,
            icon: const Icon(
              Icons.person_outline,
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            _openAddProduct();
            return;
          }

          if (index == 3) {
            _openChat();
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: localization.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: localization.favorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sell_outlined),
            selectedIcon: const Icon(Icons.sell),
            label: localization.sell,
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.chat_bubble_outline,
            ),
            selectedIcon: const Icon(
              Icons.chat_bubble,
            ),
            label: localization.messages,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    if (_unreadNotificationsCount == 0) {
      return const Icon(
        Icons.notifications_outlined,
      );
    }

    final displayCount =
        _unreadNotificationsCount > 99
            ? '99+'
            : _unreadNotificationsCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_outlined,
        ),
        Positioned(
          right: -6,
          top: -7,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              displayCount,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHome(
    AppLocalizations localization,
  ) {
    final products = _filteredProducts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: localization.search,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];

              return ChoiceChip(
                label: Text(
                  _categoryLabel(
                    context,
                    category,
                  ),
                ),
                selected:
                    _selectedCategory == category,
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (products.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 80,
              ),
              child: Text(
                localization.noProducts,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge,
              ),
            ),
          )
        else
          ...products.map(
            (product) => Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: _ProductCard(
                product: product,
                isFavorite: _isFavorite(product),
                onFavorite: () {
                  _toggleFavorite(product);
                },
                onTap: () {
                  _openProductDetails(product);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    return FavoritesPage(
      favorites: _favorites,
      onRemove: _removeFavorite,
      onOpenProduct: _openProductDetails,
    );
  }

  Widget _buildSellTab(
    AppLocalizations localization,
  ) {
    return Center(
      child: FilledButton.icon(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add),
        label: Text(
          localization.sell,
        ),
      ),
    );
  }

  Widget _buildChatTab(
    AppLocalizations localization,
  ) {
    return Center(
      child: FilledButton.icon(
        onPressed: _openChat,
        icon: const Icon(
          Icons.chat_bubble_outline,
        ),
        label: Text(
          localization.messages,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  String _statusLabel(
    BuildContext context,
    String status,
  ) {
    final localization =
        AppLocalizations.of(context);

    switch (status) {
      case 'Reserved':
        return localization.reserved;
      case 'Sold':
        return localization.productSold;
      default:
        return localization.available;
    }
  }

  String _categoryLabel(
    BuildContext context,
    String category,
  ) {
    final localization =
        AppLocalizations.of(context);

    switch (category) {
      case 'Marvel':
        return localization.marvel;
      case 'DC':
        return localization.dc;
      case 'Game of Thrones':
        return localization.gameOfThrones;
      case 'Anime':
        return localization.anime;
      case 'Star Wars':
        return localization.starWars;
      case 'Other':
        return localization.other;
      default:
        return localization.all;
    }
  }

  Widget _buildProductImage(BuildContext context) {
    final imagePath = product.imagePath;

    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholder(context);
    }

    final isNetworkImage =
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://');

    if (isNetworkImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imagePath,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _buildImageError();
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imagePath),
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _buildImageError();
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 40,
      ),
    );
  }

  Widget _buildImageError() {
    return const SizedBox(
      width: 90,
      height: 90,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildProductImage(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _categoryLabel(
                        context,
                        product.category,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${product.price} EGP',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(
                          context,
                          product.status,
                        ),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                tooltip: isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: isFavorite
                      ? Colors.red
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}