import 'dart:io';

import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'chat_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final String name;
  final String price;
  final String category;
  final String condition;
  final String description;
  final String paymentMethod;
  final String? imagePath;
  final String status;
  final ValueChanged<String> onStatusChanged;

  const ProductDetailsPage({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.paymentMethod,
    required this.imagePath,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  State<ProductDetailsPage> createState() =>
      _ProductDetailsPageState();
}

class _ProductDetailsPageState
    extends State<ProductDetailsPage> {
  late String _productStatus;

  @override
  void initState() {
    super.initState();
    _productStatus = widget.status;
  }

  void _setStatus(String status) {
    setState(() {
      _productStatus = status;
    });

    widget.onStatusChanged(status);

    final localization = AppLocalizations.of(context);

    final message = localization.isArabic
        ? 'تم تغيير حالة المنتج إلى ${_statusLabel(status, localization)}'
        : 'Status changed to ${_statusLabel(status, localization)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _reserveProduct() {
    if (_productStatus != 'Available') {
      return;
    }

    _setStatus('Reserved');

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

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          productName: widget.name,
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
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return widget.condition;
    }

    switch (widget.condition) {
      case 'New':
        return 'جديد';
      case 'Used':
        return 'مستعمل';
      case 'Rare':
        return 'نادر';
      default:
        return widget.condition;
    }
  }

  String _categoryLabel(
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return widget.category;
    }

    switch (widget.category) {
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
        return widget.category;
    }
  }

  String _paymentLabel(
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return widget.paymentMethod;
    }

    switch (widget.paymentMethod) {
      case 'Cash on Delivery':
        return 'الدفع عند الاستلام';
      case 'Electronic Wallet':
        return 'محفظة إلكترونية';
      default:
        return widget.paymentMethod;
    }
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

    final hasImage = widget.imagePath != null &&
        widget.imagePath!.isNotEmpty &&
        File(widget.imagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: hasImage
                ? Image.file(
                    File(widget.imagePath!),
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: 280,
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
                  ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.price,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
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
            widget.description.trim().isEmpty
                ? noDescription
                : widget.description,
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
                selected: _productStatus == 'Available',
                onSelected: (_) =>
                    _setStatus('Available'),
              ),
              ChoiceChip(
                label: Text(
                  _statusLabel(
                    'Reserved',
                    localization,
                  ),
                ),
                selected: _productStatus == 'Reserved',
                onSelected: (_) =>
                    _setStatus('Reserved'),
              ),
              ChoiceChip(
                label: Text(
                  _statusLabel(
                    'Sold',
                    localization,
                  ),
                ),
                selected: _productStatus == 'Sold',
                onSelected: (_) =>
                    _setStatus('Sold'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (_productStatus == 'Available')
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _reserveProduct,
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
              onPressed: _openChat,
              icon: const Icon(
                Icons.chat_bubble_outline,
              ),
              label: Text(
                chatText,
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