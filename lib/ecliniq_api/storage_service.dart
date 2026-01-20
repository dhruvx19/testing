import 'dart:convert';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

/// Storage service for handling storage-related operations
/// @description Provides methods to interact with storage API endpoints
class StorageService {
  /// Get public URL for a storage key
  /// @description Fetches the public URL for a storage key. If the key starts with "public/",
  /// it calls the API to get the public URL. Otherwise, returns null or the original key.
  /// @param key - Storage key (e.g., "public/patients/profiles/...")
  /// @returns Future<String?> - Public URL if successful, null otherwise
  /// @example
  /// ```dart
  /// final storageService = StorageService();
  /// final url = await storageService.getPublicUrl('public/patients/profiles/...');
  /// ```
  Future<String?> getPublicUrl(String? key) async {
    if (key == null || key.isEmpty) {
      return null;
    }

    // If key doesn't start with "public/", return null or handle as needed
    if (!key.startsWith('public/')) {
      return null;
    }

    try {
      final url = Uri.parse('${Endpoints.storagePublicUrl}?key=${Uri.encodeComponent(key)}');

      final response = await http.get(
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
      // Return null on error to allow fallback handling
      return null;
    }
  }

  /// Get image URL with fallback
  /// @description Gets the public URL for a storage key if it starts with "public/",
  /// otherwise returns the key as-is (assuming it's already a full URL)
  /// @param imageKey - Image key or URL
  /// @param fallbackUrl - Optional fallback URL if image key is null or empty
  /// @returns Future<String> - Public URL, original key, or fallback URL
  /// @example
  /// ```dart
  /// final storageService = StorageService();
  /// final url = await storageService.getImageUrl(
  ///   'public/patients/profiles/...',
  ///   fallbackUrl: 'https://default-image.com/placeholder.jpg'
  /// );
  /// ```
  Future<String> getImageUrl(
    String? imageKey, {
    String? fallbackUrl,
  }) async {
    if (imageKey == null || imageKey.isEmpty) {
      return fallbackUrl ??
          'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
    }

    // If already a full URL, return as-is
    if (imageKey.startsWith('http://') || imageKey.startsWith('https://')) {
      return imageKey;
    }

    // If starts with "public/", get public URL from API
    if (imageKey.startsWith('public/')) {
      final publicUrl = await getPublicUrl(imageKey);
      if (publicUrl != null && publicUrl.isNotEmpty) {
        return publicUrl;
      }
    }

    // Fallback to original key or fallback URL
    return fallbackUrl ??
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
  }
}



