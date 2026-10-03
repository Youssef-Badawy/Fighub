import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      _notificationsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  Future<void> addNotification({
    required String userId,
    required String title,
    required String message,
    String? productId,
    String? chatId,
  }) async {
    if (userId.isEmpty) {
      return;
    }

    await _notificationsCollection(userId).add({
      'title': title,
      'message': message,
      'productId': productId,
      'chatId': chatId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchMyNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        const <Map<String, dynamic>>[],
      );
    }

    return _notificationsCollection(user.uid)
        .orderBy(
          'createdAt',
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

  Future<void> markAsRead(
    String notificationId,
  ) async {
    final user = _auth.currentUser;

    if (user == null || notificationId.isEmpty) {
      return;
    }

    await _notificationsCollection(user.uid)
        .doc(notificationId)
        .update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final snapshot = await _notificationsCollection(user.uid)
        .where(
          'isRead',
          isEqualTo: false,
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final document in snapshot.docs) {
      batch.update(
        document.reference,
        {
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  Future<void> deleteNotification(
    String notificationId,
  ) async {
    final user = _auth.currentUser;

    if (user == null || notificationId.isEmpty) {
      return;
    }

    await _notificationsCollection(user.uid)
        .doc(notificationId)
        .delete();
  }
}