import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'follow_service.dart';
import 'chat_page.dart';
import 'chat_service.dart';
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

  final FollowService _followService =
      FollowService();

  SellerProfile? _sellerProfile;

  bool _isLoadingProfile = true;
  String? _profileError;
  bool _isFollowLoading = false;
  bool _isOpeningChat = false;

  final ChatService _chatService = ChatService();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

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

  Future<void> _openDirectChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == widget.sellerId ||
        _isOpeningChat) {
      return;
    }

    setState(() => _isOpeningChat = true);
    try {
      final chatId = await _chatService.getOrCreateDirectChat(
        otherUserId: widget.sellerId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            productName: 'محادثة مع ${_sellerProfile?.name ?? 'المستخدم'}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح المحادثة: $error')),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowLoading) {
      return;
    }

    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return;
    }

    if (currentUser.uid == widget.sellerId) {
      return;
    }

    setState(() {
      _isFollowLoading = true;
    });

    try {
      final isFollowing =
          await _followService.isFollowing(
        widget.sellerId,
      );

      if (isFollowing) {
        await _followService.unfollowUser(
          widget.sellerId,
        );
      } else {
        await _followService.followUser(
          widget.sellerId,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
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

    final currentUser = _auth.currentUser;
    final isOwnProfile =
        currentUser != null &&
        currentUser.uid == widget.sellerId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 138,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                image: (_sellerProfile?.coverUrl.isNotEmpty == true)
                    ? DecorationImage(
                        image: NetworkImage(_sellerProfile!.coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildProfilePhoto(),
            ),
            const SizedBox(height: 12),
            Text(
              sellerName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_sellerProfile?.bio.trim().isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                _sellerProfile!.bio,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                StreamBuilder<int>(
                  stream:
                      _followService.watchFollowersCount(
                    widget.sellerId,
                  ),
                  builder: (
                    context,
                    snapshot,
                  ) {
                    final count =
                        snapshot.data ?? 0;

                    return Column(
                      children: [
                        Text(
                          '$count',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Followers',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 32),
                StreamBuilder<int>(
                  stream:
                      _followService.watchFollowingCount(
                    widget.sellerId,
                  ),
                  builder: (
                    context,
                    snapshot,
                  ) {
                    final count =
                        snapshot.data ?? 0;

                    return Column(
                      children: [
                        Text(
                          '$count',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Following',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 32),
                Column(
                  children: [
                    Text(
                      '$productCount',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Products',
                    ),
                  ],
                ),
              ],
            ),
            if (!isOwnProfile) ...[
              const SizedBox(height: 18),
              StreamBuilder<bool>(
                stream:
                    _followService.watchIsFollowing(
                  widget.sellerId,
                ),
                builder: (
                  context,
                  snapshot,
                ) {
                  final isFollowing =
                      snapshot.data ?? false;

                  return Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isFollowLoading ? null : _toggleFollow,
                          icon: _isFollowLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  isFollowing
                                      ? Icons.person_remove_outlined
                                      : Icons.person_add_outlined,
                                ),
                          label: Text(isFollowing ? 'Following' : 'Follow'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isOpeningChat ? null : _openDirectChat,
                          icon: _isOpeningChat
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
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
