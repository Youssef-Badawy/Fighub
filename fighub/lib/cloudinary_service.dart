import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'jcfyuify';
  static const String _uploadPreset = 'fighub_products';

  static const String _workerUrl =
      'https://fighub.youssef-khaled-badawy.workers.dev';

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

    final response = await http.post(
      Uri.parse(_workerUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Cloudinary cleanup failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<String> uploadImage(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();

    if (imageBytes.isEmpty) {
      throw StateError('Image file is empty.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = _uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageFile.name,
      ),
    );

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Cloudinary upload failed: '
        '${response.statusCode} $responseBody',
      );
    }

    final decodedResponse = jsonDecode(responseBody) as Map<String, dynamic>;

    final secureUrl = decodedResponse['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError('Cloudinary did not return an image URL.');
    }

    return secureUrl;
  }

  Future<String> uploadAudio(String audioPath) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
    );
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        audioPath,
        filename: 'voice_message.m4a',
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Cloudinary audio upload failed: ${response.statusCode} $body',
      );
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final url = decoded['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Cloudinary did not return an audio URL.');
    }
    return url;
  }

  Future<String> uploadVideo(XFile videoFile) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
    );
    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        videoFile.path,
        filename: videoFile.name,
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Cloudinary video upload failed: ${response.statusCode} $body',
      );
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final url = decoded['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Cloudinary did not return a video URL.');
    }
    return url;
  }
}
