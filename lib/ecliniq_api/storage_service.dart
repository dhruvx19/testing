import 'dart:convert';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class StorageService {
  Future<String?> getPublicUrl(String? key) async {
    if (key == null || key.isEmpty) {
      return null;
    }

    if (!key.startsWith('public/')) {
      return null;
    }

    try {
      final url = Uri.parse('${Endpoints.storagePublicUrl}?key=${Uri.encodeComponent(key)}');

      final response = await EcliniqHttpClient.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return responseData['data']['publicUrl'] as String?;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String> getImageUrl(
    String? imageKey, {
    String? fallbackUrl,
  }) async {
    if (imageKey == null || imageKey.isEmpty) {
      return fallbackUrl ??
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
    }

    if (imageKey.startsWith('http://') || imageKey.startsWith('https://')) {
      return imageKey;
    }

    if (imageKey.startsWith('public/')) {
      final publicUrl = await getPublicUrl(imageKey);
      if (publicUrl != null && publicUrl.isNotEmpty) {
        return publicUrl;
      }
    }

    return fallbackUrl ??
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
  }
}
