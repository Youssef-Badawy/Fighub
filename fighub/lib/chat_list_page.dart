import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'chat_page.dart';
import 'chat_service.dart';

class ChatListPage extends StatelessWidget {
  final List<String> productNames;

  const ChatListPage({super.key, required this.productNames});

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'المحادثات' : 'Messages'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.watchMyChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(isArabic ? 'جاري تحميل المحادثات...' : 'Loading conversations...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '${isArabic ? 'تعذر تحميل المحادثات' : 'Could not load conversations'}\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final chats = snapshot.data ?? const <Map<String, dynamic>>[];
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey),
                    const SizedBox(height: 14),
                    Text(
                      isArabic ? 'لا توجد محادثات حتى الآن' : 'No conversations yet',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isArabic
                          ? 'ستظهر محادثات العروض والمنتجات والطباعة هنا.'
                          : 'Offer, product, and printing chats will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final offers = chats.where((chat) => chatService.chatTypeFor(chat) == 'offers').toList();
          final products = chats.where((chat) {
            final type = chatService.chatTypeFor(chat);
            return type == 'ordinary' || type == 'products';
          }).toList();
          final printing = chats.where((chat) => chatService.chatTypeFor(chat) == 'printing').toList();
          final other = chats.where((chat) {
            final type = chatService.chatTypeFor(chat);
            return type != 'offers' && type != 'ordinary' && type != 'products' && type != 'printing';
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              _section(
                context,
                title: isArabic ? 'محادثات العروض الجماعية' : 'Group offer chats',
                icon: Icons.local_offer_outlined,
                chats: offers,
                service: chatService,
                isArabic: isArabic,
              ),
              _section(
                context,
                title: isArabic ? 'محادثات المنتجات العادية' : 'Regular product chats',
                icon: Icons.shopping_bag_outlined,
                chats: products,
                service: chatService,
                isArabic: isArabic,
              ),
              _section(
                context,
                title: isArabic ? 'محادثات 3D Printing' : '3D Printing chats',
                icon: Icons.print_outlined,
                chats: printing,
                service: chatService,
                isArabic: isArabic,
              ),
              if (other.isNotEmpty)
                _section(
                  context,
                  title: isArabic ? 'محادثات أخرى وسابقة' : 'Other and legacy chats',
                  icon: Icons.chat_outlined,
                  chats: other,
                  service: chatService,
                  isArabic: isArabic,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> chats,
    required ChatService service,
    required bool isArabic,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Text(
                chats.length.toString(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (chats.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  isArabic ? 'لا توجد محادثات في هذا القسم' : 'No chats in this section',
                  style: TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            )
          else
            ...chats.map((chat) => _chatTile(context, chat, service, isArabic)),
        ],
      ),
    );
  }

  Widget _chatTile(
    BuildContext context,
    Map<String, dynamic> chat,
    ChatService service,
    bool isArabic,
  ) {
    final chatId = chat['id'] as String? ?? '';
    final productName = chat['productName'] as String? ?? '';
    final lastMessage = chat['lastMessage'] as String? ?? '';

    return StreamBuilder<Map<String, dynamic>?>(
      stream: service.watchChatPartner(chatId),
      builder: (context, partnerSnapshot) {
        final partner = partnerSnapshot.data;
        final partnerName = partner?['name'] as String? ?? '';
        final photo = partner?['photoUrl'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty ? const Icon(Icons.person_outline) : null,
            ),
            title: Text(
              partnerName.isNotEmpty
                  ? partnerName
                  : (productName.isNotEmpty ? productName : (isArabic ? 'مستخدم' : 'User')),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              lastMessage.isEmpty
                  ? (isArabic ? 'اضغط لفتح المحادثة' : 'Tap to open conversation')
                  : lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onLongPress: chatId.isEmpty
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text(isArabic ? 'مسح سجل المحادثة عندك؟' : 'Clear chat history for you?'),
                        content: Text(
                          isArabic
                              ? 'سيتم إخفاء الرسائل القديمة عندك فقط، وسيحتفظ الطرف الآخر بالمحادثة.'
                              : 'Old messages will be hidden only for you. The other participant keeps the conversation.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: Text(isArabic ? 'مسح' : 'Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    try {
                      await service.deleteChat(chatId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isArabic ? 'تم مسح سجل المحادثة عندك' : 'Chat history cleared for you')),
                      );
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${isArabic ? 'تعذر مسح المحادثة' : 'Could not clear chat'}: $error')),
                      );
                    }
                  },
            onTap: chatId.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(chatId: chatId, productName: productName),
                      ),
                    );
                  },
          ),
        );
      },
    );
  }
}
