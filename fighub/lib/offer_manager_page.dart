import 'package:flutter/material.dart';

import 'offer_model.dart';
import 'offer_service.dart';

class OfferManagerPage extends StatefulWidget {
  final String offerId;

  const OfferManagerPage({
    super.key,
    required this.offerId,
  });

  @override
  State<OfferManagerPage> createState() => _OfferManagerPageState();
}

class _OfferManagerPageState extends State<OfferManagerPage> {
  final OfferService _offerService = OfferService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العرض'),
      ),
      body: StreamBuilder<List<OfferItem>>(
        stream: _offerService.watchOfferItems(widget.offerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final items = snapshot.data ?? <OfferItem>[];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'لم تتم إضافة قطع للعرض بعد.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  leading: item.imagePaths.isEmpty
                      ? const CircleAvatar(
                          child: Icon(Icons.image_outlined),
                        )
                      : CircleAvatar(
                          backgroundImage:
                              NetworkImage(item.imagePaths.first),
                        ),
                  title: Text(
                    item.name.isEmpty
                        ? 'قطعة بدون اسم'
                        : item.name,
                  ),
                  subtitle: Text(
                    '${item.price} جنيه • ${item.status}',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'إضافة القطعة سنضيفها في الخطوة التالية.',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة قطعة'),
      ),
    );
  }
}
