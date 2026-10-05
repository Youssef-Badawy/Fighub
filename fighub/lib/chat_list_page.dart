import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'chat_page.dart';
import 'chat_service.dart';

class ChatListPage extends StatelessWidget {
  final List<String> productNames;

  const ChatListPage({
    super.key,
    required this.productNames,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);

    final title =
        localization.isArabic ? 'المحادثات' : 'Messages';

    final emptyTitle = localization.isArabic
        ? 'لا توجد محادثات حتى الآن.'
        : 'No conversations yet.';

    final emptySubtitle = localization.isArabic
        ? 'ستظهر محادثات المنتجات هنا.'
        : 'Your product conversations will appear here.';

    final openConversation = localization.isArabic
        ? 'اضغط لفتح المحادثة'
        : 'Tap to open conversation';

    final loadingText = localization.isArabic
        ? 'جاري تحميل المحادثات...'
        : 'Loading conversations...';

    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.watchMyChats(),
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
            final error = snapshot.error.toString();

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 70,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localization.isArabic
                          ? 'حدث خطأ أثناء تحميل المحادثات'
                          : 'An error occurred while loading conversations',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SelectableText(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final chats = snapshot.data ?? const [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
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
                  Text(
                    emptySubtitle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final chat = chats[index];

              final chatId =
                  chat['id'] as String? ?? '';

              final productName =
                  chat['productName'] as String? ?? '';

              final lastMessage =
                  chat['lastMessage'] as String? ?? '';

              return StreamBuilder<
                  Map<String, dynamic>?>(
                stream: chatService.watchChatPartner(
                  chatId,
                ),
                builder: (context, partnerSnapshot) {
                  final partner =
                      partnerSnapshot.data;

                  final partnerName =
                      partner?['name']
                              as String? ??
                          '';

                  final partnerPhoto =
                      partner?['photoUrl']
                              as String? ??
                          '';

                  return Card(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            partnerPhoto.isNotEmpty
                                ? NetworkImage(
                                    partnerPhoto,
                                  )
                                : null,
                        child: partnerPhoto.isEmpty
                            ? const Icon(
                                Icons.person_outline,
                              )
                            : null,
                      ),
                      title: Text(
                        partnerName.isEmpty
                            ? (productName.isEmpty
                                ? (localization.isArabic
                                    ? 'مستخدم'
                                    : 'User')
                                : productName)
                            : partnerName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        lastMessage.isEmpty
                            ? openConversation
                            : lastMessage,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                      onTap: chatId.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(
                                    chatId: chatId,
                                    productName:
                                        productName,
                                  ),
                                ),
                              );
                            },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}