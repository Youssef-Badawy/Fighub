import 'package:flutter/material.dart';

import 'offer_model.dart';
import 'offer_service.dart';

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final OfferService _offerService = OfferService();

  DateTime? _scheduledAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _scheduledAt ?? now,
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledAt != null
          ? TimeOfDay.fromDateTime(_scheduledAt!)
          : TimeOfDay.now(),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final offer = Offer(
        sellerId: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledAt: _scheduledAt,
        status: _scheduledAt == null ? 'Draft' : 'Scheduled',
      );

      final offerId = await _offerService.createOffer(offer);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(offerId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إنشاء العرض: $error'),
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
        title: const Text('إنشاء عرض جديد'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم العرض',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'اكتب اسم العرض';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'وصف العرض',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: const Text('موعد العرض'),
                subtitle: Text(
                  _scheduledAt == null
                      ? 'لم يتم تحديد موعد'
                      : _scheduledAt.toString(),
                ),
                trailing: TextButton(
                  onPressed: _isSaving ? null : _pickDateTime,
                  child: const Text('اختيار'),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _createOffer,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isSaving ? 'جاري الإنشاء...' : 'إنشاء العرض',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
