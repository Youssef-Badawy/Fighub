import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;

  String _category = 'Marvel';
  String _condition = 'New';
  String _paymentMethod = 'Cash on delivery';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _publishProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final product = Product(
      name: _nameController.text.trim(),
      price: '${_priceController.text.trim()} EGP',
      category: _category,
      condition: _condition,
      description: _descriptionController.text.trim(),
      paymentMethod: _paymentMethod,
      imagePath: _selectedImage?.path,
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell a Figure'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1D),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.grey.shade800,
                    ),
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 55,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Add product photo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(_selectedImage!.path),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Figure name',
                  hintText: 'e.g. Batman',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the figure name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g. 1500',
                  border: OutlineInputBorder(),
                  suffixText: 'EGP',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Marvel',
                    child: Text('Marvel'),
                  ),
                  DropdownMenuItem(
                    value: 'DC',
                    child: Text('DC'),
                  ),
                  DropdownMenuItem(
                    value: 'Anime',
                    child: Text('Anime'),
                  ),
                  DropdownMenuItem(
                    value: 'Game of Thrones',
                    child: Text('Game of Thrones'),
                  ),
                  DropdownMenuItem(
                    value: 'Star Wars',
                    child: Text('Star Wars'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],
                onChanged: (value) {
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
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'New',
                    child: Text('New'),
                  ),
                  DropdownMenuItem(
                    value: 'Used - Excellent',
                    child: Text('Used - Excellent'),
                  ),
                  DropdownMenuItem(
                    value: 'Used - Good',
                    child: Text('Used - Good'),
                  ),
                  DropdownMenuItem(
                    value: 'Rare',
                    child: Text('Rare'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _condition = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Product payment',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Cash on delivery',
                    child: Text('Cash on delivery'),
                  ),
                  DropdownMenuItem(
                    value: 'Electronic wallet',
                    child: Text('Electronic wallet'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _paymentMethod = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell buyers about your figure...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _publishProduct,
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text(
                    'Publish Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}