import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'chat_service.dart';

import 'add_offer_item_page.dart';
import 'offer_details_page.dart';
import 'offer_model.dart';
import 'offer_service.dart';
import 'seller_profile_service.dart';

class OfferManagerPage extends StatelessWidget {
  final String offerId;

  const OfferManagerPage({super.key, required this.offerId});

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
                  builder: (_) => OfferDetailsPage(offerId: offerId),
                ),
              );
            },
          ),
          StreamBuilder<List<OfferItem>>(
            stream: offerService.watchOfferItems(offerId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];

              final canDelete = items.isNotEmpty;

              if (!canDelete) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'حذف العرض',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('حذف العرض؟'),
                        content: const Text(
                          'سيتم حذف العرض وجميع قطعه. هل أنت متأكد؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(false);
                            },
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(true);
                            },
                            child: const Text('حذف العرض'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed != true || !context.mounted) {
                    return;
                  }

                  try {
                    await offerService.deleteOffer(offerId);

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حذف العرض بنجاح')),
                    );
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تعذر حذف العرض: $error')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Offer?>(
        stream: offerService.watchOffer(offerId),
        builder: (context, offerSnapshot) {
          if (offerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (offerSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'حدث خطأ أثناء تحميل العرض:\n'
                  '${offerSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final offer = offerSnapshot.data;

          if (offer == null) {
            return const Center(child: Text('العرض غير موجود.'));
          }

          return StreamBuilder<SellerProfile?>(
            stream: SellerProfileService().watchSellerProfile(offer.sellerId),
            builder: (context, profileSnapshot) {
              final profile = profileSnapshot.data;

              final sellerName = profile?.name.trim().isNotEmpty == true
                  ? profile!.name
                  : 'مستخدم FigHub';

              final hasPhoto = profile?.photoUrl.isNotEmpty == true;

              return StreamBuilder<List<OfferItem>>(
                stream: offerService.watchOfferItems(offerId),
                builder: (context, itemsSnapshot) {
                  if (itemsSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !itemsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (itemsSnapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'حدث خطأ أثناء تحميل القطع:\n'
                          '${itemsSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final items = itemsSnapshot.data ?? [];

                  final reservedCount = items
                      .where((item) => item.status == 'Reserved')
                      .length;

                  final canDelete =
                      items.isNotEmpty && reservedCount == items.length;

                  final buyerGroups = <String, List<OfferItem>>{};
                  for (final item in items) {
                    final buyerId = item.reservedBy;
                    if (item.status == 'Reserved' &&
                        buyerId != null &&
                        buyerId.isNotEmpty) {
                      buyerGroups.putIfAbsent(buyerId, () => []).add(item);
                    }
                  }

                  return Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: hasPhoto
                                        ? NetworkImage(profile!.photoUrl)
                                        : null,
                                    child: hasPhoto
                                        ? null
                                        : const Icon(Icons.person_outline),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'صاحب العرض',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          sellerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Chip(
                                    avatar: Icon(
                                      Icons.storefront_outlined,
                                      size: 18,
                                    ),
                                    label: Text('عرضي'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                offer.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (offer.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(offer.description),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'القطع المحجوزة: '
                                    '$reservedCount / ${items.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (canDelete) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'جميع القطع محجوزة ويمكن حذف العرض.',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (buyerGroups.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'المشترون والحجوزات',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...buyerGroups.entries.map((entry) {
                                    final buyerId = entry.key;
                                    final buyerItems = entry.value;
                                    final total = buyerItems.fold<double>(0, (
                                      sum,
                                      item,
                                    ) {
                                      final price = item.price.replaceAll(
                                        RegExp(r'[^0-9.]'),
                                        '',
                                      );
                                      return sum +
                                          (double.tryParse(price) ?? 0);
                                    });

                                    return StreamBuilder<SellerProfile?>(
                                      stream: SellerProfileService()
                                          .watchSellerProfile(buyerId),
                                      builder: (context, profileSnapshot) {
                                        final buyerProfile =
                                            profileSnapshot.data;
                                        final buyerName =
                                            buyerProfile?.name
                                                    .trim()
                                                    .isNotEmpty ==
                                                true
                                            ? buyerProfile!.name
                                            : 'مستخدم FigHub';

                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            backgroundImage:
                                                buyerProfile
                                                        ?.photoUrl
                                                        .isNotEmpty ==
                                                    true
                                                ? NetworkImage(
                                                    buyerProfile!.photoUrl,
                                                  )
                                                : null,
                                            child:
                                                buyerProfile
                                                        ?.photoUrl
                                                        .isNotEmpty ==
                                                    true
                                                ? null
                                                : const Icon(
                                                    Icons.person_outline,
                                                  ),
                                          ),
                                          title: Text(buyerName),
                                          subtitle: Text(
                                            '${buyerItems.length} قطعة • '
                                            'الإجمالي: '
                                            '${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2)} جنيه',
                                          ),
                                          trailing: const Icon(
                                            Icons.chat_bubble_outline,
                                          ),
                                          onTap: () async {
                                            try {
                                              final chatService = ChatService();
                                              String? chatId;

                                              for (final reservedItem
                                                  in buyerItems) {
                                                final itemId = reservedItem.id;
                                                if (itemId == null ||
                                                    itemId.isEmpty) {
                                                  continue;
                                                }

                                                chatId = await chatService
                                                    .getOrCreateOfferChat(
                                                      offerId: offerId,
                                                      itemId: itemId,
                                                      itemName:
                                                          reservedItem.name,
                                                      price: reservedItem.price,
                                                      imagePaths: reservedItem
                                                          .imagePaths,
                                                      buyerId: buyerId,
                                                      sellerId: offer.sellerId,
                                                    );
                                              }

                                              if (!context.mounted) return;
                                              if (chatId == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'لم يتم العثور على قطع محجوزة صالحة لفتح المحادثة.',
                                                        ),
                                                      ),
                                                    );
                                                return;
                                              }

                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => ChatPage(
                                                    chatId: chatId!,
                                                    productName:
                                                        'حساب المشتريات',
                                                  ),
                                                ),
                                              );
                                            } catch (error) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'تعذر فتح المحادثة: $error',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'لم تتم إضافة أي قطع لهذا العرض بعد.\n'
                                    'اضغط على زر إضافة قطعة للبدء.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  100,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = items[index];

                                  return Card(
                                    child: ListTile(
                                      leading: item.imagePaths.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () => _showFullOfferImage(
                                                context,
                                                item.imagePaths.first,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  item.imagePaths.first,
                                                  width: 64,
                                                  height: 64,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      const SizedBox(
                                                        width: 64,
                                                        height: 64,
                                                        child: Icon(
                                                          Icons
                                                              .broken_image_outlined,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox(
                                              width: 64,
                                              height: 64,
                                              child: Icon(Icons.image_outlined),
                                            ),
                                      title: Text(item.name),
                                      subtitle: Text(
                                        '${item.price} جنيه • ${item.status}',
                                      ),
                                      trailing: Text(item.condition),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddOfferItemPage(offerId: offerId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة قطعة'),
      ),
    );
  }
}

void _showFullOfferImage(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(32),
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}
