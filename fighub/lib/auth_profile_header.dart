import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fighub_image_picker.dart';

import 'auth_manager.dart';

class AuthProfileHeader extends StatefulWidget {
  final AuthManager authManager;

  const AuthProfileHeader({
    super.key,
    required this.authManager,
  });

  @override
  State<AuthProfileHeader> createState() => _AuthProfileHeaderState();
}

class _AuthProfileHeaderState extends State<AuthProfileHeader> {
  late final TextEditingController _bioController;
  bool _isUploadingPhoto = false;
  bool _isUploadingCover = false;
  bool _isSavingBio = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.authManager.bio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _changeProfilePhoto() async {
    if (_isUploadingPhoto) return;
    try {
      final image = await FigHubImagePicker.pickAndCrop(
        context,
        imageQuality: 85,
        maxWidth: 900,
        maxHeight: 900,
      );
      if (!mounted || image == null) return;
      setState(() => _isUploadingPhoto = true);
      await widget.authManager.updateProfilePhoto(image);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث صورة البروفايل: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _changeCoverPhoto() async {
    if (_isUploadingCover) return;
    try {
      final image = await FigHubImagePicker.pickAndCrop(
        context,
        imageQuality: 82,
        maxWidth: 1800,
        maxHeight: 1000,
      );
      if (!mounted || image == null) return;
      setState(() => _isUploadingCover = true);
      await widget.authManager.updateCoverPhoto(image);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تحديث صورة الغلاف: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _editBio() async {
    _bioController.text = widget.authManager.bio;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل النبذة الشخصية'),
        content: TextField(
          controller: _bioController,
          maxLength: 240,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'اكتب نبذة قصيرة عنك واهتماماتك...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (shouldSave == true && mounted) await _saveBio();
  }

  Future<void> _saveBio() async {
    if (_isSavingBio) return;
    setState(() => _isSavingBio = true);
    try {
      await widget.authManager.updateBio(_bioController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ النبذة الشخصية')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر حفظ النبذة: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingBio = false);
    }
  }

  Widget _buildAvatar(Color primary, Color onPrimary) {
    final photoUrl = widget.authManager.photoUrl;
    if (_isUploadingPhoto) {
      return CircleAvatar(
        radius: 38,
        backgroundColor: primary,
        child: const CircularProgressIndicator(strokeWidth: 3),
      );
    }
    return CircleAvatar(
      radius: 38,
      backgroundColor: primary,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      onBackgroundImageError: photoUrl.isNotEmpty ? (_, _) {} : null,
      child: photoUrl.isEmpty
          ? Icon(Icons.person, size: 38, color: onPrimary)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = widget.authManager.name.isEmpty
        ? 'مستخدم FigHub'
        : widget.authManager.name;
    final coverUrl = widget.authManager.coverUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 142,
                  width: double.infinity,
                  child: coverUrl.isEmpty
                      ? ColoredBox(color: colors.primaryContainer)
                      : Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                            color: colors.primaryContainer,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: colors.surface.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: PopupMenuButton<String>(
                    tooltip: 'إعدادات الملف الشخصي',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'cover':
                          _changeCoverPhoto();
                          break;
                        case 'photo':
                          _changeProfilePhoto();
                          break;
                        case 'bio':
                          _editBio();
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'cover',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.photo_camera_back_outlined),
                          title: Text('تغيير صورة الغلاف'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'photo',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.account_circle_outlined),
                          title: Text('تغيير الصورة الشخصية'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'bio',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.edit_note),
                          title: Text('تعديل النبذة'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 14,
                child: _buildAvatar(colors.primary, colors.onPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (FirebaseAuth.instance.currentUser != null)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('seller_profiles')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() ?? {};
                    final isAdmin = data['isAdmin'] == true;
                    final expiresAt = data['verifiedUntil'];
                    final isPaidVerified = data['isVerified'] == true &&
                        expiresAt is Timestamp &&
                        DateTime.now().isBefore(expiresAt.toDate());
                    if (!isAdmin && !isPaidVerified) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsetsDirectional.only(start: 6),
                      child: Icon(
                        Icons.verified,
                        color: Color(0xFF1D9BF0),
                        size: 22,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.authManager.bio.isEmpty
                ? 'أضف نبذة قصيرة عنك من قائمة الإعدادات'
                : widget.authManager.bio,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}