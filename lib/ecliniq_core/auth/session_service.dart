import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/auth/jwt_decoder.dart';

class SessionService {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyIsOnboardingComplete = 'is_onboarding_complete';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyCurrentFlowState = 'current_flow_state';

  static Future<bool> storeTokens({
    required String authToken,
    String? refreshToken,
    int? expiresInSeconds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_keyAuthToken, authToken);
      if (refreshToken != null) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      }

      DateTime expiryTime;

      if (expiresInSeconds != null) {
        expiryTime = DateTime.now().add(Duration(seconds: expiresInSeconds));
      } else {
        final expirationTime = JwtDecoder.getExpirationTime(authToken);
        if (expirationTime != null) {
          expiryTime = expirationTime;
        } else {
          expiryTime = DateTime.now().add(const Duration(hours: 24));
        }
      }

      await prefs.setString(_keyTokenExpiry, expiryTime.toIso8601String());

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAuthToken);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_keyTokenExpiry);

      if (expiryString == null) {
        return true;
      }

      final expiryTime = DateTime.parse(expiryString);
      
      // Proactively return true if we're within 5 minutes of real expiry
      final bufferTime = expiryTime.subtract(const Duration(minutes: 5));
      return DateTime.now().isAfter(bufferTime);
    } catch (e) {
      return true;
    }
  }

  static Future<bool> hasValidSession() async {
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final isExpired = await isTokenExpired();
      if (isExpired) {
        final expiry = await getTokenExpiry();
        if (expiry != null) {}
      } else {}

      return !isExpired;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setOnboardingComplete(bool complete) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsOnboardingComplete, complete);
    } catch (e) {}
  }

  static Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsOnboardingComplete) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirst = prefs.getBool(_keyIsFirstLaunch) ?? true;
      if (isFirst) {
        await prefs.setBool(_keyIsFirstLaunch, false);
      }
      return isFirst;
    } catch (e) {
      return true;
    }
  }

  static Future<bool> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final tokenRemoved = await prefs.remove(_keyAuthToken);
      final refreshTokenRemoved = await prefs.remove(_keyRefreshToken);
      final expiryRemoved = await prefs.remove(_keyTokenExpiry);

      final token = prefs.getString(_keyAuthToken);
      final refreshToken = prefs.getString(_keyRefreshToken);
      final expiry = prefs.getString(_keyTokenExpiry);

      if (token != null || refreshToken != null || expiry != null) {
        await prefs.remove(_keyAuthToken);
        await prefs.remove(_keyRefreshToken);
        await prefs.remove(_keyTokenExpiry);
      }

      final secureStorageCleared =
          await SecureStorageService.clearSessionData();

      if (secureStorageCleared &&
          tokenRemoved &&
          refreshTokenRemoved &&
          expiryRemoved) {
        return true;
      } else {
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<DateTime?> getTokenExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_keyTokenExpiry);
      if (expiryString == null) return null;
      return DateTime.parse(expiryString);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveFlowState(String flowState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentFlowState, flowState);
    } catch (e) {}
  }

  static Future<String?> getFlowState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyCurrentFlowState);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearFlowState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCurrentFlowState);
    } catch (e) {}
  }
}
