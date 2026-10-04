import 'package:flutter/material.dart';

import 'add_offer_item_page.dart';
import 'offer_details_page.dart';
import 'offer_model.dart';
import 'offer_service.dart';
import 'seller_profile_service.dart';

class OfferManagerPage extends StatelessWidget {
  final String offerId;

  const OfferManagerPage({
    super.key,
    required this.offerId,
  });

  @override
  Widget build(BuildContext context) {
    final offerService = OfferService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العرض'),
        actions: [
          IconButton(
            tooltip: 'معاينة العرض',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OfferDetailsPage(
                    offerId: offerId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<OfferItem>>(
        stream: offerService.watchOfferItems(offerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'حدث خطأ أثناء تحميل القطع:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لم تتم إضافة أي قطع لهذا العرض بعد.\n'
                  'اضغط على زر إضافة قطعة للبدء.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  leading: item.imagePaths.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imagePaths.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return const SizedBox(
                                width: 64,
                                height: 64,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                ),
                              );
                            },
                          ),
                        )
                      : const SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(Icons.image_outlined),
                        ),
                  title: Text(item.name),
                  subtitle: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: offerService.watchItemReservations(
                      offerId: offerId,
                      itemId: item.id!,
                    ),
                    builder: (context, reservationSnapshot) {
                      final reservations =
                          reservationSnapshot.data ?? [];

                      final activeReservation =
                          reservations.cast<Map<String, dynamic>?>().firstWhere(
                                (reservation) =>
                                    reservation?['status'] == 'Active',
                                orElse: () => null,
                              );

                      final reservedBy =
                          activeReservation?['userId'] as String?;

                      if (reservedBy == null) {
                        return Text(
                          '${item.price} جنيه • ${item.status}',
                        );
                      }

                      return StreamBuilder<SellerProfile?>(
                        stream: SellerProfileService()
                            .watchSellerProfile(reservedBy),
                        builder: (context, profileSnapshot) {
                          final profile = profileSnapshot.data;

                          final name = profile?.name.trim().isNotEmpty == true
                              ? profile!.name
                              : 'مستخدم FigHub';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.price} جنيه • ${item.status}',
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        profile?.photoUrl.isNotEmpty == true
                                            ? NetworkImage(profile!.photoUrl)
                                            : null,
                                    child:
                                        profile?.photoUrl.isNotEmpty == true
                                            ? null
                                            : const Icon(
                                                Icons.person_outline,
                                                size: 18,
                                              ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'محجوز بواسطة: $name',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  trailing: Text(item.condition),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddOfferItemPage(
                offerId: offerId,
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
