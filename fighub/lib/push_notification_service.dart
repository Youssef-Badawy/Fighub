import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await _requestPermission();

    await _saveCurrentToken();

    _messaging.onTokenRefresh.listen(
      (token) async {
        await _saveToken(
          user.uid,
          token,
        );
      },
    );

    FirebaseMessaging.onMessage.listen(
      (message) {
        debugPrint(
          'FCM foreground message: '
          '${message.notification?.title}',
        );
      },
    );
  }

  Future<void> _requestPermission() async {
    final settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );
  }

  Future<void> _saveCurrentToken() async {
    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final token =
        await _messaging.getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    await _saveToken(
      user.uid,
      token,
    );
  }

  Future<void> _saveToken(
    String userId,
    String token,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set(
      {
        'fcmTokens': FieldValue.arrayUnion([
          token,
        ]),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
