import 'package:flutter/material.dart';

import 'auth_manager.dart';
import 'auth_page.dart';

class AuthGate extends StatelessWidget {
  final AuthManager authManager;
  final Widget home;

  const AuthGate({
    super.key,
    required this.authManager,
    required this.home,
  });

  @override
  Widget build(BuildContext context) {
    if (authManager.isLoggedIn) {
      return home;
    }

    return AuthPage(
      authManager: authManager,
    );
  }
}