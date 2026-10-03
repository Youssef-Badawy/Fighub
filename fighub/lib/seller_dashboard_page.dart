import 'dart:io';

import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'product_model.dart';

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
  late List<Product> _products;

  @override
  void initState() {
    super.initState();
    _products = widget.products;
  }

  void _changeStatus(Product product, String status) {
    setState(() {
      product.status = status;
    });

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
  }

  Future<void> _deleteProduct(Product product) async {
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

    setState(() {
      _products.remove(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localization.isArabic
              ? 'تم حذف المنتج'
              : 'Product deleted.',
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;

    final title = isArabic
        ? 'لوحة البائع'
        : 'Seller Dashboard';

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
      body: Column(
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

                      final hasImage =
                          product.imagePath != null &&
                              product.imagePath!.isNotEmpty &&
                              File(product.imagePath!)
                                  .existsSync();

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
                                        BorderRadius.circular(
                                      12,
                                    ),
                                    child: hasImage
                                        ? Image.file(
                                            File(
                                              product.imagePath!,
                                            ),
                                            width: 95,
                                            height: 95,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 95,
                                            height: 95,
                                            color: Colors
                                                .grey
                                                .shade200,
                                            child: const Icon(
                                              Icons
                                                  .image_outlined,
                                              size: 42,
                                              color: Colors.grey,
                                            ),
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
                                          style:
                                              const TextStyle(
                                            fontSize: 17,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          product.price,
                                          style: TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            )
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
                                            color: Colors
                                                .grey
                                                .shade600,
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
                                            color: product
                                                        .status ==
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
      ),
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