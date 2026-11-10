import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_manager.dart';
import 'auth_page.dart';

Future<bool> requireRegisteredAccount(BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && !currentUser.isAnonymous) {
    return true;
  }

  final authManager = AuthManager();
  await authManager.load();
  if (!context.mounted) return false;

  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (routeContext) => AuthPage(
        authManager: authManager,
        onAuthenticated: () {
          Navigator.of(routeContext).pop(true);
        },
      ),
    ),
  );

  return result == true &&
      FirebaseAuth.instance.currentUser != null &&
      !(FirebaseAuth.instance.currentUser?.isAnonymous ?? true);
}
