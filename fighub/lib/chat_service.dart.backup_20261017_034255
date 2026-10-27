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

      final index = items.indexWhere(
        (item) => item['offerId'] == offerId && item['itemId'] == itemId,
      );

      if (index >= 0) {
        final existing = items[index];
        if (existing['status'] != 'Cancelled' &&
            existing['status'] != 'Settled') {
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
    var completed = false;

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
        buyerConfirmed = true;
      } else {
        sellerConfirmed = true;
      }

      final updates = <String, dynamic>{
        'settlementBuyerConfirmed': buyerConfirmed,
        'settlementSellerConfirmed': sellerConfirmed,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (buyerConfirmed && sellerConfirmed) {
        final rawHistory = data['settledOrders'];
        final history = rawHistory is List
            ? List<dynamic>.from(rawHistory)
            : <dynamic>[];

        history.add({
          'items': activeItems,
          'settledAt': Timestamp.now(),
          'buyerId': buyerId,
          'sellerId': sellerId,
        });

        updates['settledOrders'] = history;
        updates['offerItems'] = items
            .where(
              (item) =>
                  item['status'] == 'Cancelled' || item['status'] == 'Settled',
            )
            .toList();
        updates['settlementBuyerConfirmed'] = false;
        updates['settlementSellerConfirmed'] = false;
        completed = true;
      }

      transaction.update(ref, updates);
    });

    return completed;
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
        items.add(item);
        newlyAdded = true;
      } else {
        // Refresh missing/old item details without duplicating the reservation.
        items[index] = {...items[index], ...item};
        if (items[index]['status'] == 'Cancelled' ||
            items[index]['status'] == 'Settled') {
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
    if (chatId.isEmpty) {
      return Stream.value(const <Map<String, dynamic>>[]);
    }

    return _messagesCollection(chatId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((document) => {'id': document.id, ...document.data()})
              .toList();
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
              .toList();
        });
  }

  Future<void> deleteChat(String chatId) async {
    final user = _auth.currentUser;

    if (user == null || chatId.isEmpty) {
      return;
    }

    final chatReference = _firestore.collection('chats').doc(chatId);

    final chatSnapshot = await chatReference.get();

    if (!chatSnapshot.exists) {
      return;
    }

    final chatData = chatSnapshot.data() ?? {};

    final participants = chatData['participants'];

    if (participants is! List || !participants.contains(user.uid)) {
      throw StateError('You are not a participant in this chat.');
    }

    await chatReference.delete();
  }

  Future<void> markChatAsRead(String chatId) async {
    final user = _auth.currentUser;

    if (user == null || chatId.isEmpty) {
      return;
    }

    await _firestore.collection('chats').doc(chatId).update({
      'lastReadBy': {user.uid: FieldValue.serverTimestamp()},
    });
  }
}
