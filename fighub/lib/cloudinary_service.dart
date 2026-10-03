import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = 'jcfyuify';
  static const String _uploadPreset = 'fighub_products';

  Future<String> uploadImage(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();

    if (imageBytes.isEmpty) {
      throw StateError('Image file is empty.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['upload_preset'] = _uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageFile.name,
      ),
    );

    final response = await request.send();

    final responseBody =
        await response.stream.bytesToString();

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw StateError(
        'Cloudinary upload failed: '
        '${response.statusCode} $responseBody',
      );
    }

    final decodedResponse =
        jsonDecode(responseBody) as Map<String, dynamic>;

    final secureUrl =
        decodedResponse['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw StateError(
        'Cloudinary did not return an image URL.',
      );
    }

    return secureUrl;
  }
}