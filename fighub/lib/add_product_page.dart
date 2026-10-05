import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'interests.dart';
import 'package:image_picker/image_picker.dart';

import 'app_localizations.dart';
import 'cloudinary_service.dart';
import 'product_model.dart';
import 'product_service.dart';

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
  final ProductService _productService = ProductService();
  final CloudinaryService _cloudinaryService =
      CloudinaryService();

  String _category = 'Marvel';
  String _condition = 'New';
  String _paymentMethod = 'Cash on Delivery';

  final List<XFile> _imageFiles = [];
  bool _isPublishing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isEmpty) {
        return;
      }

      setState(() {
        _imageFiles
          ..clear()
          ..addAll(images);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final localization = AppLocalizations.of(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            localization.isArabic
                ? 'حدث خطأ أثناء اختيار الصور:\n$error'
                : 'Error selecting images:\n$error',
          ),
        ),
      );
    }
  }

  void _removeImage(int index) {
    if (_isPublishing) {
      return;
    }

    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _publishProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).isArabic
                ? 'يجب تسجيل الدخول أولاً'
                : 'You must be logged in first',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final List<String> imageUrls = [];

      for (final imageFile in _imageFiles) {
        final imageUrl =
            await _cloudinaryService.uploadImage(imageFile);

        imageUrls.add(imageUrl);
      }

      final product = Product(
        name: _nameController.text.trim(),
        price: _priceController.text.trim(),
        category: _category,
        condition: _condition,
        description: _descriptionController.text.trim(),
        paymentMethod: _paymentMethod,
        imagePath:
            imageUrls.isNotEmpty ? imageUrls.first : null,
        imagePaths: imageUrls,
        sellerId: user.uid,
      );

      await _productService.addProduct(product);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, product);
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
                ? 'حدث خطأ أثناء نشر المنتج:\n$errorMessage'
                : 'An error occurred while publishing the product:\n$errorMessage',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
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

    final productNameHint = isArabic
        ? 'مثال: Spider-Man Figure'
        : 'Example: Spider-Man Figure';

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

    final addImagesText =
        isArabic ? 'إضافة صور' : 'Add Images';

    final changeImagesText =
        isArabic ? 'تغيير الصور' : 'Change Images';

    final noImagesText = isArabic
        ? 'لم يتم اختيار صور'
        : 'No images selected';

    final selectedImagesText = isArabic
        ? 'صور مختارة'
        : 'selected images';

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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: _imageFiles.isEmpty
                  ? SizedBox(
                      height: 180,
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 55,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            noImagesText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: _imageFiles.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final imageFile = _imageFiles[index];

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(12),
                              child:
                                  FutureBuilder<List<int>>(
                                future:
                                    imageFile.readAsBytes(),
                                builder: (
                                  context,
                                  snapshot,
                                ) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return Container(
                                      color:
                                          Colors.grey.shade200,
                                      child: const Center(
                                        child:
                                            CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasError ||
                                      snapshot.data == null) {
                                    return Container(
                                      color:
                                          Colors.grey.shade200,
                                      child: const Icon(
                                        Icons
                                            .broken_image_outlined,
                                        size: 35,
                                        color: Colors.grey,
                                      ),
                                    );
                                  }

                                  return Image.memory(
                                    Uint8List.fromList(
                                      snapshot.data!,
                                    ),
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            if (index == 0)
                              Positioned(
                                left: 6,
                                bottom: 6,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black
                                        .withValues(alpha: 0.65),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isArabic
                                        ? 'الرئيسية'
                                        : 'Main',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Material(
                                color: Colors.black54,
                                shape:
                                    const CircleBorder(),
                                child: InkWell(
                                  customBorder:
                                      const CircleBorder(),
                                  onTap: _isPublishing
                                      ? null
                                      : () =>
                                          _removeImage(index),
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.all(5),
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed:
                    _isPublishing ? null : _pickImages,
                icon: const Icon(
                  Icons.photo_library_outlined,
                ),
                label: Text(
                  _imageFiles.isEmpty
                      ? addImagesText
                      : '$changeImagesText '
                          '(${_imageFiles.length} $selectedImagesText)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              enabled: !_isPublishing,
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
              enabled: !_isPublishing,
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
              items: FigHubInterests.all.map((value) {
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
              onChanged: _isPublishing
                  ? null
                  : (value) {
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
              onChanged: _isPublishing
                  ? null
                  : (value) {
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
              enabled: !_isPublishing,
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
              onChanged: _isPublishing
                  ? null
                  : (value) {
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
                onPressed:
                    _isPublishing ? null : _publishProduct,
                icon: _isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.publish),
                label: Text(
                  _isPublishing
                      ? (isArabic
                          ? 'جاري النشر...'
                          : 'Publishing...')
                      : publishText,
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