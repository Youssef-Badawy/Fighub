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

  Future<String> getOrCreateOfferChat({
    required String offerId,
    required String itemId,
    required String itemName,
    required List<String> imagePaths,
    required String buyerId,
    required String sellerId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (offerId.isEmpty || itemId.isEmpty) {
      throw ArgumentError('Offer ID and item ID are required.');
    }

    if (buyerId.isEmpty || sellerId.isEmpty) {
      throw ArgumentError('Buyer ID and seller ID are required.');
    }

    if (buyerId == sellerId) {
      throw StateError('Buyer and seller must be different.');
    }

    if (user.uid != sellerId) {
      throw StateError('Only the seller can start this offer chat.');
    }

    final participants = [buyerId, sellerId]..sort();

    // One combined offer chat per buyer/seller pair.
    final chatId = 'offer_${participants[0]}_${participants[1]}';

    final chatReference = _firestore.collection('chats').doc(chatId);

    final chatDocument = await chatReference.get();

    final newItem = {
      'offerId': offerId,
      'itemId': itemId,
      'itemName': itemName,
      'imagePaths': imagePaths,
    };

    if (!chatDocument.exists) {
      await chatReference.set({
        'offerId': offerId,
        'itemId': itemId,
        'productId': 'offer_$offerId',
        'productName': itemName,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'participants': [buyerId, sellerId],
        'offerItems': [newItem],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      });

      await _notificationService.addNotification(
        userId: buyerId,
        title: 'محادثة جديدة',
        message: 'بدأ البائع محادثة بخصوص $itemName.',
        productId: 'offer_$offerId',
        chatId: chatId,
      );
    } else {
      final existingData = chatDocument.data() ?? {};

      final rawItems = existingData['offerItems'];

      final existingItems = rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      final alreadyExists = existingItems.any(
        (item) => item['offerId'] == offerId && item['itemId'] == itemId,
      );

      if (!alreadyExists) {
        existingItems.add(newItem);
      }

      await chatReference.update({
        'offerItems': existingItems,
        'offerId': existingData['offerId'] ?? offerId,
        'itemId': existingData['itemId'] ?? itemId,
        'productId': existingData['productId'] ?? 'offer_$offerId',
        'productName': existingData['productName'] ?? itemName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
