import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_localizations.dart';
import 'chat_page.dart';
import 'chat_service.dart';
import 'product_model.dart';
import 'product_service.dart';
import 'seller_profile_page.dart';
import 'seller_profile_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final ValueChanged<String> onStatusChanged;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.onStatusChanged,
  });

  @override
  State<ProductDetailsPage> createState() =>
      _ProductDetailsPageState();
}

class _ProductDetailsPageState
    extends State<ProductDetailsPage> {
  final ProductService _productService = ProductService();
  final ChatService _chatService = ChatService();
  final SellerProfileService _sellerProfileService =
      SellerProfileService();

  late String _productStatus;
  bool _isUpdatingStatus = false;
  bool _isOpeningChat = false;
  bool _isLoadingSeller = true;

  SellerProfile? _sellerProfile;

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _productStatus = widget.product.status;
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    if (widget.product.sellerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingSeller = false;
        });
      }
      return;
    }

    try {
      final profile =
          await _sellerProfileService.getSellerProfile(
        widget.product.sellerId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sellerProfile = profile;
        _isLoadingSeller = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingSeller = false;
      });
    }
  }

  Future<void> _openSellerProfile() async {
    if (widget.product.sellerId.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerProfilePage(
          sellerId: widget.product.sellerId,
        ),
      ),
    );
  }

  Future<void> _setStatus(String status) async {
    if (_isUpdatingStatus || status == _productStatus) {
      return;
    }

    final previousStatus = _productStatus;

    setState(() {
      _productStatus = status;
      _isUpdatingStatus = true;
    });

    try {
      final updatedProduct = Product(
        id: widget.product.id,
        sellerId: widget.product.sellerId,
        name: widget.product.name,
        price: widget.product.price,
        category: widget.product.category,
        condition: widget.product.condition,
        description: widget.product.description,
        paymentMethod: widget.product.paymentMethod,
        imagePath: widget.product.imagePath,
        imagePaths: widget.product.imagePaths,
        status: status,
      );

      await _productService.updateProduct(
        updatedProduct,
      );

      widget.product.status = status;
      widget.onStatusChanged(status);

      if (!mounted) {
        return;
      }

      final localization = AppLocalizations.of(context);

      final message = localization.isArabic
          ? 'تم تغيير حالة المنتج إلى ${_statusLabel(status, localization)}'
          : 'Status changed to ${_statusLabel(status, localization)}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _productStatus = previousStatus;
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
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _reserveProduct() async {
    if (_productStatus != 'Available' ||
        _isUpdatingStatus) {
      return;
    }

    await _setStatus('Reserved');

    if (!mounted) {
      return;
    }

    final localization = AppLocalizations.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localization.isArabic
              ? 'تم حجز المنتج بنجاح'
              : 'Product reserved successfully.',
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    if (_isOpeningChat) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      final localization = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isArabic
                ? 'يجب تسجيل الدخول أولًا.'
                : 'You must sign in first.',
          ),
        ),
      );

      return;
    }

    final productId = widget.product.id;

    if (productId == null || productId.isEmpty) {
      if (!mounted) {
        return;
      }

      final localization = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isArabic
                ? 'لا يمكن فتح المحادثة لهذا المنتج.'
                : 'Unable to open chat for this product.',
          ),
        ),
      );

      return;
    }

    if (widget.product.sellerId.isEmpty ||
        widget.product.sellerId == user.uid) {
      if (!mounted) {
        return;
      }

      final localization = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.isArabic
                ? 'لا يمكنك بدء محادثة مع نفسك.'
                : 'You cannot start a chat with yourself.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isOpeningChat = true;
    });

    try {
      final chatId = await _chatService.getOrCreateChat(
        productId: productId,
        productName: widget.product.name,
        sellerId: widget.product.sellerId,
      );

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: chatId,
            productName: widget.product.name,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final localization = AppLocalizations.of(context);

      final errorMessage = error.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            localization.isArabic
                ? 'خطأ فتح المحادثة:\n$errorMessage'
                : 'Chat opening error:\n$errorMessage',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningChat = false;
        });
      }
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
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return widget.product.condition;
    }

    switch (widget.product.condition) {
      case 'New':
        return 'جديد';
      case 'Used':
        return 'مستعمل';
      case 'Rare':
        return 'نادر';
      default:
        return widget.product.condition;
    }
  }

  String _categoryLabel(
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return widget.product.category;
    }

    switch (widget.product.category) {
      case 'Marvel':
        return 'مارفل';
      case 'DC':
        return 'دي سي';
      case 'Game of Thrones':
        return 'صراع العروش';
      case 'Anime':
        return 'أنمي';
      case 'Star Wars':
        return 'حرب النجوم';
      case 'Other':
        return 'أخرى';
      default:
        return widget.product.category;
    }
  }

  String _paymentLabel(
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return widget.product.paymentMethod;
    }

    switch (widget.product.paymentMethod) {
      case 'Cash on Delivery':
        return 'الدفع عند الاستلام';
      case 'Electronic Wallet':
        return 'محفظة إلكترونية';
      default:
        return widget.product.paymentMethod;
    }
  }

  List<String> _getImages() {
    if (widget.product.imagePaths.isNotEmpty) {
      return widget.product.imagePaths;
    }

    if (widget.product.imagePath != null &&
        widget.product.imagePath!.isNotEmpty) {
      return [widget.product.imagePath!];
    }

    return [];
  }

  Widget _buildSellerCard(
    BuildContext context,
    AppLocalizations localization,
  ) {
    final sellerName =
        _sellerProfile?.name.isNotEmpty == true
            ? _sellerProfile!.name
            : localization.isArabic
                ? 'البائع'
                : 'Seller';

    final sellerPhoto =
        _sellerProfile?.photoUrl ?? '';

    final viewProfileText = localization.isArabic
        ? 'عرض صفحة البائع'
        : 'View Seller Profile';

    Widget sellerImage;

    if (_isLoadingSeller) {
      sellerImage = CircleAvatar(
        radius: 28,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    } else if (sellerPhoto.isNotEmpty &&
        (sellerPhoto.startsWith('http://') ||
            sellerPhoto.startsWith('https://'))) {
      sellerImage = CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(sellerPhoto),
        onBackgroundImageError: (_, _) {},
      );
    } else if (sellerPhoto.isNotEmpty) {
      sellerImage = CircleAvatar(
        radius: 28,
        backgroundImage: FileImage(
          File(sellerPhoto),
        ),
      );
    } else {
      sellerImage = const CircleAvatar(
        radius: 28,
        child: Icon(
          Icons.person,
          size: 30,
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isLoadingSeller
            ? null
            : _openSellerProfile,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              sellerImage,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.isArabic
                          ? 'البائع'
                          : 'Seller',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sellerName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      viewProfileText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(
    String imagePath,
    String noImage,
  ) {
    final isNetworkImage =
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _buildImagePlaceholder(noImage);
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
            width: double.infinity,
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    final localFile = File(imagePath);

    if (!localFile.existsSync()) {
      return _buildImagePlaceholder(noImage);
    }

    return Image.file(
      localFile,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _buildImagePlaceholder(noImage);
      },
    );
  }

  Widget _buildImagePlaceholder(String noImage) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_outlined,
            size: 70,
            color: Colors.grey,
          ),
          const SizedBox(height: 10),
          Text(noImage),
        ],
      ),
    );
  }

  Widget _buildImageGallery(String noImage) {
    final images = _getImages();

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildImagePlaceholder(noImage),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildImageItem(
                  images[index],
                  noImage,
                );
              },
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final imagePath = images[index];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    padding: EdgeInsets.all(
                      _currentImageIndex == index
                          ? 3
                          : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            _currentImageIndex == index
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8),
                      child: _buildThumbnail(
                        imagePath,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_currentImageIndex + 1} / ${images.length}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnail(String imagePath) {
    final isNetworkImage =
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.broken_image_outlined,
              color: Colors.grey,
            ),
          );
        },
      );
    }

    final localFile = File(imagePath);

    if (!localFile.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_outlined,
          color: Colors.grey,
        ),
      );
    }

    return Image.file(
      localFile,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(
            Icons.broken_image_outlined,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;

    final title = isArabic
        ? 'تفاصيل المنتج'
        : 'Product Details';

    final descriptionTitle =
        isArabic ? 'الوصف' : 'Description';

    final categoryTitle =
        isArabic ? 'الفئة' : 'Category';

    final conditionTitle =
        isArabic ? 'الحالة' : 'Condition';

    final paymentTitle =
        isArabic ? 'طريقة الدفع' : 'Payment Method';

    final statusTitle =
        isArabic ? 'حالة المنتج' : 'Product Status';

    final reserveText =
        isArabic ? 'حجز المنتج' : 'Reserve Product';

    final chatText =
        isArabic ? 'محادثة مع البائع' : 'Chat Seller';

    final noDescription = isArabic
        ? 'لا يوجد وصف للمنتج.'
        : 'No description available.';

    final noImage = isArabic
        ? 'لا توجد صورة'
        : 'No Image';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImageGallery(noImage),
          const SizedBox(height: 18),
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.product.price} EGP',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(height: 18),
          _buildSellerCard(
            context,
            localization,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _InfoRow(
                    title: categoryTitle,
                    value: _categoryLabel(localization),
                  ),
                  const Divider(),
                  _InfoRow(
                    title: conditionTitle,
                    value: _conditionLabel(localization),
                  ),
                  const Divider(),
                  _InfoRow(
                    title: paymentTitle,
                    value: _paymentLabel(localization),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            descriptionTitle,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.product.description.trim().isEmpty
                ? noDescription
                : widget.product.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            statusTitle,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
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
                    _productStatus == 'Available',
                onSelected: _isUpdatingStatus
                    ? null
                    : (_) {
                        _setStatus('Available');
                      },
              ),
              ChoiceChip(
                label: Text(
                  _statusLabel(
                    'Reserved',
                    localization,
                  ),
                ),
                selected:
                    _productStatus == 'Reserved',
                onSelected: _isUpdatingStatus
                    ? null
                    : (_) {
                        _setStatus('Reserved');
                      },
              ),
              ChoiceChip(
                label: Text(
                  _statusLabel(
                    'Sold',
                    localization,
                  ),
                ),
                selected:
                    _productStatus == 'Sold',
                onSelected: _isUpdatingStatus
                    ? null
                    : (_) {
                        _setStatus('Sold');
                      },
              ),
            ],
          ),
          if (_isUpdatingStatus) ...[
            const SizedBox(height: 12),
            const Center(
              child: CircularProgressIndicator(),
            ),
          ],
          const SizedBox(height: 22),
          if (_productStatus == 'Available')
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isUpdatingStatus
                    ? null
                    : _reserveProduct,
                icon: const Icon(
                  Icons.bookmark_add_outlined,
                ),
                label: Text(
                  reserveText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isOpeningChat
                  ? null
                  : _openChat,
              icon: _isOpeningChat
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.chat_bubble_outline,
                    ),
              label: Text(
                _isOpeningChat
                    ? (isArabic
                        ? 'جاري فتح المحادثة...'
                        : 'Opening chat...')
                    : chatText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}