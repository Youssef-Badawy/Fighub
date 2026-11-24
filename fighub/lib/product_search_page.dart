import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'product_model.dart';
import 'search_service.dart';

class ProductSearchPage extends StatefulWidget {
  final List<Product> products;
  final ValueChanged<Product> onOpenProduct;

  const ProductSearchPage({
    super.key,
    required this.products,
    required this.onOpenProduct,
  });

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<Product> get _results {
    if (_query.trim().isEmpty) return widget.products;
    final ranked = <({Product product, int score})>[];
    for (final product in widget.products) {
      final searchableText = [
        product.name,
        product.category,
        product.description,
        product.price,
      ].join(' ');
      final score = SearchService.score(searchableText, _query);
      if (score > 0) ranked.add((product: product, score: score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked.map((entry) => entry.product).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final isArabic = AppLocalizations.of(context).isArabic;
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'البحث عن المنتجات' : 'Search products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _queryController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: isArabic\n                    ? 'اكتب اسم المنتج أو القسم أو الوصف'\n                    : 'Search by product, category, or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: isArabic ? 'مسح البحث' : 'Clear search',
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 52),
                          SizedBox(height: 12),
                          Text(
                            isArabic\n                                ? 'مفيش منتجات مطابقة. جرّب كلمة تانية.'\n                                : 'No matching products. Try another search.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(12),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = results[index];
                      final imageUrl = product.imagePath ?? '';
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          leading: SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: imageUrl.startsWith('https://') ||
                                      imageUrl.startsWith('http://')
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      cacheWidth: 192,
                                      errorBuilder: (_, _, _) => const ColoredBox(
                                        color: Color(0x11000000),
                                        child: Icon(Icons.broken_image_outlined),
                                      ),
                                    )
                                  : const ColoredBox(
                                      color: Color(0x11000000),
                                      child: Icon(Icons.inventory_2_outlined),
                                    ),
                            ),
                          ),
                          title: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${product.category} • ${product.price} ${isArabic ? 'ج.م' : 'EGP'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onOpenProduct(product);
                            });
                          },
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
