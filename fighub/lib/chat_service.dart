import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService();

  String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  CollectionReference<Map<String, dynamic>>
      _messagesCollection(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages');
  }

  String createChatId({
    required String productId,
    required String buyerId,
    required String sellerId,
  }) {
    final participants = [
      buyerId,
      sellerId,
    ]..sort();

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
      throw ArgumentError(
        'Product ID is required.',
      );
    }

    if (sellerId.isEmpty) {
      throw ArgumentError(
        'Seller ID is required.',
      );
    }

    if (sellerId == user.uid) {
      throw StateError(
        'You cannot start a chat with yourself.',
      );
    }

    final chatId = createChatId(
      productId: productId,
      buyerId: user.uid,
      sellerId: sellerId,
    );

    final chatReference =
        _firestore.collection('chats').doc(chatId);

    final chatDocument =
        await chatReference.get();

    if (!chatDocument.exists) {
      await chatReference.set({
        'productId': productId,
        'productName': productName,
        'buyerId': user.uid,
        'sellerId': sellerId,
        'participants': [
          user.uid,
          sellerId,
        ],
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        'lastMessage': '',
      });

      await _notificationService.addNotification(
        userId: sellerId,
        title: 'محادثة جديدة',
        message:
            'بدأ مشتري محادثة بخصوص $productName.',
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
    required String buyerId,
    required String sellerId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('User must be signed in.');
    }

    if (offerId.isEmpty || itemId.isEmpty) {
      throw ArgumentError(
        'Offer ID and item ID are required.',
      );
    }

    if (buyerId.isEmpty || sellerId.isEmpty) {
      throw ArgumentError(
        'Buyer ID and seller ID are required.',
      );
    }

    if (buyerId == sellerId) {
      throw StateError(
        'Buyer and seller must be different.',
      );
    }

    if (user.uid != sellerId) {
      throw StateError(
        'Only the seller can start this offer chat.',
      );
    }

    final participants = [
      buyerId,
      sellerId,
    ]..sort();

    final chatId =
        'offer_${offerId}_${itemId}_${participants[0]}_${participants[1]}';

    final chatReference =
        _firestore.collection('chats').doc(chatId);

    final chatDocument =
        await chatReference.get();

    if (!chatDocument.exists) {
      await chatReference.set({
        'offerId': offerId,
        'itemId': itemId,
        'productId': 'offer_$offerId',
        'productName': itemName,
        'buyerId': buyerId,
        'sellerId': sellerId,
        'participants': [
          buyerId,
          sellerId,
        ],
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
        'lastMessage': '',
      });

      await _notificationService.addNotification(
        userId: buyerId,
        title: 'محادثة جديدة',
        message:
            'بدأ البائع محادثة بخصوص $itemName.',
        productId: 'offer_$offerId',
        chatId: chatId,
      );
    }

    return chatId;
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

    final chatReference =
        _firestore.collection('chats').doc(chatId);

    final chatDocument =
        await chatReference.get();

    if (!chatDocument.exists) {
      throw StateError('Chat not found.');
    }

    final chatData =
        chatDocument.data() ?? {};

    final buyerId =
        chatData['buyerId'] as String? ?? '';

    final sellerId =
        chatData['sellerId'] as String? ?? '';

    final productId =
        chatData['productId'] as String? ?? '';

    final productName =
        chatData['productName'] as String? ??
            'Product';

    if (buyerId.isEmpty || sellerId.isEmpty) {
      throw StateError(
        'Chat participants are missing.',
      );
    }

    if (user.uid != buyerId &&
        user.uid != sellerId) {
      throw StateError(
        'You are not a participant in this chat.',
      );
    }

    final recipientId =
        user.uid == buyerId
            ? sellerId
            : buyerId;

    await _messagesCollection(chatId).add({
      'senderId': user.uid,
      'text': message,
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    await chatReference.update({
      'lastMessage': message,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _notificationService.addNotification(
      userId: recipientId,
      title: 'رسالة جديدة',
      message:
          '$productName: $message',
      productId: productId,
      chatId: chatId,
    );
  }

  Stream<List<Map<String, dynamic>>> watchMessages(
    String chatId,
  ) {
    if (chatId.isEmpty) {
      return Stream.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _messagesCollection(chatId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  (document) => {
                    'id': document.id,
                    ...document.data(),
                  },
                )
                .toList();
          },
        );
  }

  Stream<List<Map<String, dynamic>>> watchMyChats() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _firestore
        .collection('chats')
        .where(
          'participants',
          arrayContains: user.uid,
        )
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  (document) => {
                    'id': document.id,
                    ...document.data(),
                  },
                )
                .toList();
          },
        );
  }

  Future<void> markChatAsRead(
    String chatId,
  ) async {
    final user = _auth.currentUser;

    if (user == null || chatId.isEmpty) {
      return;
    }

    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'lastReadBy': {
        user.uid:
            FieldValue.serverTimestamp(),
      },
    });
  }
}