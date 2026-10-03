import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const String _languageKey = 'language';
  static const String _darkModeKey = 'darkMode';

  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadSettings() async {
    final preferences =
        await SharedPreferences.getInstance();

    final savedLanguage =
        preferences.getString(_languageKey);

    if (savedLanguage == 'ar' || savedLanguage == 'en') {
      _locale = Locale(savedLanguage!);
    }

    final savedDarkMode =
        preferences.getBool(_darkModeKey) ?? false;

    _themeMode = savedDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'ar' && languageCode != 'en') {
      return;
    }

    _locale = Locale(languageCode);

    notifyListeners();

    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setString(
      _languageKey,
      languageCode,
    );
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();

    final preferences =
        await SharedPreferences.getInstance();

    await preferences.setBool(
      _darkModeKey,
      enabled,
    );
  }
}