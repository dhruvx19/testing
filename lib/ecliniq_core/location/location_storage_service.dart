import 'package:shared_preferences/shared_preferences.dart';

/// Service to store and retrieve user location persistently
class LocationStorageService {
  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';
  static const String _keyLocationName = 'user_location_name';
  static const String _keyLocationTimestamp = 'user_location_timestamp';

  /// Store user location
  static Future<bool> storeLocation({
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyLatitude, latitude);
      await prefs.setDouble(_keyLongitude, longitude);
      if (locationName != null) {
        await prefs.setString(_keyLocationName, locationName);
      }
      await prefs.setString(_keyLocationTimestamp, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get stored user location
  static Future<Map<String, dynamic>?> getStoredLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble(_keyLatitude);
      final longitude = prefs.getDouble(_keyLongitude);
      final locationName = prefs.getString(_keyLocationName);
      final timestamp = prefs.getString(_keyLocationTimestamp);

      if (latitude != null && longitude != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
          'locationName': locationName,
          'timestamp': timestamp,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear stored location
  static Future<void> clearStoredLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLatitude);
      await prefs.remove(_keyLongitude);
      await prefs.remove(_keyLocationName);
      await prefs.remove(_keyLocationTimestamp);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Check if location is stored and not too old (optional: within 24 hours)
  static Future<bool> hasValidStoredLocation({Duration maxAge = const Duration(hours: 24)}) async {
    try {
      final location = await getStoredLocation();
      if (location == null) return false;

      final timestamp = location['timestamp'] as String?;
      if (timestamp == null) return true; // If no timestamp, assume valid

      final storedTime = DateTime.parse(timestamp);
      final age = DateTime.now().difference(storedTime);
      return age < maxAge;
    } catch (e) {
      return false;
    }
  }
}

