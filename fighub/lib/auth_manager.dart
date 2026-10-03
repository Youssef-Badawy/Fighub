import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager extends ChangeNotifier {
  static const String _loggedInKey = 'loggedIn';
  static const String _nameKey = 'userName';
  static const String _emailKey = 'userEmail';
  static const String _phoneKey = 'userPhone';

  bool _isLoggedIn = false;
  String _name = '';
  String _email = '';
  String _phone = '';

  bool get isLoggedIn => _isLoggedIn;
  String get name => _name;
  String get email => _email;
  String get phone => _phone;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();

    _isLoggedIn = preferences.getBool(_loggedInKey) ?? false;
    _name = preferences.getString(_nameKey) ?? '';
    _email = preferences.getString(_emailKey) ?? '';
    _phone = preferences.getString(_phoneKey) ?? '';

    notifyListeners();
  }

  Future<void> login({
    required String name,
    required String email,
    required String phone,
  }) async {
    _isLoggedIn = true;
    _name = name;
    _email = email;
    _phone = phone;

    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_loggedInKey, true);
    await preferences.setString(_nameKey, name);
    await preferences.setString(_emailKey, email);
    await preferences.setString(_phoneKey, phone);
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _name = '';
    _email = '';
    _phone = '';

    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_loggedInKey);
    await preferences.remove(_nameKey);
    await preferences.remove(_emailKey);
    await preferences.remove(_phoneKey);
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    _name = name;
    _email = email;
    _phone = phone;

    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_nameKey, name);
    await preferences.setString(_emailKey, email);
    await preferences.setString(_phoneKey, phone);
  }
}