import 'dart:convert';

/// Utility to decode JWT tokens and extract expiration time
class JwtDecoder {
  static int? getExpirationTimestamp(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed
      final normalizedPayload = _normalizeBase64(payload);
      
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final payloadMap = jsonDecode(decodedString) as Map<String, dynamic>;
      
      // Extract expiration (exp) claim
      final exp = payloadMap['exp'];
      if (exp is int) {
        return exp;
      }
      
      return null;
    } catch (e) {
      print('Error decoding JWT token: $e');
      return null;
    }
  }

  /// Get expiration time as DateTime
  static DateTime? getExpirationTime(String token) {
    final timestamp = getExpirationTimestamp(token);
    if (timestamp == null) {
      return null;
    }
    
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  /// Calculate seconds until expiration
  /// Returns null if expiration cannot be determined
  static int? getSecondsUntilExpiration(String token) {
    final expirationTime = getExpirationTime(token);
    if (expirationTime == null) {
      return null;
    }
    
    final now = DateTime.now();
    final difference = expirationTime.difference(now);
    
    return difference.inSeconds;
  }

  /// Normalize base64 string by adding padding if needed
  static String _normalizeBase64(String base64) {
    final remainder = base64.length % 4;
    if (remainder == 0) {
      return base64;
    }
    
    return base64 + '=' * (4 - remainder);
  }

  /// Decode JWT payload and return as Map
  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalizedPayload = _normalizeBase64(payload);
      
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final payloadMap = jsonDecode(decodedString) as Map<String, dynamic>;
      
      return payloadMap;
    } catch (e) {
      print('Error decoding JWT payload: $e');
      return null;
    }
  }
}

