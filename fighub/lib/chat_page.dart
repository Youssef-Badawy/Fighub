import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'chat_service.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String productName;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.productName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController =
      TextEditingController();

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
      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: message,
      );

      if (!mounted) {
        return;
      }

      _messageController.clear();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إرسال الرسالة.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _sendQuickMessage(
    String message,
  ) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: message,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إرسال الرسالة.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
  ) {
    final senderId = message['senderId'] as String? ?? '';
    final text = message['text'] as String? ?? '';

    final currentUserId =
        _chatService.currentUserId;

    final isMine = senderId == currentUserId;

    return Align(
      alignment: isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isMine
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final isArabic = localization.isArabic;

    final chatTitle = isArabic ? 'المحادثة' : 'Chat';

    final sendMessageHint =
        isArabic ? 'اكتب رسالة...' : 'Type a message...';

    final quickMessagesTitle =
        isArabic ? 'رسائل سريعة' : 'Quick messages';

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
        title: Text(
          '$chatTitle - ${widget.productName}',
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: Row(
              children: [
                const CircleAvatar(
                  child: Icon(
                    Icons.shopping_bag_outlined,
                  ),
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
          ),
          Expanded(
            child: StreamBuilder<
                List<Map<String, dynamic>>>(
              stream: _chatService.watchMessages(
                widget.chatId,
              ),
              builder: (
                context,
                snapshot,
              ) {
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

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages =
                    snapshot.data ?? const [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
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
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    return _buildMessageBubble(
                      context,
                      messages[index],
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                6,
                12,
                10,
              ),
              child: Column(
                children: [
                  StreamBuilder<
                      List<Map<String, dynamic>>>(
                    stream: _chatService.watchMessages(
                      widget.chatId,
                    ),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      final messages =
                          snapshot.data ?? const [];

                      if (messages.isNotEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 8,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 8,
                                right: 4,
                                left: 4,
                              ),
                              child: Text(
                                quickMessagesTitle,
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  label: Text(
                                    availableMessage,
                                  ),
                                  onPressed: _isSending
                                      ? null
                                      : () =>
                                          _sendQuickMessage(
                                            availableMessage,
                                          ),
                                ),
                                ActionChip(
                                  label: Text(
                                    moreInfoMessage,
                                  ),
                                  onPressed: _isSending
                                      ? null
                                      : () =>
                                          _sendQuickMessage(
                                            moreInfoMessage,
                                          ),
                                ),
                                ActionChip(
                                  label: Text(
                                    negotiateMessage,
                                  ),
                                  onPressed: _isSending
                                      ? null
                                      : () =>
                                          _sendQuickMessage(
                                            negotiateMessage,
                                          ),
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
                          controller:
                              _messageController,
                          textInputAction:
                              TextInputAction.send,
                          onSubmitted: (_) =>
                              _sendMessage(),
                          decoration:
                              InputDecoration(
                            hintText:
                                sendMessageHint,
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                24,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _isSending
                            ? null
                            : _sendMessage,
                        child: const Icon(
                          Icons.send,
                        ),
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