import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'app_localizations.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: productNames.isEmpty
          ? Center(
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
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: productNames.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final productName = productNames[index];

                return Card(
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      radius: 25,
                      child: Icon(
                        Icons.person_outline,
                      ),
                    ),
                    title: Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(openConversation),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            productName: productName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}