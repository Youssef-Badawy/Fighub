import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'notification_service.dart';

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

    final title =
        isArabic ? 'الإشعارات' : 'Notifications';

    final emptyTitle = isArabic
        ? 'لا توجد إشعارات حتى الآن.'
        : 'No notifications yet.';

    final emptySubtitle = isArabic
        ? 'ستظهر إشعارات المنتجات والحجوزات هنا.'
        : 'Product and reservation notifications will appear here.';

    final loadingText = isArabic
        ? 'جاري تحميل الإشعارات...'
        : 'Loading notifications...';

    final errorText = isArabic
        ? 'حدث خطأ أثناء تحميل الإشعارات.'
        : 'An error occurred while loading notifications.';

    final markAllReadText = isArabic
        ? 'تحديد الكل كمقروء'
        : 'Mark all as read';

    final service = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await service.markAllAsRead();
              } catch (_) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic
                          ? 'حدث خطأ أثناء تحديث الإشعارات.'
                          : 'Failed to update notifications.',
                    ),
                  ),
                );
              }
            },
            child: Text(markAllReadText),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.watchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(loadingText),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  errorText,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notificationList =
              snapshot.data ?? const [];

          if (notificationList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
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
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notificationList.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification =
                  notificationList[index];

              final notificationId =
                  notification['id'] as String? ?? '';

              final notificationTitle =
                  notification['title'] as String? ?? '';

              final message =
                  notification['message'] as String? ?? '';

              final isRead =
                  notification['isRead'] as bool? ?? false;

              final createdAt =
                  notification['createdAt'];

              String timeText =
                  isArabic ? 'الآن' : 'Just now';

              if (createdAt is Timestamp) {
                final dateTime = createdAt.toDate();
                final difference =
                    DateTime.now().difference(dateTime);

                if (difference.inMinutes < 1) {
                  timeText =
                      isArabic ? 'الآن' : 'Just now';
                } else if (difference.inHours < 1) {
                  final minutes =
                      difference.inMinutes;

                  timeText = isArabic
                      ? 'منذ $minutes دقيقة'
                      : '$minutes min ago';
                } else if (difference.inDays < 1) {
                  final hours =
                      difference.inHours;

                  timeText = isArabic
                      ? 'منذ $hours ساعة'
                      : '$hours hr ago';
                } else {
                  final days =
                      difference.inDays;

                  timeText = isArabic
                      ? 'منذ $days يوم'
                      : '$days day(s) ago';
                }
              }

              return Card(
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    child: Icon(
                      isRead
                          ? Icons.notifications_outlined
                          : Icons.notifications_active,
                    ),
                  ),
                  title: Text(
                    notificationTitle.isEmpty
                        ? (isArabic
                            ? 'إشعار'
                            : 'Notification')
                        : notificationTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isRead
                          ? FontWeight.w600
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(message),
                        const SizedBox(height: 4),
                        Text(timeText),
                      ],
                    ),
                  ),
                  onTap: notificationId.isEmpty
                      ? null
                      : () async {
                          if (!isRead) {
                            try {
                              await service.markAsRead(
                                notificationId,
                              );
                            } catch (_) {
                              if (!context.mounted) {
                                return;
                              }

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isArabic
                                        ? 'حدث خطأ أثناء تحديث الإشعار.'
                                        : 'Failed to update notification.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}