import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'app_localizations.dart';
import 'chat_service.dart';
import 'cloudinary_service.dart';

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
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void dispose() {
    _messageController.dispose();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  Future<void> _startVoiceRecording() async {
    if (_isSending || _isRecording) return;

    final isArabic = AppLocalizations.of(context).isArabic;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic ? 'لازم تسمح باستخدام الميكروفون لتسجيل رسالة صوتية.' : 'Microphone permission is required to record a voice message.',
            ),
          ),
        );
        return;
      }

      final path =
          '${Directory.systemTemp.path}/fighub_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: path,
      );

      if (!mounted) {
        await _audioRecorder.stop();
        return;
      }

      setState(() => _isRecording = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تعذر بدء تسجيل الصوت.' : 'Could not start recording.',
          ),
        ),
      );
    }
  }

  Future<void> _cancelVoiceRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      // Best effort cleanup when cancelling a recording.
    } finally {
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopAndSendVoiceMessage() async {
    if (!_isRecording || _isSending) return;

    final isArabic = AppLocalizations.of(context).isArabic;
    String? path;

    setState(() {
      _isRecording = false;
      _isSending = true;
    });

    try {
      path = await _audioRecorder.stop();
      if (path == null || path.isEmpty) {
        throw StateError('Recording did not produce a file.');
      }

      final url = await CloudinaryService().uploadAudio(path);
      await _chatService.sendMediaMessage(
        chatId: widget.chatId,
        mediaUrl: url,
        mediaType: 'audio',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم إرسال الرسالة الصوتية.' : 'Voice message sent.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تعذر إرسال الصوت. راجع الاتصال وإعدادات Cloudinary.' : 'Could not send audio. Check your connection and Cloudinary settings.',
          ),
        ),
      );
    } finally {
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // A leftover temporary file does not affect the sent message.
        }
      }
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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

  Future<void> _pickAndSendMedia() async {
    if (_isSending) return;

    final isArabic = AppLocalizations.of(context).isArabic;
    final selectedType = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text(isArabic ? 'إرسال صورة' : 'Send a photo'),
              onTap: () => Navigator.pop(sheetContext, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text(isArabic ? 'إرسال فيديو' : 'Send a video'),
              onTap: () => Navigator.pop(sheetContext, 'video'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selectedType == null) return;

    try {
      final picker = ImagePicker();
      final file = selectedType == 'image'
          ? await picker.pickImage(source: ImageSource.gallery)
          : await picker.pickVideo(source: ImageSource.gallery);

      if (!mounted || file == null) return;
      setState(() => _isSending = true);

      final cloudinary = CloudinaryService();
      final url = selectedType == 'image'
          ? await cloudinary.uploadImage(file)
          : await cloudinary.uploadVideo(file);

      await _chatService.sendMediaMessage(
        chatId: widget.chatId,
        mediaUrl: url,
        mediaType: selectedType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تم إرسال الوسائط بنجاح.' : 'Media sent successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تعذر إرسال الوسائط. راجع الاتصال وإعدادات Cloudinary.' : 'Could not send media. Check your connection and Cloudinary settings.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
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

  Future<void> _confirmOrderSettlement() async {
    try {
      final bothConfirmed = await _chatService.confirmSettlement(
        chatId: widget.chatId,
      );
      if (!mounted) return;

      final isArabic = AppLocalizations.of(context).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bothConfirmed
                ? (isArabic
                    ? 'تم تأكيد الطرفين. البائع يقدر الآن يتمم البيع.'
                    : 'Both parties confirmed. The seller can now finalize the sale.')
                : (isArabic
                    ? 'تم تسجيل تأكيدك. ننتظر تأكيد الطرف الآخر.'
                    : 'Your confirmation was saved. Waiting for the other party.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final isArabic = AppLocalizations.of(context).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر تأكيد الحساب. تأكد من وجود قطع محجوزة.'
                : 'Could not confirm settlement. Check active reservations.',
          ),
        ),
      );
    }
  }

  Future<void> _finalizeOrderSettlement() async {
    try {
      await _chatService.finalizeSettlement(chatId: widget.chatId);
      if (!mounted) return;
      final isArabic = AppLocalizations.of(context).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إتمام البيع وحفظ سجل الحساب.'
                : 'Sale finalized and order history saved.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final isArabic = AppLocalizations.of(context).isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر إتمام البيع. راجع الحجوزات وقواعد Firestore.'
                : 'Could not finalize the sale. Check reservations and Firestore rules.',
          ),
        ),
      );
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
    final type = message['type'] as String? ?? 'text';
    final mediaUrl = message['mediaUrl'] as String? ?? '';

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'image' && mediaUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  mediaUrl,
                  width: 230,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      width: 230,
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 230,
                    height: 100,
                    child: Center(child: Icon(Icons.broken_image, size: 36)),
                  ),
                ),
              ),
            if (type == 'video' && mediaUrl.isNotEmpty)
              _ChatVideoPlayer(url: mediaUrl),
            if (type == 'audio' && mediaUrl.isNotEmpty)
              _ChatAudioPlayer(
                url: mediaUrl,
                isArabic: AppLocalizations.of(context).isArabic,
              ),
            if (text.isNotEmpty) ...[
              if (type != 'text') const SizedBox(height: 6),
              Text(text, style: const TextStyle(fontSize: 15)),
            ],
          ],
        ),
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
                        .where(
                          (item) =>
                              item['status'] != 'Cancelled' &&
                              item['status'] != 'Settled',
                        )
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
                                GestureDetector(
                                  onTap: image.isEmpty
                                      ? null
                                      : () =>
                                            _showFullChatImage(context, image),
                                  child: ClipRRect(
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
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        name.isEmpty
                                            ? (isArabic ? 'قطعة' : 'Item')
                                            : name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${item['price'] ?? '0'} ${isArabic ? 'جنيه' : 'EGP'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
          StreamBuilder<Map<String, dynamic>?>(
            stream: _chatService.watchChat(widget.chatId),
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) return const SizedBox.shrink();

              final rawItems = data['offerItems'];
              final items = rawItems is List
                  ? rawItems
                        .whereType<Map>()
                        .map((item) => Map<String, dynamic>.from(item))
                        .where(
                          (item) =>
                              item['status'] != 'Cancelled' &&
                              item['status'] != 'Settled',
                        )
                        .toList()
                  : <Map<String, dynamic>>[];

              if (items.isEmpty) return const SizedBox.shrink();

              double total = 0;
              for (final item in items) {
                final rawPrice = (item['price'] ?? '0').toString();
                final cleaned = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
                total += double.tryParse(cleaned) ?? 0;
              }

              final uid = _chatService.currentUserId;
              final buyerId = data['buyerId'] as String? ?? '';
              final sellerId = data['sellerId'] as String? ?? '';
              final buyerConfirmed = data['settlementBuyerConfirmed'] == true;
              final sellerConfirmed = data['settlementSellerConfirmed'] == true;
              final isBuyer = uid != null && uid == buyerId;
              final isSeller = uid != null && uid == sellerId;
              final alreadyConfirmed = isBuyer
                  ? buyerConfirmed
                  : isSeller
                  ? sellerConfirmed
                  : true;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: Theme.of(context).colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isArabic ? 'إجمالي الحساب' : 'Order total'}: '
                      '${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2)} '
                      '${isArabic ? 'جنيه' : 'EGP'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isArabic ? 'تأكيد المشتري' : 'Buyer'}: '
                      '${buyerConfirmed ? (isArabic ? 'تم' : 'Confirmed') : (isArabic ? 'منتظر' : 'Pending')}'
                      '  •  '
                      '${isArabic ? 'تأكيد البائع' : 'Seller'}: '
                      '${sellerConfirmed ? (isArabic ? 'تم' : 'Confirmed') : (isArabic ? 'منتظر' : 'Pending')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    if (buyerConfirmed && sellerConfirmed && isSeller)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _finalizeOrderSettlement,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            isArabic
                                ? 'إتمام البيع وتسجيل القطع كمباعة'
                                : 'Finalize sale and mark items sold',
                          ),
                        ),
                      )
                    else if (buyerConfirmed && sellerConfirmed && isBuyer)
                      Text(
                        isArabic
                            ? 'تم تأكيد الطرفين. ننتظر البائع لإتمام البيع.'
                            : 'Both confirmed. Waiting for the seller to finalize.',
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: alreadyConfirmed
                              ? null
                              : _confirmOrderSettlement,
                          icon: const Icon(Icons.handshake_outlined),
                          label: Text(
                            alreadyConfirmed
                                ? (isArabic
                                    ? 'تم تسجيل تأكيدك'
                                    : 'Your confirmation is recorded')
                                : (isArabic
                                    ? 'تأكيد تسوية الحساب'
                                    : 'Confirm order settlement'),
                          ),
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
                      IconButton(
                        tooltip: isArabic
                            ? 'إرفاق صورة أو فيديو'
                            : 'Attach photo or video',
                        onPressed: _isSending ? null : _pickAndSendMedia,
                        icon: const Icon(Icons.attach_file),
                      ),
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
                      if (_isRecording) ...[
                        IconButton(
                          tooltip: isArabic
                              ? 'إلغاء التسجيل'
                              : 'Cancel recording',
                          onPressed: _isSending ? null : _cancelVoiceRecording,
                          icon: const Icon(Icons.close, color: Colors.red),
                        ),
                        IconButton(
                          tooltip: isArabic
                              ? 'إيقاف وإرسال الصوت'
                              : 'Stop and send voice',
                          onPressed: _isSending
                              ? null
                              : _stopAndSendVoiceMessage,
                          icon: const Icon(
                            Icons.stop_circle,
                            color: Colors.red,
                          ),
                        ),
                      ] else
                        IconButton(
                          tooltip: isArabic
                              ? 'تسجيل رسالة صوتية'
                              : 'Record a voice message',
                          onPressed: _isSending ? null : _startVoiceRecording,
                          icon: const Icon(Icons.mic),
                        ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        mini: true,
                        onPressed: _isSending || _isRecording
                            ? null
                            : _sendMessage,
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

class _ChatAudioPlayer extends StatefulWidget {
  final String url;
  final bool isArabic;

  const _ChatAudioPlayer({required this.url, required this.isArabic});

  @override
  State<_ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<_ChatAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSubscription;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play(UrlSource(widget.url));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic
                ? 'تعذر تشغيل الرسالة الصوتية.'
                : 'Could not play the voice message.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_stateSubscription?.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _isPlaying
                ? (widget.isArabic ? 'إيقاف مؤقت' : 'Pause')
                : (widget.isArabic ? 'تشغيل الصوت' : 'Play voice message'),
            onPressed: _togglePlayback,
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
            iconSize: 34,
          ),
          Expanded(
            child: Text(
              widget.isArabic ? 'رسالة صوتية' : 'Voice message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatVideoPlayer extends StatefulWidget {
  final String url;

  const _ChatVideoPlayer({required this.url});

  @override
  State<_ChatVideoPlayer> createState() => _ChatVideoPlayerState();
}

class _ChatVideoPlayerState extends State<_ChatVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
        .initialize()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((Object _) {
          if (mounted) setState(() => _failed = true);
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const SizedBox(
        width: 230,
        height: 130,
        child: Center(child: Icon(Icons.error_outline)),
      );
    }
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        width: 230,
        height: 130,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ratio = _controller.value.aspectRatio > 0
        ? _controller.value.aspectRatio
        : 16 / 9;

    return SizedBox(
      width: 230,
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            IconButton.filled(
              onPressed: () {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
                setState(() {});
              },
              icon: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showFullChatImage(BuildContext context, String imageUrl) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(32),
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}
