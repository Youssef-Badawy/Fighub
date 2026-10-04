import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'offer_model.dart';
import 'offer_service.dart';

class OfferDetailsPage extends StatelessWidget {
  final String offerId;

  const OfferDetailsPage({
    super.key,
    required this.offerId,
  });

  @override
  Widget build(BuildContext context) {
    final offerService = OfferService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل العرض'),
      ),
      body: StreamBuilder<Offer?>(
        stream: offerService.watchOffer(offerId),
        builder: (context, offerSnapshot) {
          if (offerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (offerSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'حدث خطأ أثناء تحميل العرض:\n${offerSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final offer = offerSnapshot.data;

          if (offer == null) {
            return const Center(
              child: Text('العرض غير موجود.'),
            );
          }

          final isActive = offerService.isOfferActive(offer);

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (offer.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(offer.description),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              isActive ? 'العرض متاح' : 'لم يبدأ بعد',
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (offer.scheduledAt != null)
                            Expanded(
                              child: Text(
                                'يبدأ: ${offer.scheduledAt}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<OfferItem>>(
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
              child: Text(
                'لا توجد قطع مضافة لهذا العرض حتى الآن.',
              ),
            );
          }

                    return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.imagePaths.isNotEmpty)
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Image.network(
                          item.imagePaths.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.price} جنيه',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(item.category),
                              ),
                              Chip(
                                label: Text(item.condition),
                              ),
                              Chip(
                                label: Text(item.status),
                              ),
                            ],
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(item.description),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: Builder(
                              builder: (context) {
                                final currentUserId =
                                    FirebaseAuth.instance.currentUser?.uid;

                                final isMyReservation =
                                    item.reservedBy != null &&
                                    item.reservedBy == currentUserId;

                                final waitingIndex =
                                    currentUserId == null
                                        ? -1
                                        : item.waitingUsers.indexOf(
                                            currentUserId,
                                          );

                                final isWaiting =
                                    waitingIndex >= 0;

                                final isFirstWaiting =
                                    isWaiting &&
                                    waitingIndex == 0;

                                if (isMyReservation) {
                                  return FilledButton.icon(
                                    onPressed: () async {
                                      final confirmed =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) {
                                          return AlertDialog(
                                            title: const Text(
                                              'إلغاء الحجز؟',
                                            ),
                                            content: const Text(
                                              'هل أنت متأكد أنك تريد إلغاء حجز هذه القطعة؟',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(dialogContext)
                                                      .pop(false);
                                                },
                                                child: const Text('لا'),
                                              ),
                                              FilledButton(
                                                onPressed: () {
                                                  Navigator.of(dialogContext)
                                                      .pop(true);
                                                },
                                                child: const Text(
                                                  'نعم، إلغاء',
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmed != true) return;

                                      try {
                                        await OfferService()
                                            .cancelReservation(
                                          offerId: offerId,
                                          itemId: item.id!,
                                        );

                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'تم إلغاء الحجز بنجاح',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تعذر إلغاء الحجز: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.bookmark_remove_outlined,
                                    ),
                                    label: const Text('إلغاء الحجز'),
                                  );
                                }

                                if (isWaiting) {
                                  if (isFirstWaiting &&
                                      isActive &&
                                      item.status == 'Available') {
                                    return FilledButton.icon(
                                      onPressed: () async {
                                        try {
                                          await OfferService()
                                              .claimWaitingReservation(
                                            offerId: offerId,
                                            itemId: item.id!,
                                          );

                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'تم استلام الحجز بنجاح',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'تعذر استلام الحجز: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      label: const Text(
                                        'استلام الحجز',
                                      ),
                                    );
                                  }

                                  return OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                      Icons.hourglass_top,
                                    ),
                                    label: Text(
                                      'أنت في الانتظار - ترتيبك ${waitingIndex + 1}',
                                    ),
                                  );
                                }

                                return FilledButton.icon(
                                  onPressed: !isActive
                                      ? null
                                      : item.status == 'Available'
                                          ? () async {
                                              try {
                                                await OfferService()
                                                    .reserveItem(
                                                  offerId: offerId,
                                                  itemId: item.id!,
                                                );

                                                if (!context.mounted) {
                                                  return;
                                                }

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'تم حجز القطعة بنجاح',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!context.mounted) {
                                                  return;
                                                }

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'تعذر حجز القطعة: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          : () async {
                                              try {
                                                await OfferService()
                                                    .reserveItem(
                                                  offerId: offerId,
                                                  itemId: item.id!,
                                                );

                                                if (!context.mounted) {
                                                  return;
                                                }

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'تمت إضافتك إلى قائمة الانتظار',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!context.mounted) {
                                                  return;
                                                }

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'تعذر الانضمام لقائمة الانتظار: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                  icon: const Icon(
                                    Icons.bookmark_border,
                                  ),
                                  label: Text(
                                    !isActive
                                        ? 'العرض لم يبدأ بعد'
                                        : item.status == 'Available'
                                            ? 'احجز القطعة'
                                            : 'انضم لقائمة الانتظار',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
