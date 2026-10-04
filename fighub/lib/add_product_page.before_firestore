import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_localizations.dart';
import 'product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({
    super.key,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _priceController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String _category = 'Marvel';
  String _condition = 'New';
  String _paymentMethod = 'Cash on Delivery';

  String? _imagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _imagePath = image.path;
    });
  }

  void _publishProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
        ),
      );
      return;
    }

    final product = Product(
      name: _nameController.text.trim(),
      price: _priceController.text.trim(),
      category: _category,
      condition: _condition,
      description: _descriptionController.text.trim(),
      paymentMethod: _paymentMethod,
      imagePath: _imagePath,
      sellerId: user.uid,
    );

    Navigator.pop(context, product);
  }

  String _categoryLabel(
    String value,
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return value;
    }

    switch (value) {
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
        return value;
    }
  }

  String _conditionLabel(
    String value,
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return value;
    }

    switch (value) {
      case 'New':
        return 'جديد';
      case 'Used':
        return 'مستعمل';
      case 'Rare':
        return 'نادر';
      default:
        return value;
    }
  }

  String _paymentLabel(
    String value,
    AppLocalizations localization,
  ) {
    if (!localization.isArabic) {
      return value;
    }

    switch (value) {
      case 'Cash on Delivery':
        return 'الدفع عند الاستلام';
      case 'Electronic Wallet':
        return 'محفظة إلكترونية';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;

    final title = isArabic ? 'إضافة منتج' : 'Add Product';

    final productNameLabel =
        isArabic ? 'اسم المنتج' : 'Product name';

    final productNameHint =
        isArabic ? 'مثال: Spider-Man Figure' : 'Example: Spider-Man Figure';

    final priceLabel = isArabic ? 'السعر' : 'Price';

    final priceHint =
        isArabic ? 'مثال: 1500 جنيه' : 'Example: 1500 EGP';

    final categoryLabel = isArabic ? 'الفئة' : 'Category';

    final conditionLabel =
        isArabic ? 'الحالة' : 'Condition';

    final descriptionLabel =
        isArabic ? 'الوصف' : 'Description';

    final descriptionHint = isArabic
        ? 'اكتب تفاصيل المنتج وحالته...'
        : 'Describe the product and its condition...';

    final paymentLabel =
        isArabic ? 'طريقة الدفع' : 'Payment method';

    final addImageText =
        isArabic ? 'إضافة صورة' : 'Add Image';

    final changeImageText =
        isArabic ? 'تغيير الصورة' : 'Change Image';

    final publishText =
        isArabic ? 'نشر المنتج' : 'Publish Product';

    final requiredMessage =
        isArabic ? 'هذا الحقل مطلوب' : 'This field is required';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                ),
                child: _imagePath == null
                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            size: 55,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            addImageText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius:
                            BorderRadius.circular(16),
                        child: Image.file(
                          File(_imagePath!),
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  _imagePath == null
                      ? addImageText
                      : changeImageText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: productNameLabel,
                hintText: productNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return requiredMessage;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: priceLabel,
                hintText: priceHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return requiredMessage;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                labelText: categoryLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                'Marvel',
                'DC',
                'Game of Thrones',
                'Anime',
                'Star Wars',
                'Other',
              ].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    _categoryLabel(
                      value,
                      localization,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _category = value;
                });
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _condition,
              decoration: InputDecoration(
                labelText: conditionLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                'New',
                'Used',
                'Rare',
              ].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    _conditionLabel(
                      value,
                      localization,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _condition = value;
                });
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: descriptionLabel,
                hintText: descriptionHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(
                labelText: paymentLabel,
                border: const OutlineInputBorder(),
              ),
              items: [
                'Cash on Delivery',
                'Electronic Wallet',
              ].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(
                    _paymentLabel(
                      value,
                      localization,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _paymentMethod = value;
                });
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _publishProduct,
                icon: const Icon(Icons.publish),
                label: Text(
                  publishText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}