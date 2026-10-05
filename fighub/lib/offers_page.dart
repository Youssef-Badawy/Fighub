import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'offer_details_page.dart';
import 'offer_manager_page.dart';
import 'offer_model.dart';
import 'offer_service.dart';
import 'seller_profile_service.dart';

class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final offerService = OfferService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('العروض الجماعية'),
      ),
      body: StreamBuilder<List<Offer>>(
        stream: offerService.watchOffers(),
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
                  'حدث خطأ أثناء تحميل العروض:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد عروض جماعية حاليًا.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final offer = offers[index];

              if (offer.id == null) {
                return const SizedBox.shrink();
              }

              final isOwner = currentUserId == offer.sellerId;

              return StreamBuilder<SellerProfile?>(
                stream: SellerProfileService()
                    .watchSellerProfile(offer.sellerId),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;

                  final sellerName =
                      profile?.name.trim().isNotEmpty == true
                          ? profile!.name
                          : 'مستخدم FigHub';

                  final hasPhoto =
                      profile?.photoUrl.isNotEmpty == true;

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => isOwner
                                ? OfferManagerPage(
                                    offerId: offer.id!,
                                  )
                                : OfferDetailsPage(
                                    offerId: offer.id!,
                                  ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: hasPhoto
                                      ? NetworkImage(
                                          profile!.photoUrl,
                                        )
                                      : null,
                                  child: hasPhoto
                                      ? null
                                      : const Icon(
                                          Icons.person_outline,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'صاحب العرض',
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        sellerName,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  const Chip(
                                    avatar: Icon(
                                      Icons.storefront_outlined,
                                      size: 18,
                                    ),
                                    label: Text('عرضي'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              offer.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              offer.description.isEmpty
                                  ? 'عرض جماعي على مجموعة من القطع.'
                                  : offer.description,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                if (isOwner)
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              OfferManagerPage(
                                            offerId: offer.id!,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.settings_outlined,
                                    ),
                                    label:
                                        const Text('إدارة العرض'),
                                  )
                                else
                                  const Text(
                                    'عرض التفاصيل',
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
