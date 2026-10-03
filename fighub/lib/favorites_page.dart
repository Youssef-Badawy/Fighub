import 'dart:io';

import 'package:flutter/material.dart';

import 'product_model.dart';
import 'app_localizations.dart';

class FavoritesPage extends StatelessWidget {
  final List<Product> favorites;
  final ValueChanged<Product> onRemove;
  final ValueChanged<Product> onOpenProduct;

  const FavoritesPage({
    super.key,
    required this.favorites,
    required this.onRemove,
    required this.onOpenProduct,
  });

  String _statusLabel(
    String status,
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return status;
    }

    switch (status) {
      case 'Available':
        return 'متاح';
      case 'Reserved':
        return 'محجوز';
      case 'Sold':
        return 'تم البيع';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    final title = localization.isArabic
        ? 'المفضلة'
        : 'Favorites';

    final emptyTitle = localization.isArabic
        ? 'لا توجد منتجات مفضلة حتى الآن.'
        : 'No favorite products yet.';

    final emptySubtitle = localization.isArabic
        ? 'اضغط على علامة القلب لحفظ مجسم.'
        : 'Tap the heart icon to save a figure.';

    final removeTooltip = localization.isArabic
        ? 'إزالة من المفضلة'
        : 'Remove from favorites';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 75,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    emptyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = favorites[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpenProduct(product),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          _FavoriteProductImage(
                            imagePath: product.imagePath,
                          ),
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
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  product.category,
                                  style: TextStyle(
                                    color:
                                        Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  product.price,
                                  style: TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _statusLabel(
                                    product.status,
                                    localization,
                                  ),
                                  style: TextStyle(
                                    color: product.status ==
                                            'Available'
                                        ? Colors.green
                                        : product.status ==
                                                'Reserved'
                                            ? Colors.orange
                                            : Colors.red,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                onRemove(product),
                            icon: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            tooltip: removeTooltip,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _FavoriteProductImage extends StatelessWidget {
  final String? imagePath;

  const _FavoriteProductImage({
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null &&
        imagePath!.isNotEmpty &&
        File(imagePath!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: hasImage
          ? Image.file(
              File(imagePath!),
              width: 95,
              height: 95,
              fit: BoxFit.cover,
            )
          : Container(
              width: 95,
              height: 95,
              color: Colors.grey.shade200,
              child: const Icon(
                Icons.image_outlined,
                size: 42,
                color: Colors.grey,
              ),
            ),
    );
  }
}