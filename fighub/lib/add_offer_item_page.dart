import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'interests.dart';

import 'cloudinary_service.dart';
import 'offer_model.dart';
import 'offer_service.dart';

class AddOfferItemPage extends StatefulWidget {
  final String offerId;

  const AddOfferItemPage({
    super.key,
    required this.offerId,
  });

  @override
  State<AddOfferItemPage> createState() => _AddOfferItemPageState();
}

class _AddOfferItemPageState extends State<AddOfferItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final OfferService _offerService = OfferService();

  final List<XFile> _selectedImages = [];

  String _category = 'Other';
  String _condition = 'Used';
  bool _isSaving = false;

  final List<String> _categories = FigHubInterests.all;

  final List<String> _conditions = [
    'New',
    'Used',
    'Rare',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 85,
    );

    if (!mounted || images.isEmpty) {
      return;
    }

    setState(() {
      _selectedImages
        ..clear()
        ..addAll(images);
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر صورة واحدة على الأقل للقطعة.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final imageUrls = <String>[];

      for (final image in _selectedImages) {
        final url = await _cloudinaryService.uploadImage(image);
        imageUrls.add(url);
      }

      final item = OfferItem(
        name: _nameController.text.trim(),
        price: _priceController.text.trim(),
        category: _category,
        condition: _condition,
        description: _descriptionController.text.trim(),
        imagePaths: imageUrls,
      );

      await _offerService.addOfferItem(
        offerId: widget.offerId,
        item: item,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إضافة القطعة: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة قطعة للعرض'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _selectedImages.isEmpty
                      ? 'اختيار صور القطعة'
                      : 'تغيير الصور (${_selectedImages.length})',
                ),
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _selectedImages[index].path,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Container(
                              width: 110,
                              height: 110,
                              alignment: Alignment.center,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم القطعة',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اكتب اسم القطعة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'السعر بالجنيه',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اكتب السعر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _category = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                  border: OutlineInputBorder(),
                ),
                items: _conditions
                    .map(
                      (condition) => DropdownMenuItem(
                        value: condition,
                        child: Text(condition),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _condition = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'وصف القطعة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveItem,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSaving
                      ? 'جاري رفع الصور وحفظ القطعة...'
                      : 'حفظ القطعة',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
