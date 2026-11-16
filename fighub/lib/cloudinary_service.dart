import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'jcfyuify';
  static const String _uploadPreset = 'fighub_products';

  static const String _workerUrl =
      'https://fighub.youssef-khaled-badawy.workers.dev';

  static const int _maxImageBytes = 25 * 1024 * 1024;
  static const int _maxVideoBytes = 100 * 1024 * 1024;
  static const int _maxAudioBytes = 25 * 1024 * 1024;
  static const Duration _uploadTimeout = Duration(minutes: 3);

  Future<void> deleteProductAssets({
    required String productId,
    required List<String> assetUrls,
  }) async {
    final urls = _cloudinaryUrls(assetUrls);
    if (urls.isEmpty) return;
    await _deleteAssets({
      'action': 'deleteCloudinaryAssets',
      'ownerType': 'product',
      'ownerId': productId,
      'assetUrls': urls,
    });
  }

  Future<void> deleteOfferAssets({
    required String offerId,
    required List<Map<String, dynamic>> items,
  }) async {
    final cleanedItems = items
        .map((item) => {
              'itemId': item['itemId'],
              'assetUrls': _cloudinaryUrls(
                (item['assetUrls'] as List? ?? []).whereType<String>().toList(),
              ),
            })
        .where((item) => (item['assetUrls'] as List).isNotEmpty)
        .toList();
    if (cleanedItems.isEmpty) return;
    await _deleteAssets({
      'action': 'deleteCloudinaryAssets',
      'ownerType': 'offer',
      'ownerId': offerId,
      'items': cleanedItems,
    });
  }

  List<String> _cloudinaryUrls(List<String> values) {
    return values
        .where((value) => value.startsWith('https://res.cloudinary.com/'))
        .toSet()
        .toList();
  }

  Future<void> _deleteAssets(Map<String, dynamic> body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('User must be signed in.');
    final idToken = await user.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Could not get Firebase ID token.');
    }

    final response = await http
        .post(
          Uri.parse(_workerUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Cloudinary cleanup failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  String _errorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message']?.toString();
          if (message != null && message.isNotEmpty) return message;
        }
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {
      // Preserve the original response when Cloudinary returns non-JSON.
    }
    return responseBody.length > 500
        ? responseBody.substring(0, 500)
        : responseBody;
  }

  Future<String> _uploadFile({
    required String path,
    required String filename,
    required String resourceType,
    required String mediaLabel,
    required int maxBytes,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('ملف $mediaLabel غير موجود على الجهاز.');
    }

    final fileLength = await file.length();
    if (fileLength <= 0) {
      throw StateError('ملف $mediaLabel فارغ.');
    }
    if (fileLength > maxBytes) {
      final maxMb = (maxBytes / (1024 * 1024)).round();
      throw StateError('حجم $mediaLabel أكبر من الحد المسموح ($maxMb MB).');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          path,
          filename: filename,
        ),
      );

    try {
      final streamedResponse =
          await request.send().timeout(_uploadTimeout);
      final responseBody = await streamedResponse.stream
          .bytesToString()
          .timeout(const Duration(seconds: 30));

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw StateError(
          'Cloudinary $mediaLabel upload failed '
          '(${streamedResponse.statusCode}): ${_errorMessage(responseBody)}',
        );
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Cloudinary returned an invalid response.');
      }
      final secureUrl = decoded['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw StateError('Cloudinary did not return a secure URL.');
      }
      return secureUrl;
    } on TimeoutException {
      throw StateError(
        'انتهت مهلة رفع $mediaLabel. تحقق من الاتصال وحاول مرة أخرى.',
      );
    } on SocketException {
      throw StateError('تعذر الاتصال بخدمة رفع $mediaLabel.');
    }
  }

  Future<String> uploadImage(XFile imageFile) {
    return _uploadFile(
      path: imageFile.path,
      filename: imageFile.name,
      resourceType: 'image',
      mediaLabel: 'الصورة',
      maxBytes: _maxImageBytes,
    );
  }

  Future<String> uploadAudio(String audioPath) {
    return _uploadFile(
      path: audioPath,
      filename: 'voice_message.m4a',
      resourceType: 'video',
      mediaLabel: 'الرسالة الصوتية',
      maxBytes: _maxAudioBytes,
    );
  }

  Future<String> uploadVideo(XFile videoFile) {
    return _uploadFile(
      path: videoFile.path,
      filename: videoFile.name,
      resourceType: 'video',
      mediaLabel: 'الفيديو',
      maxBytes: _maxVideoBytes,
    );
  }
}
