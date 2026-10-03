import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'app_settings.dart';

class SettingsPage extends StatefulWidget {
  final AppSettings settings;

  const SettingsPage({
    super.key,
    required this.settings,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          _sectionTitle(l10n.language),

          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(
              widget.settings.isArabic
                  ? l10n.arabic
                  : l10n.english,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showLanguageDialog,
          ),

          const Divider(),

          _sectionTitle(l10n.notifications),

          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.notifications),
            subtitle: Text(
              widget.settings.isArabic
                  ? 'التحكم في إشعارات التطبيق'
                  : 'Control app notifications',
            ),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),

          const Divider(),

          _sectionTitle(l10n.account),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.account),
            subtitle: Text(
              widget.settings.isArabic
                  ? 'إدارة بيانات الحساب'
                  : 'Manage your account information',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showInfo(
                widget.settings.isArabic
                    ? 'قسم الحساب سيكون متاحًا بالكامل بعد إضافة تسجيل الدخول والحسابات.'
                    : 'Account management will be available after adding login and user accounts.',
              );
            },
          ),

          const Divider(),

          _sectionTitle(l10n.darkMode),

          SwitchListTile(
            secondary: Icon(
              darkModeEnabled
                  ? Icons.dark_mode
                  : Icons.light_mode_outlined,
            ),
            title: Text(l10n.darkMode),
            subtitle: Text(
              widget.settings.isArabic
                  ? 'تفعيل الوضع الداكن للتطبيق'
                  : 'Enable dark mode for the app',
            ),
            value: darkModeEnabled,
            onChanged: (value) {
              setState(() {
                darkModeEnabled = value;
              });

              _showInfo(
                value
                    ? (widget.settings.isArabic
                        ? 'تم تفعيل الوضع الداكن.'
                        : 'Dark mode enabled.')
                    : (widget.settings.isArabic
                        ? 'تم إيقاف الوضع الداكن.'
                        : 'Dark mode disabled.'),
              );
            },
          ),

          const Divider(),

          _sectionTitle(l10n.aboutFigHub),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutFigHub),
            subtitle: const Text('FigHub - Action Figures & Collectibles Marketplace'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog();
            },
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'FigHub',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final selectedLanguage =
        widget.settings.isArabic ? 'ar' : 'en';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  selectedLanguage == 'en'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(l10n.english),
                onTap: () async {
                  Navigator.pop(context);
                  await widget.settings.setLanguage('en');
                },
              ),
              ListTile(
                leading: Icon(
                  selectedLanguage == 'ar'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(l10n.arabic),
                onTap: () async {
                  Navigator.pop(context);
                  await widget.settings.setLanguage('ar');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.aboutFigHub),
          content: Text(
            widget.settings.isArabic
                ? 'FigHub هو سوق إلكتروني لبيع وشراء مجسمات الأكشن فيجرز والمقتنيات.'
                : 'FigHub is an online marketplace for buying and selling action figures and collectibles.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(l10n.close),
            ),
          ],
        );
      },
    );
  }
}