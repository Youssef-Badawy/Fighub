import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'chat_service.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String productName;

  const ChatPage({super.key, required this.chatId, required this.productName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService _chatService = ChatService();

  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(chatId: widget.chatId, text: message);

      if (!mounted) {
        return;
      }

      _messageController.clear();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إرسال الرسالة.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendQuickMessage(String message) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(chatId: widget.chatId, text: message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء إرسال الرسالة.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(
        chatId: widget.chatId,
        messageId: messageId,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك حذف هذه الرسالة.')),
      );
    }
  }

  Future<void> _confirmDeleteMessage(Map<String, dynamic> message) async {
    final messageId = message['id'] as String? ?? '';

    if (messageId.isEmpty) {
      return;
    }

    final senderId = message['senderId'] as String? ?? '';

    if (senderId != _chatService.currentUserId) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text('Do you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteMessage(messageId);
    }
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
  ) {
    final senderId = message['senderId'] as String? ?? '';

    final text = message['text'] as String? ?? '';

    final currentUserId = _chatService.currentUserId;

    final isMine = senderId == currentUserId;

    final bubble = Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );

    if (!isMine) {
      return bubble;
    }

    return GestureDetector(
      onLongPress: () {
        _confirmDeleteMessage(message);
      },
      child: bubble,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;

    final sendMessageHint = isArabic ? 'اكتب رسالة...' : 'Type a message...';

    final quickMessagesTitle = isArabic ? 'رسائل سريعة' : 'Quick messages';

    final availableMessage = isArabic
        ? 'هل المنتج ما زال متاحًا؟'
        : 'Is it still available?';

    final moreInfoMessage = isArabic
        ? 'هل يمكنك إخباري بالمزيد؟'
        : 'Can you tell me more?';

    final negotiateMessage = isArabic
        ? 'هل السعر قابل للتفاوض؟'
        : 'Is the price negotiable?';

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<Map<String, dynamic>?>(
          stream: _chatService.watchChatPartner(widget.chatId),
          builder: (context, snapshot) {
            final partner = snapshot.data;

            final partnerName = partner?['name'] as String? ?? '';

            final partnerPhoto = partner?['photoUrl'] as String? ?? '';

            return Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundImage: partnerPhoto.isNotEmpty
                      ? NetworkImage(partnerPhoto)
                      : null,
                  child: partnerPhoto.isEmpty
                      ? const Icon(Icons.person_outline, size: 21)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    partnerName.isEmpty ? widget.productName : partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<Map<String, dynamic>?>(
            stream: _chatService.watchChat(widget.chatId),
            builder: (context, chatSnapshot) {
              final chatData = chatSnapshot.data ?? {};

              final rawOfferItems = chatData['offerItems'];

              final offerItems = rawOfferItems is List
                  ? rawOfferItems
                        .whereType<Map>()
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList()
                  : <Map<String, dynamic>>[];

              if (offerItems.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.shopping_bag_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'القطع المحجوزة في هذه المحادثة'
                          : 'Reserved items in this chat',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 105,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: offerItems.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = offerItems[index];

                          final name = item['itemName'] as String? ?? '';

                          final rawImages = item['imagePaths'];

                          final images = rawImages is List
                              ? rawImages
                                    .whereType<String>()
                                    .where((image) => image.trim().isNotEmpty)
                                    .toList()
                              : <String>[];

                          final image = images.isNotEmpty ? images.first : '';

                          return Container(
                            width: 185,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 70,
                                    height: 85,
                                    child: image.isEmpty
                                        ? Container(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            child: const Icon(
                                              Icons
                                                  .image_not_supported_outlined,
                                            ),
                                          )
                                        : Image.network(
                                            image,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                    child: const Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                    ),
                                                  );
                                                },
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name.isEmpty
                                        ? (isArabic ? 'قطعة' : 'Item')
                                        : name,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.watchMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      isArabic
                          ? 'حدث خطأ أثناء تحميل المحادثة.'
                          : 'An error occurred while loading the chat.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? const [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isArabic
                              ? 'ابدأ المحادثة مع البائع'
                              : 'Start a conversation with the seller',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(context, messages[index]);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Column(
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatService.watchMessages(widget.chatId),
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? const [];

                      if (messages.isNotEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                                right: 4,
                                left: 4,
                              ),
                              child: Text(
                                quickMessagesTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  label: Text(availableMessage),
                                  onPressed: _isSending
                                      ? null
                                      : () =>
                                            _sendQuickMessage(availableMessage),
                                ),
                                ActionChip(
                                  label: Text(moreInfoMessage),
                                  onPressed: _isSending
                                      ? null
                                      : () =>
                                            _sendQuickMessage(moreInfoMessage),
                                ),
                                ActionChip(
                                  label: Text(negotiateMessage),
                                  onPressed: _isSending
                                      ? null
                                      : () =>
                                            _sendQuickMessage(negotiateMessage),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: sendMessageHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _isSending ? null : _sendMessage,
                        child: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
