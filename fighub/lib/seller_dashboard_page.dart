import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'product_model.dart';
import 'product_service.dart';

class SellerDashboardPage extends StatefulWidget {
  final List<Product> products;

  const SellerDashboardPage({
    super.key,
    required this.products,
  });

  @override
  State<SellerDashboardPage> createState() =>
      _SellerDashboardPageState();
}

class _SellerDashboardPageState
    extends State<SellerDashboardPage> {
  final ProductService _productService = ProductService();

  final List<Product> _products = [];

  StreamSubscription<List<Product>>? _productsSubscription;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSellerProducts();
  }

  void _loadSellerProducts() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No signed-in user.';
      });
      return;
    }

    _productsSubscription = _productService
        .watchSellerProducts(user.uid)
        .listen(
      (products) {
        if (!mounted) {
          return;
        }

        setState(() {
          _products
            ..clear()
            ..addAll(products);
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _changeStatus(
    Product product,
    String status,
  ) async {
    if (product.id == null || product.id!.isEmpty) {
      return;
    }

    final previousStatus = product.status;

    setState(() {
      product.status = status;
    });

    try {
      final updatedProduct = Product(
        id: product.id,
        sellerId: product.sellerId,
        name: product.name,
        price: product.price,
        category: product.category,
        condition: product.condition,
        description: product.description,
        paymentMethod: product.paymentMethod,
        imagePath: product.imagePath,
        status: status,
      );

      await _productService.updateProduct(
        updatedProduct,
      );

      if (!mounted) {
        return;
      }

      final localization = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isArabic
                ? 'تم تغيير حالة ${product.name} إلى ${_statusLabel(status, localization)}'
                : '${product.name} status changed to ${_statusLabel(status, localization)}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        product.status = previousStatus;
      });

      final localization = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isArabic
                ? 'حدث خطأ أثناء تحديث حالة المنتج'
                : 'An error occurred while updating the product status',
          ),
        ),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.id == null || product.id!.isEmpty) {
      return;
    }

    final localization = AppLocalizations.of(context);

    final title = localization.isArabic
        ? 'حذف المنتج'
        : 'Delete Product';

    final message = localization.isArabic
        ? 'هل أنت متأكد من حذف "${product.name}"؟'
        : 'Are you sure you want to delete "${product.name}"?';

    final cancel = localization.isArabic
        ? 'إلغاء'
        : 'Cancel';

    final delete = localization.isArabic
        ? 'حذف'
        : 'Delete';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: Text(cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(delete),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      await _productService.deleteProduct(
        product.id!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isArabic
                ? 'تم حذف المنتج'
                : 'Product deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isArabic
                ? 'حدث خطأ أثناء حذف المنتج'
                : 'An error occurred while deleting the product',
          ),
        ),
      );
    }
  }

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

  String _conditionLabel(
    String condition,
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return condition;
    }

    switch (condition) {
      case 'New':
        return 'جديد';
      case 'Used':
        return 'مستعمل';
      case 'Rare':
        return 'نادر';
      default:
        return condition;
    }
  }

  Widget _buildProductImage(Product product) {
    final imagePath = product.imagePath;

    if (imagePath == null || imagePath.isEmpty) {
      return _buildImagePlaceholder();
    }

    final isNetworkImage =
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: 95,
        height: 95,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _buildImagePlaceholder();
        },
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            width: 95,
            height: 95,
            color: Colors.grey.shade200,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        },
      );
    }

    final localFile = File(imagePath);

    if (!localFile.existsSync()) {
      return _buildImagePlaceholder();
    }

    return Image.file(
      localFile,
      width: 95,
      height: 95,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _buildImagePlaceholder();
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 95,
      height: 95,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.image_outlined,
        size: 42,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;

    final title = isArabic
        ? 'منتجاتي'
        : 'My Products';

    final totalTitle =
        isArabic ? 'الإجمالي' : 'Total';

    final availableTitle =
        isArabic ? 'متاح' : 'Available';

    final reservedTitle =
        isArabic ? 'محجوز' : 'Reserved';

    final soldTitle =
        isArabic ? 'تم البيع' : 'Sold';

    final emptyTitle = isArabic
        ? 'لا توجد منتجات حتى الآن.'
        : 'No products yet.';

    final emptySubtitle = isArabic
        ? 'المنتجات التي تنشرها ستظهر هنا.'
        : 'Products you publish will appear here.';

    final deleteTooltip =
        isArabic ? 'حذف المنتج' : 'Delete product';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(
        localization,
        totalTitle,
        availableTitle,
        reservedTitle,
        soldTitle,
        emptyTitle,
        emptySubtitle,
        deleteTooltip,
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations localization,
    String totalTitle,
    String availableTitle,
    String reservedTitle,
    String soldTitle,
    String emptyTitle,
    String emptySubtitle,
    String deleteTooltip,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                localization.isArabic
                    ? 'حدث خطأ أثناء تحميل منتجاتك'
                    : 'An error occurred while loading your products',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: totalTitle,
                  value: _products.length.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: availableTitle,
                  value: _products
                      .where(
                        (product) =>
                            product.status == 'Available',
                      )
                      .length
                      .toString(),
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: reservedTitle,
                  value: _products
                      .where(
                        (product) =>
                            product.status == 'Reserved',
                      )
                      .length
                      .toString(),
                  icon: Icons.bookmark_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  title: soldTitle,
                  value: _products
                      .where(
                        (product) =>
                            product.status == 'Sold',
                      )
                      .length
                      .toString(),
                  icon: Icons.sell_outlined,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
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
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    16,
                  ),
                  itemCount: _products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final product = _products[index];

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: _buildProductImage(
                                    product,
                                  ),
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
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        '${product.category} • ${_conditionLabel(product.condition, localization)}',
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
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
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _deleteProduct(product),
                                  tooltip: deleteTooltip,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    _statusLabel(
                                      'Available',
                                      localization,
                                    ),
                                  ),
                                  selected:
                                      product.status ==
                                          'Available',
                                  onSelected: (_) =>
                                      _changeStatus(
                                    product,
                                    'Available',
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text(
                                    _statusLabel(
                                      'Reserved',
                                      localization,
                                    ),
                                  ),
                                  selected:
                                      product.status ==
                                          'Reserved',
                                  onSelected: (_) =>
                                      _changeStatus(
                                    product,
                                    'Reserved',
                                  ),
                                ),
                                ChoiceChip(
                                  label: Text(
                                    _statusLabel(
                                      'Sold',
                                      localization,
                                    ),
                                  ),
                                  selected:
                                      product.status ==
                                          'Sold',
                                  onSelected: (_) =>
                                      _changeStatus(
                                    product,
                                    'Sold',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 12,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 23,
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}