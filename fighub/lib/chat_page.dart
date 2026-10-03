import 'package:flutter/material.dart';

import 'app_localizations.dart';

class ChatPage extends StatefulWidget {
  final String? productName;

  const ChatPage({
    super.key,
    this.productName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController =
      TextEditingController();

  final List<String> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(message);
      _messageController.clear();
    });
  }

  void _sendQuickMessage(String message) {
    setState(() {
      _messages.add(message);
    });
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
          widget.productName == null
              ? chatTitle
              : '$chatTitle - ${widget.productName}',
        ),
      ),
      body: Column(
        children: [
          if (widget.productName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
              child: Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.shopping_bag_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.productName!,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_messages.isEmpty)
            Expanded(
              child: Center(
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
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];

                  return Align(
                    alignment:
                        AlignmentDirectional.centerEnd,
                    child: Container(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                        onPressed: () =>
                            _sendQuickMessage(
                          availableMessage,
                        ),
                      ),
                      ActionChip(
                        label: Text(moreInfoMessage),
                        onPressed: () =>
                            _sendQuickMessage(
                          moreInfoMessage,
                        ),
                      ),
                      ActionChip(
                        label: Text(negotiateMessage),
                        onPressed: () =>
                            _sendQuickMessage(
                          negotiateMessage,
                        ),
                      ),
                    ],
                  ),
                ],
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: sendMessageHint,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send),
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