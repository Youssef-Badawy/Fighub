import 'package:flutter/material.dart';

import 'app_localizations.dart';

class NotificationsPage extends StatelessWidget {
  final List<String> notifications;

  const NotificationsPage({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;

    final title = isArabic ? 'الإشعارات' : 'Notifications';

    final emptyTitle = isArabic
        ? 'لا توجد إشعارات حتى الآن.'
        : 'No notifications yet.';

    final emptySubtitle = isArabic
        ? 'ستظهر إشعارات المنتجات والحجوزات هنا.'
        : 'Product and reservation notifications will appear here.';

    final justNow = isArabic ? 'الآن' : 'Just now';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 75,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    emptyTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                    ),
                    child: Text(
                      emptySubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.notifications_outlined,
                      ),
                    ),
                    title: Text(
                      notification,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(justNow),
                    ),
                  ),
                );
              },
            ),
    );
  }
}