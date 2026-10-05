import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class WorkerPushService {
  static const String _workerUrl =
      'https://fighub.youssef-khaled-badawy.workers.dev';

  Future<void> sendPush({
    required String userId,
    required String title,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not get Firebase ID token.');
    }

    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'message': message,
      }),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        'Push Worker failed: '
        '${response.statusCode} ${response.body}',
      );
    }
  }
}
