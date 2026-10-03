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
  State<AuthProfileHeader> createState() =>
      _AuthProfileHeaderState();
}

class _AuthProfileHeaderState
    extends State<AuthProfileHeader> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingPhoto = false;

  Future<void> _changeProfilePhoto() async {
    if (_isUploadingPhoto) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _isUploadingPhoto = true;
      });

      await widget.authManager.updateProfilePhoto(image);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تحديث صورة البروفايل بنجاح',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'حدث خطأ أثناء تحديث صورة البروفايل:\n$error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Widget _buildProfilePhoto(
    BuildContext context,
    Color primaryColor,
    Color iconColor,
  ) {
    final photoUrl = widget.authManager.photoUrl;

    if (_isUploadingPhoto) {
      return CircleAvatar(
        radius: 34,
        backgroundColor: primaryColor,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 34,
        backgroundColor: primaryColor,
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, _) {},
      );
    }

    return CircleAvatar(
      radius: 34,
      backgroundColor: primaryColor,
      child: Icon(
        Icons.person,
        size: 36,
        color: iconColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final name = widget.authManager.name.isEmpty
        ? 'مستخدم FigHub'
        : widget.authManager.name;

    final email = widget.authManager.email.isEmpty
        ? 'لا يوجد بريد إلكتروني'
        : widget.authManager.email;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploadingPhoto
                ? null
                : _changeProfilePhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildProfilePhoto(
                  context,
                  colors.primary,
                  colors.onPrimary,
                ),
                if (!_isUploadingPhoto)
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.primaryContainer,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: colors.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                if (widget.authManager.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.authManager.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'اضغط على الصورة لتغييرها',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer
                        .withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}