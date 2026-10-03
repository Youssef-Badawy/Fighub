import 'dart:io';

import 'package:flutter/material.dart';

import 'product_details_page.dart';
import 'product_model.dart';
import 'product_service.dart';
import 'seller_profile_service.dart';

class SellerProfilePage extends StatefulWidget {
  final String sellerId;

  const SellerProfilePage({
    super.key,
    required this.sellerId,
  });

  @override
  State<SellerProfilePage> createState() =>
      _SellerProfilePageState();
}

class _SellerProfilePageState
    extends State<SellerProfilePage> {
  final SellerProfileService _sellerProfileService =
      SellerProfileService();

  final ProductService _productService =
      ProductService();

  SellerProfile? _sellerProfile;

  bool _isLoadingProfile = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    try {
      final profile =
          await _sellerProfileService.getSellerProfile(
        widget.sellerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sellerProfile = profile;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingProfile = false;
        _profileError = error.toString();
      });
    }
  }

  Widget _buildProfilePhoto() {
    final photoUrl = _sellerProfile?.photoUrl ?? '';

    if (photoUrl.isEmpty) {
      return const CircleAvatar(
        radius: 42,
        child: Icon(
          Icons.person,
          size: 44,
        ),
      );
    }

    if (photoUrl.startsWith('http://') ||
        photoUrl.startsWith('https://')) {
      return CircleAvatar(
        radius: 42,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: 42,
      backgroundImage: FileImage(
        File(photoUrl),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int productCount,
  ) {
    final theme = Theme.of(context);

    final sellerName =
        _sellerProfile?.name.isNotEmpty == true
            ? _sellerProfile!.name
            : 'FigHub Seller';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfilePhoto(),
            const SizedBox(height: 12),
            Text(
              sellerName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '$productCount products',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    final imagePath = product.imagePath;

    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        width: 85,
        height: 85,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_outlined,
          size: 38,
        ),
      );
    }

    final isNetworkImage =
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://');

    if (isNetworkImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imagePath,
          width: 85,
          height: 85,
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
        width: 85,
        height: 85,
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

  Widget _buildImageError() {
    return const SizedBox(
      width: 85,
      height: 85,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 38,
      ),
    );
  }

  Future<void> _openProduct(Product product) async {
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

  Widget _buildProductCard(Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _openProduct(product);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildProductImage(product),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${product.price} EGP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingProfile) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_profileError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'حدث خطأ أثناء تحميل بيانات البائع:\n$_profileError',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return StreamBuilder<List<Product>>(
      stream: _productService.watchSellerProducts(
        widget.sellerId,
      ),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'حدث خطأ أثناء تحميل منتجات البائع:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final products =
            snapshot.data ?? <Product>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(
              context,
              products.length,
            ),
            const SizedBox(height: 16),
            Text(
              'Products',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 50),
                child: Center(
                  child: Text(
                    'لا توجد منتجات معروضة حاليًا.',
                  ),
                ),
              )
            else
              ...products.map(
                (product) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10),
                  child: _buildProductCard(product),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sellerName =
        _sellerProfile?.name.isNotEmpty == true
            ? _sellerProfile!.name
            : 'Seller Profile';

    return Scaffold(
      appBar: AppBar(
        title: Text(sellerName),
      ),
      body: _buildContent(),
    );
  }
}