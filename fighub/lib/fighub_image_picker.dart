import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Shared image selection flow used before every FigHub image upload.
/// Users can crop/rotate an image or keep the original unchanged.
class FigHubImagePicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickAndCrop(
    BuildContext context, {
    ImageSource source = ImageSource.gallery,
    int imageQuality = 90,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final selected = await _picker.pickImage(
      source: source,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (selected == null || !context.mounted) return null;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_rotate),
              title: const Text('تعديل وقص الصورة'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('استخدام الصورة كما هي'),
              onTap: () => Navigator.pop(sheetContext, 'original'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'original') return selected;
    if (choice != 'edit') return null;

    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!kIsWeb && !isMobile) return selected;

    final theme = Theme.of(context);
    final cropped = await ImageCropper().cropImage(
      sourcePath: selected.path,
      maxWidth: 2400,
      maxHeight: 2400,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 88,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'تعديل الصورة',
          toolbarColor: theme.colorScheme.surface,
          toolbarWidgetColor: theme.colorScheme.onSurface,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'تعديل الصورة',
          aspectRatioPresets: const [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        if (kIsWeb) WebUiSettings(context: context),
      ],
    );

    if (cropped == null) return null;
    return XFile(cropped.path);
  }

  static Future<List<XFile>> pickAndCropMultiple(
    BuildContext context, {
    int imageQuality = 90,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final selected = await _picker.pickMultiImage(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    if (!context.mounted || selected.isEmpty) return [];

    final result = <XFile>[];
    for (final image in selected) {
      if (!context.mounted) break;
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.crop_rotate),
                title: const Text('تعديل وقص الصورة'),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('استخدام الصورة كما هي'),
                onTap: () => Navigator.pop(sheetContext, 'original'),
              ),
            ],
          ),
        ),
      );
      if (choice == 'original') {
        result.add(image);
        continue;
      }
      if (choice != 'edit') continue;

      final isMobile = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      if (!kIsWeb && !isMobile) {
        result.add(image);
        continue;
      }

      final theme = Theme.of(context);
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        maxWidth: 2400,
        maxHeight: 2400,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 88,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'تعديل الصورة',
            toolbarColor: theme.colorScheme.surface,
            toolbarWidgetColor: theme.colorScheme.onSurface,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'تعديل الصورة',
            aspectRatioPresets: const [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          if (kIsWeb) WebUiSettings(context: context),
        ],
      );
      if (cropped != null) result.add(XFile(cropped.path));
    }
    return result;
  }
}
