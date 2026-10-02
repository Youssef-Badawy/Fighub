import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product is ready to be published!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sell a Figure',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  height: 190,
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
                              Icons.add_photo_alternate_outlined,
                              size: 55,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Add product photos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap to choose a photo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            File(_selectedImage!.path),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Figure name',
                  hintText: 'e.g. Batman, Jon Snow...',
                  prefixIcon: Icon(Icons.toys_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the figure name';
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
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'EGP',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the price';
                  }

                  final price = double.tryParse(value);

                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
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
                    value: 'Game of Thrones',
                    child: Text('Game of Thrones'),
                  ),
                  DropdownMenuItem(
                    value: 'Anime',
                    child: Text('Anime'),
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
                  prefixIcon: Icon(Icons.inventory_2_outlined),
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

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell buyers about your figure...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_outlined),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Payment',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Product payment method',
                  prefixIcon: Icon(
                    Icons.account_balance_wallet_outlined,
                  ),
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

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1D),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Shipping fees are always paid on delivery.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _publishProduct,
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text(
                    'Publish Product',
                    style: TextStyle(
                      fontSize: 17,
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