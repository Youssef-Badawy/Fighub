import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';
import 'worker_push_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService _notificationService = NotificationService();

  final WorkerPushService _workerPushService = WorkerPushService();

  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  CollectionReference<Map<String, dynamic>> _messagesCollection(String chatId) {
    return _firestore.collection('chats').doc(chatId).collection('messages');
  }

  String createChatId({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) {
    final participants = [buyerId, sellerId]..sort();

    return '${productId}_${participants[0]}_${participants[1]}';
  }

  Future<String> getOrCreateChat({
    required String productId,
    required String productName,
    required String sellerId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (productId.isEmpty) {
      throw ArgumentError('Product ID is required.');
    }

    if (sellerId.isEmpty) {
      throw ArgumentError('Seller ID is required.');
    }

    if (sellerId == user.uid) {
      throw StateError('You cannot start a chat with yourself.');
    }

    final chatId = createChatId(
      productId: productId,
      buyerId: user.uid,
      sellerId: sellerId,
    );

    final chatReference = _firestore.collection('chats').doc(chatId);

    final chatDocument = await chatReference.get();

    if (!chatDocument.exists) {
      await chatReference.set({
        'productId': productId,
        'productName': productName,
        'buyerId': user.uid,
        'sellerId': sellerId,
        'participants': [user.uid, sellerId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });

      await _notificationService.addNotification(
        userId: sellerId,
        title: 'محادثة جديدة',
        message: 'بدأ مشتري محادثة بخصوص $productName.',
        productId: productId,
        chatId: chatId,
      );
    }

    return chatId;
  }

  Future<String> addReservedProductToChat({
    required String productId,
    required String productName,
    required String price,
    required List<String> imagePaths,
    required String sellerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    if (productId.isEmpty || sellerId.isEmpty) {
      throw ArgumentError('Product ID and seller ID are required.');
    }
    if (user.uid == sellerId) {
      throw StateError('You cannot reserve your own product.');
    }

    final participants = [user.uid, sellerId]..sort();
    final chatId = 'offer_${participants[0]}_${participants[1]}';
    final ref = _firestore.collection('chats').doc(chatId);
    final newItem = <String, dynamic>{
      'source': 'product',
      'productId': productId,
      'itemId': productId,
      'itemName': productName,
      'price': price,
      'imagePaths': imagePaths,
      'reservedBy': user.uid,
      'status': 'Reserved',
    };

    var addedNewItem = false;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        transaction.set(ref, {
          'productId': 'combined_$chatId',
          'productName': 'حساب المشتريات',
          'buyerId': user.uid,
          'sellerId': sellerId,
          'participants': [user.uid, sellerId],
          'offerItems': [newItem],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': 'تم حجز $productName',
        });
        addedNewItem = true;
        return;
      }

      final data = snapshot.data()!;
      if (data['buyerId'] != user.uid ||
          data['sellerId'] != sellerId ||
          data['participants'] is! List ||
          !(data['participants'] as List).contains(user.uid) ||
          !(data['participants'] as List).contains(sellerId)) {
        throw StateError('Chat participants do not match.');
      }

      final rawItems = data['offerItems'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (items.any(
        (item) => item['source'] == 'product' && item['productId'] == productId,
      )) {
        return;
      }

      items.add(newItem);
      transaction.update(ref, {
        'offerItems': items,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': 'تم حجز $productName',
      });
      addedNewItem = true;
    });

    if (addedNewItem) {
      await _notificationService.addNotification(
        userId: sellerId,
        title: 'حجز منتج جديد',
        message: 'تم حجز $productName بواسطة مشتري.',
        productId: productId,
        chatId: chatId,
      );
    }

    return chatId;
  }

  Future<String> addReservedOfferItemToChat({
    required String offerId,
    required String itemId,
    required String itemName,
    required String price,
    required List<String> imagePaths,
    required String sellerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    if (offerId.isEmpty || itemId.isEmpty || sellerId.isEmpty) {
      throw ArgumentError('Offer, item, and seller IDs are required.');
    }
    if (user.uid == sellerId) {
      throw StateError('Buyer and seller must be different.');
    }

    final participants = [user.uid, sellerId]..sort();
    final chatId = 'offer_${participants[0]}_${participants[1]}';
    final ref = _firestore.collection('chats').doc(chatId);
    final newItem = <String, dynamic>{
      'source': 'offer',
      'offerId': offerId,
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'imagePaths': imagePaths,
      'reservedBy': user.uid,
      'status': 'Reserved',
    };

    var added = false;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        transaction.set(ref, {
          'productId': 'combined_$chatId',
          'productName': 'حساب المشتريات',
          'buyerId': user.uid,
          'sellerId': sellerId,
          'participants': [user.uid, sellerId],
          'offerItems': [newItem],
          'settlementBuyerConfirmed': false,
          'settlementSellerConfirmed': false,
          'settledOrders': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': 'تم حجز $itemName',
        });
        added = true;
        return;
      }

      final data = snapshot.data()!;
      final rawParticipants = data['participants'];
      if (data['buyerId'] != user.uid ||
          data['sellerId'] != sellerId ||
          rawParticipants is! List ||
          !rawParticipants.contains(user.uid) ||
          !rawParticipants.contains(sellerId)) {
        throw StateError('Chat participants do not match.');
      }

      final rawItems = data['offerItems'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      // Never restore an item that already belongs to a completed sale.
      final rawSettledOrders = data['settledOrders'];
      final wasSettled =
          rawSettledOrders is List &&
          rawSettledOrders.whereType<Map>().any((order) {
            final orderItems = order['items'];
            return orderItems is List &&
                orderItems.whereType<Map>().any(
                  (settledItem) =>
                      settledItem['offerId'] == offerId &&
                      settledItem['itemId'] == itemId,
                );
          });

      if (wasSettled) return;

      final index = items.indexWhere(
        (item) => item['offerId'] == offerId && item['itemId'] == itemId,
      );

      if (index >= 0) {
        final existing = items[index];
        if (existing['status'] != 'Cancelled') {
          return;
        }
        items[index] = newItem;
      } else {
        items.add(newItem);
      }

      transaction.update(ref, {
        'offerItems': items,
        'settlementBuyerConfirmed': false,
        'settlementSellerConfirmed': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': 'تم حجز $itemName',
      });
      added = true;
    });

    if (added) {
      await _notificationService.addNotification(
        userId: sellerId,
        title: 'حجز قطعة جديدة',
        message: 'تم حجز $itemName من العرض.',
        productId: 'offer_$offerId',
        chatId: chatId,
      );
    }
    return chatId;
  }

  Future<void> removeReservedOfferItemFromChat({
    required String offerId,
    required String itemId,
    required String sellerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    if (offerId.isEmpty || itemId.isEmpty || sellerId.isEmpty) return;

    final participants = [user.uid, sellerId]..sort();
    final ref = _firestore
        .collection('chats')
        .doc('offer_${participants[0]}_${participants[1]}');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final rawItems = data['offerItems'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      var changed = false;
      for (final item in items) {
        if (item['offerId'] == offerId &&
            item['itemId'] == itemId &&
            item['status'] != 'Cancelled') {
          item['status'] = 'Cancelled';
          changed = true;
        }
      }

      if (changed) {
        transaction.update(ref, {
          'offerItems': items,
          'settlementBuyerConfirmed': false,
          'settlementSellerConfirmed': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<bool> confirmSettlement({required String chatId}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    if (chatId.isEmpty) throw ArgumentError('Chat ID is required.');

    final ref = _firestore.collection('chats').doc(chatId);
    var bothConfirmed = false;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Chat not found.');

      final data = snapshot.data()!;
      final buyerId = data['buyerId'] as String? ?? '';
      final sellerId = data['sellerId'] as String? ?? '';
      if (user.uid != buyerId && user.uid != sellerId) {
        throw StateError('Only chat participants can confirm settlement.');
      }

      final rawItems = data['offerItems'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      final activeItems = items
          .where(
            (item) =>
                item['status'] != 'Cancelled' && item['status'] != 'Settled',
          )
          .toList();

      if (activeItems.isEmpty) {
        throw StateError('There are no active reserved items to settle.');
      }

      var buyerConfirmed = data['settlementBuyerConfirmed'] == true;
      var sellerConfirmed = data['settlementSellerConfirmed'] == true;

      if (user.uid == buyerId) {
        if (buyerConfirmed) throw StateError('Buyer already confirmed.');
        buyerConfirmed = true;
      } else {
        if (sellerConfirmed) throw StateError('Seller already confirmed.');
        sellerConfirmed = true;
      }

      bothConfirmed = buyerConfirmed && sellerConfirmed;

      // Each participant may update only their own confirmation.
      transaction.update(ref, {
        if (user.uid == buyerId)
          'settlementBuyerConfirmed': true
        else
          'settlementSellerConfirmed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return bothConfirmed;
  }

  Future<void> finalizeSettlement({required String chatId}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    if (chatId.isEmpty) throw ArgumentError('Chat ID is required.');

    final chatRef = _firestore.collection('chats').doc(chatId);

    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);
      if (!chatSnapshot.exists) throw StateError('Chat not found.');

      final data = chatSnapshot.data()!;
      final buyerId = data['buyerId'] as String? ?? '';
      final sellerId = data['sellerId'] as String? ?? '';

      if (user.uid != sellerId) {
        throw StateError('Only the seller can finalize the sale.');
      }
      if (buyerId.isEmpty ||
          data['settlementBuyerConfirmed'] != true ||
          data['settlementSellerConfirmed'] != true) {
        throw StateError('Both parties must confirm before finalization.');
      }

      final rawItems = data['offerItems'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      final activeItems = items
          .where(
            (item) =>
                item['status'] != 'Cancelled' && item['status'] != 'Settled',
          )
          .toList();

      if (activeItems.isEmpty) {
        throw StateError('There are no active reserved items to settle.');
      }

      final itemRefs = <DocumentReference<Map<String, dynamic>>>[];
      final reservationRefs = <DocumentReference<Map<String, dynamic>>>[];

      for (final item in activeItems) {
        final offerId = item['offerId'] as String? ?? '';
        final itemId = item['itemId'] as String? ?? '';
        if (offerId.isEmpty || itemId.isEmpty || item['source'] != 'offer') {
          throw StateError('Invalid offer item in settlement.');
        }

        final itemRef = _firestore
            .collection('offers')
            .doc(offerId)
            .collection('items')
            .doc(itemId);
        itemRefs.add(itemRef);
        reservationRefs.add(itemRef.collection('reservations').doc(buyerId));
      }

      // Read every document before writing anything in the transaction.
      final itemSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      final reservationSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final ref in itemRefs) {
        itemSnapshots.add(await transaction.get(ref));
      }
      for (final ref in reservationRefs) {
        reservationSnapshots.add(await transaction.get(ref));
      }

      for (var i = 0; i < activeItems.length; i++) {
        final itemSnapshot = itemSnapshots[i];
        final reservationSnapshot = reservationSnapshots[i];

        if (!itemSnapshot.exists || !reservationSnapshot.exists) {
          throw StateError('A reserved item or reservation no longer exists.');
        }

        final itemData = itemSnapshot.data()!;
        final reservationData = reservationSnapshot.data()!;

        if (itemData['status'] != 'Reserved' ||
            itemData['reservedBy'] != buyerId ||
            reservationData['status'] != 'Active' ||
            reservationData['userId'] != buyerId) {
          throw StateError('A reservation is no longer active.');
        }
      }

      final historyRaw = data['settledOrders'];
      final history = historyRaw is List
          ? List<dynamic>.from(historyRaw)
          : <dynamic>[];
      history.add({
        'items': activeItems,
        'settledAt': Timestamp.now(),
        'buyerId': buyerId,
        'sellerId': sellerId,
      });

      for (var i = 0; i < activeItems.length; i++) {
        transaction.update(itemRefs[i], {
          'status': 'Sold',
          'soldTo': buyerId,
          'soldAt': FieldValue.serverTimestamp(),
        });
        transaction.update(reservationRefs[i], {
          'status': 'Settled',
          'settledAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(chatRef, {
        'settledOrders': history,
        'offerItems': items
            .where(
              (item) =>
                  item['status'] == 'Cancelled' || item['status'] == 'Settled',
            )
            .toList(),
        'settlementBuyerConfirmed': false,
        'settlementSellerConfirmed': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': 'تم إتمام تسوية الحساب',
      });
    });
  }

  Future<String> getOrCreateOfferChat({
    required String offerId,
    required String itemId,
    required String itemName,
    required List<String> imagePaths,
    required String buyerId,
    required String sellerId,
    required String price,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    if (offerId.isEmpty ||
        itemId.isEmpty ||
        buyerId.isEmpty ||
        sellerId.isEmpty) {
      throw ArgumentError('Offer, item, buyer, and seller IDs are required.');
    }
    if (buyerId == sellerId) {
      throw StateError('Buyer and seller must be different.');
    }
    if (user.uid != sellerId) {
      throw StateError('Only the seller can open this offer chat.');
    }

    final participants = [buyerId, sellerId]..sort();
    final chatId = 'offer_${participants[0]}_${participants[1]}';
    final ref = _firestore.collection('chats').doc(chatId);

    final item = <String, dynamic>{
      'source': 'offer',
      'offerId': offerId,
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'imagePaths': imagePaths,
      'reservedBy': buyerId,
      'status': 'Reserved',
    };

    var newlyAdded = false;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);

      if (!snapshot.exists) {
        transaction.set(ref, {
          'productId': 'combined_$chatId',
          'productName': 'حساب المشتريات',
          'buyerId': buyerId,
          'sellerId': sellerId,
          'participants': [buyerId, sellerId],
          'offerItems': [item],
          'settlementBuyerConfirmed': false,
          'settlementSellerConfirmed': false,
          'settledOrders': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': 'تم حجز $itemName',
        });
        newlyAdded = true;
        return;
      }

      final data = snapshot.data()!;
      final rawParticipants = data['participants'];
      if (data['buyerId'] != buyerId ||
          data['sellerId'] != sellerId ||
          rawParticipants is! List ||
          !rawParticipants.contains(buyerId) ||
          !rawParticipants.contains(sellerId)) {
        throw StateError('Chat participants do not match.');
      }

      final rawItems = data['offerItems'];
      final items = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((value) => Map<String, dynamic>.from(value))
                .toList()
          : <Map<String, dynamic>>[];

      final index = items.indexWhere(
        (value) => value['offerId'] == offerId && value['itemId'] == itemId,
      );

      if (index < 0) {
        // Do not restore an item from a previously settled order
        // just because the seller opened the chat again.
        final rawSettledOrders = data['settledOrders'];
        final wasSettled =
            rawSettledOrders is List &&
            rawSettledOrders.whereType<Map>().any((order) {
              final orderItems = order['items'];
              return orderItems is List &&
                  orderItems.whereType<Map>().any(
                    (settledItem) =>
                        settledItem['offerId'] == offerId &&
                        settledItem['itemId'] == itemId,
                  );
            });

        if (!wasSettled) {
          items.add(item);
          newlyAdded = true;
        }
      } else {
        // Keep settled items out of the active total when opening the chat.
        final previousStatus = items[index]['status'];

        items[index] = {
          ...items[index],
          ...item,
          if (previousStatus == 'Settled') 'status': 'Settled',
        };

        // A cancelled item can be reactivated only when the manager
        // passes it again as an actually reserved offer item.
        if (previousStatus == 'Cancelled') {
          newlyAdded = true;
        }
      }

      final updates = <String, dynamic>{
        'offerItems': items,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newlyAdded) {
        updates['settlementBuyerConfirmed'] = false;
        updates['settlementSellerConfirmed'] = false;
        updates['lastMessage'] = 'تم حجز $itemName';
      }

      transaction.update(ref, updates);
    });

    if (newlyAdded) {
      await _notificationService.addNotification(
        userId: buyerId,
        title: 'محادثة العرض',
        message: 'تم تحديث تفاصيل القطعة: $itemName.',
        productId: 'offer_$offerId',
        chatId: chatId,
      );
    }

    return chatId;
  }

  Stream<Map<String, dynamic>?> watchChat(String chatId) {
    if (chatId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null);
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    final message = text.trim();

    if (chatId.isEmpty || message.isEmpty) {
      return;
    }

    final chatReference = _firestore.collection('chats').doc(chatId);

    final chatDocument = await chatReference.get();

    if (!chatDocument.exists) {
      throw StateError('Chat not found.');
    }

    final chatData = chatDocument.data() ?? {};

    final buyerId = chatData['buyerId'] as String? ?? '';

    final sellerId = chatData['sellerId'] as String? ?? '';

    final productId = chatData['productId'] as String? ?? '';

    final productName = chatData['productName'] as String? ?? 'Product';

    if (buyerId.isEmpty || sellerId.isEmpty) {
      throw StateError('Chat participants are missing.');
    }

    if (user.uid != buyerId && user.uid != sellerId) {
      throw StateError('You are not a participant in this chat.');
    }

    final recipientId = user.uid == buyerId ? sellerId : buyerId;

    await _messagesCollection(chatId).add({
      'senderId': user.uid,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatReference.update({
      'lastMessage': message,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.addNotification(
      userId: recipientId,
      title: 'رسالة جديدة',
      message: '$productName: $message',
      productId: productId,
      chatId: chatId,
    );

    try {
      await _workerPushService.sendPush(
        userId: recipientId,
        title: 'رسالة جديدة',
        message: '$productName: $message',
      );
    } catch (_) {
      // Push notification failure must not prevent
      // the chat message from being saved successfully.
    }
  }

  Future<void> sendMediaMessage({
    required String chatId,
    required String mediaUrl,
    required String mediaType,
    String caption = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    if (chatId.isEmpty || mediaUrl.trim().isEmpty) {
      throw StateError('Chat ID and media URL are required.');
    }
    if (mediaType != 'image' && mediaType != 'video' && mediaType != 'audio') {
      throw ArgumentError.value(mediaType, 'mediaType');
    }

    final chatRef = _firestore.collection('chats').doc(chatId);
    final snapshot = await chatRef.get();
    if (!snapshot.exists) throw StateError('Chat not found.');

    final data = snapshot.data() ?? <String, dynamic>{};
    final buyerId = data['buyerId'] as String? ?? '';
    final sellerId = data['sellerId'] as String? ?? '';
    final productId = data['productId'] as String? ?? '';
    final productName = data['productName'] as String? ?? 'Product';

    if (buyerId.isEmpty || sellerId.isEmpty) {
      throw StateError('Chat participants are missing.');
    }
    if (user.uid != buyerId && user.uid != sellerId) {
      throw StateError('You are not a participant in this chat.');
    }

    final recipientId = user.uid == buyerId ? sellerId : buyerId;
    final trimmedCaption = caption.trim();
    final label = mediaType == 'image'
        ? '📷 صورة'
        : mediaType == 'video'
        ? '🎥 فيديو'
        : '🎙️ رسالة صوتية';
    final lastMessage = trimmedCaption.isEmpty
        ? label
        : '$label: $trimmedCaption';

    await _messagesCollection(chatId).add({
      'senderId': user.uid,
      'text': trimmedCaption,
      'type': mediaType,
      'mediaUrl': mediaUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': lastMessage,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.addNotification(
      userId: recipientId,
      title: 'رسالة جديدة',
      message: '$productName: $lastMessage',
      productId: productId,
      chatId: chatId,
    );

    try {
      await _workerPushService.sendPush(
        userId: recipientId,
        title: 'رسالة جديدة',
        message: '$productName: $lastMessage',
      );
    } catch (_) {
      // Push failure must not prevent the message from being saved.
    }
  }

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final user = _auth.currentUser;

    if (user == null || chatId.isEmpty || messageId.isEmpty) {
      return;
    }

    final messageReference = _messagesCollection(chatId).doc(messageId);

    final messageSnapshot = await messageReference.get();

    if (!messageSnapshot.exists) {
      return;
    }

    final messageData = messageSnapshot.data() ?? {};

    if (messageData['senderId'] != user.uid) {
      throw StateError('You can only delete your own messages.');
    }

    await messageReference.delete();

    final latestMessages = await _messagesCollection(chatId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    final latestMessage = latestMessages.docs.isEmpty
        ? null
        : latestMessages.docs.first.data();

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': latestMessage?['text'] as String? ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<Map<String, dynamic>?> watchChatPartner(String chatId) {
    final user = _auth.currentUser;

    if (user == null || chatId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore.collection('chats').doc(chatId).snapshots().asyncMap((
      chatSnapshot,
    ) async {
      if (!chatSnapshot.exists) {
        return null;
      }

      final data = chatSnapshot.data() ?? {};
      final participants = data['participants'];

      if (participants is! List) {
        return null;
      }

      final participantIds = participants.whereType<String>().toList();

      final otherUserId = participantIds.firstWhere(
        (id) => id != user.uid,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) {
        return null;
      }

      final profileSnapshot = await _firestore
          .collection('seller_profiles')
          .doc(otherUserId)
          .get();

      if (!profileSnapshot.exists) {
        return {'id': otherUserId, 'name': '', 'photoUrl': ''};
      }

      final profile = profileSnapshot.data() ?? {};

      return {
        'id': otherUserId,
        'name': profile['name'] as String? ?? '',
        'photoUrl': profile['photoUrl'] as String? ?? '',
      };
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String chatId) {
    final user = _auth.currentUser;
    if (chatId.isEmpty || user == null) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    final chatReference = _firestore.collection('chats').doc(chatId);

    // Re-evaluate visible messages whenever either the chat cutoff or
    // the underlying message collection changes, without extra packages.
    return Stream<List<Map<String, dynamic>>>.multi((controller) {
      List<QueryDocumentSnapshot<Map<String, dynamic>>>? latestMessages;
      Map<String, dynamic>? latestChat;
      var closed = false;

      void emitVisibleMessages() {
        if (closed || latestMessages == null || latestChat == null) return;

        final clearedAtMap = latestChat!['clearedAt'];
        final cutoff = clearedAtMap is Map ? clearedAtMap[user.uid] : null;

        final visible = latestMessages!
            .where((document) {
              if (cutoff is! Timestamp) return true;
              final createdAt = document.data()['createdAt'];
              return createdAt is Timestamp && createdAt.compareTo(cutoff) > 0;
            })
            .map((document) => {'id': document.id, ...document.data()})
            .toList();

        controller.add(visible);
      }

      final chatSubscription = chatReference.snapshots().listen((snapshot) {
        latestChat = snapshot.data() ?? <String, dynamic>{};
        emitVisibleMessages();
      }, onError: controller.addError);

      final messagesSubscription = _messagesCollection(chatId)
          .orderBy('createdAt')
          .snapshots()
          .listen((snapshot) {
            latestMessages = snapshot.docs;
            emitVisibleMessages();
          }, onError: controller.addError);

      controller.onCancel = () {
        closed = true;
        chatSubscription.cancel();
        messagesSubscription.cancel();
      };
    });
  }

  Stream<List<Map<String, dynamic>>> watchMyChats() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((document) => {'id': document.id, ...document.data()})
              .where((chat) {
                final clearedAtMap = chat['clearedAt'];
                final cutoff = clearedAtMap is Map
                    ? clearedAtMap[user.uid]
                    : null;
                final updatedAt = chat['updatedAt'];

                if (cutoff is! Timestamp || updatedAt is! Timestamp) {
                  return true;
                }
                return updatedAt.compareTo(cutoff) > 0;
              })
              .toList();
        });
  }

  Future<void> deleteChat(String chatId) async {
    final user = _auth.currentUser;
    if (user == null || chatId.isEmpty) {
      throw StateError('You must be signed in to clear a chat.');
    }

    final chatReference = _firestore.collection('chats').doc(chatId);
    final chatSnapshot = await chatReference.get();

    if (!chatSnapshot.exists) return;

    final chatData = chatSnapshot.data() ?? {};
    final participants = chatData['participants'];

    if (participants is! List || !participants.contains(user.uid)) {
      throw StateError('You are not a participant in this chat.');
    }

    // Clear history for this user only; keep shared messages and order data.
    await chatReference.update({
      'clearedAt.${user.uid}': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markChatAsRead(String chatId) async {
    final user = _auth.currentUser;

    if (user == null || chatId.isEmpty) {
      return;
    }

    await _firestore.collection('chats').doc(chatId).update({
      'lastReadBy.${user.uid}': FieldValue.serverTimestamp(),
    });
  }
}
