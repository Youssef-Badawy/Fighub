import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
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
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
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
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
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
              Container(
                height: 142,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  image: coverUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: FilledButton.tonalIcon(
                  onPressed: _isUploadingCover ? null : _changeCoverPhoto,
                  icon: _isUploadingCover
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_back_outlined),
                  label: const Text('تغيير الغلاف'),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 14,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _changeProfilePhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildAvatar(colors.primary, colors.onPrimary),
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: colors.primary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: colors.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bioController,
            maxLength: 240,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              labelText: 'نبذة عنك (Bio)',
              hintText: 'اكتب نبذة قصيرة عنك واهتماماتك...',
              border: OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _isSavingBio ? null : _saveBio,
              icon: _isSavingBio
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('حفظ النبذة'),
            ),
          ),
        ],
      ),
    );
  }
}