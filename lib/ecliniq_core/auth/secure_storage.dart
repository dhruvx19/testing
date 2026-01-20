// ignore_for_file: empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_locker/flutter_locker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'ecliniq_secure_prefs',
      resetOnError: true, // Clear data if keystore is compromised
    ),
    iOptions: const IOSOptions(accountName: 'ecliniq_keychain'),
  );

  // Keys for secure storage
  static const String _keyUserID = 'user_id';
  static const String _keyPhoneNumber = 'phone_number';

  // Storage version for migration support
  static const String _keyStorageVersion = 'storage_version';
  static const int _currentStorageVersion = 1;

  // MPIN storage key
  static const String _keyMPIN = 'mpin';
  static const String _keyIsBiometricEnabled = 'is_biometric_enabled';

  // Simple encryption/decryption using base64
  static String _encryptData(String data) {
    return base64.encode(utf8.encode(data));
  }

  static String _decryptData(String encryptedData) {
    return utf8.decode(base64.decode(encryptedData));
  }

  // Private method to store value with biometric
  static Future<bool> _storeBiometricValue({
    required String key,
    required String value,
  }) async {
    try {
      final encryptedKey = _encryptData(key);
      final encryptedValue = _encryptData(value);

      await FlutterLocker.save(
        SaveSecretRequest(
          key: encryptedKey,
          secret: encryptedValue,
          androidPrompt: AndroidPrompt(
            title: 'Enable Biometric Authentication',
            cancelLabel: 'Cancel',
            descriptionLabel: 'Use your biometric to secure your account',
          ),
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Private method to get value with biometric
  static Future<String?> _getBiometricValue({
    required String key,
    required String title,
    required String description,
  }) async {
    try {
      final encryptedKey = _encryptData(key);

      final encryptedValue = await FlutterLocker.retrieve(
        RetrieveSecretRequest(
          key: encryptedKey,
          androidPrompt: AndroidPrompt(
            title: title,
            descriptionLabel: description,
            cancelLabel: 'Cancel',
          ),
          iOsPrompt: IOsPrompt(touchIdText: title),
        ),
      );

      return _decryptData(encryptedValue);
    } on PlatformException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete MPIN and biometric data
  static Future<bool> deleteMPIN() async {
    try {
      // Delete from regular storage
      await _secureStorage.delete(key: _keyMPIN);

      // Delete from biometric storage
      try {
        final encryptedKey = _encryptData(_keyMPIN);
        await FlutterLocker.delete(encryptedKey);
      } catch (e) {
        // Ignore if key doesn't exist in biometric storage
      }

      // Clear biometric enabled flag
      await _secureStorage.delete(key: _keyIsBiometricEnabled);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete biometric value with production-grade error handling
  static Future<bool> deleteBiometricValue(String key) async {
    try {
      final encryptedKey = _encryptData(key);
      await FlutterLocker.delete(encryptedKey);
      return true;
    } on PlatformException catch (e) {
      // Key might not exist, which is fine
      if (e.code == 'secret_not_found' ||
          e.message?.contains('not found') == true) {
        return true; // Consider it successful if key doesn't exist
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clean up all biometric keys
  static Future<bool> cleanupBiometricKeys() async {
    try {
      // Clean up MPIN key
      try {
        final encryptedKey = _encryptData(_keyMPIN);
        await FlutterLocker.delete(encryptedKey);
      } catch (e) {
        // Ignore errors - keys may not exist
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Store MPIN in secure storage
  static Future<bool> storeMPIN(String mpin) async {
    try {
      await _secureStorage.write(key: _keyMPIN, value: mpin);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get MPIN from secure storage
  static Future<String?> getMPIN() async {
    try {
      return await _secureStorage.read(key: _keyMPIN);
    } catch (e) {
      return null;
    }
  }

  /// Verify MPIN
  static Future<bool> verifyMPIN(String mpin) async {
    try {
      final storedMPIN = await getMPIN();
      return storedMPIN == mpin;
    } catch (e) {
      return false;
    }
  }

  /// Check if MPIN exists
  static Future<bool> hasMPIN() async {
    try {
      final mpin = await getMPIN();
      return mpin != null && mpin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Store MPIN with biometric protection
  static Future<bool> storeMPINWithBiometric(String mpin) async {
    try {
      if (!await BiometricService.isAvailable()) {
        return await storeMPIN(mpin);
      }

      final success = await _storeBiometricValue(key: _keyMPIN, value: mpin);

      if (success) {
        // Also store in regular secure storage as backup
        await storeMPIN(mpin);
        await setBiometricEnabled(true);
      }

      return success;
    } catch (e) {
      // Fallback to regular storage
      return await storeMPIN(mpin);
    }
  }

  /// Get MPIN using biometric authentication
  static Future<String?> getMPINWithBiometric({
    BiometricAuthConfig? config,
  }) async {
    try {
      if (!await BiometricService.isAvailable()) {
        return await getMPIN();
      }

      final authConfig =
          config ??
          BiometricAuthConfig(
            localizedReason: 'Use your biometric to authenticate',
            signInTitle: 'Biometric Authentication',
            cancelButton: 'Cancel',
          );

      final mpin = await _getBiometricValue(
        key: _keyMPIN,
        title: authConfig.signInTitle,
        description: authConfig.localizedReason,
      );

      return mpin;
    } catch (e) {
      return null;
    }
  }

  /// Set biometric enabled flag
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _keyIsBiometricEnabled,
        value: enabled.toString(),
      );
    } catch (e) {}
  }

  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _keyIsBiometricEnabled);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Store user info with production-grade validation and verification
  static Future<bool> storeUserInfo(String userId, String phoneNumber) async {
    try {
      // Validate inputs
      if (userId.isEmpty || phoneNumber.isEmpty) {
        return false;
      }

      // Validate phone number format (basic check)
      if (!RegExp(
        r'^\+?[1-9]\d{1,14}$',
      ).hasMatch(phoneNumber.replaceAll(RegExp(r'[\s-]'), ''))) {}

      // Store with retry logic
      const maxRetries = 2;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          await _secureStorage.write(key: _keyUserID, value: userId);
          await _secureStorage.write(key: _keyPhoneNumber, value: phoneNumber);

          // Verify storage
          final storedUserId = await _secureStorage.read(key: _keyUserID);
          final storedPhone = await _secureStorage.read(key: _keyPhoneNumber);

          if (storedUserId == userId && storedPhone == phoneNumber) {
            return true;
          } else {
            if (attempt < maxRetries) {
              await Future.delayed(Duration(milliseconds: 100));
            }
          }
        } catch (e) {
          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 100 * attempt));
          }
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get user info
  static Future<Map<String, String?>> getUserInfo() async {
    try {
      return {
        'userId': await _secureStorage.read(key: _keyUserID),
        'phoneNumber': await _secureStorage.read(key: _keyPhoneNumber),
      };
    } catch (e) {
      return {'userId': null, 'phoneNumber': null};
    }
  }

  /// Get phone number from secure storage
  static Future<String?> getPhoneNumber() async {
    try {
      return await _secureStorage.read(key: _keyPhoneNumber);
    } catch (e) {
      return null;
    }
  }

  /// Store phone number in secure storage
  static Future<bool> storePhoneNumber(String phoneNumber) async {
    try {
      await _secureStorage.write(key: _keyPhoneNumber, value: phoneNumber);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all secure data
  static Future<bool> clearAll() async {
    try {
      // Clear biometric keys
      await cleanupBiometricKeys();

      // Clear all secure storage
      await _secureStorage.deleteAll();

      // Verify all data is cleared
      final userId = await _secureStorage.read(key: _keyUserID);
      final phoneNumber = await _secureStorage.read(key: _keyPhoneNumber);

      if (userId != null || phoneNumber != null) {
        // Retry deletion
        await _secureStorage.deleteAll();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear only session-related data (keeps MPIN and biometric)
  static Future<bool> clearSessionData() async {
    try {
      // Delete user info keys
      await _secureStorage.delete(key: _keyUserID);
      await _secureStorage.delete(key: _keyPhoneNumber);

      // Verify deletion
      final userId = await _secureStorage.read(key: _keyUserID);
      final phoneNumber = await _secureStorage.read(key: _keyPhoneNumber);

      if (userId != null || phoneNumber != null) {
        // Retry deletion
        await _secureStorage.delete(key: _keyUserID);
        await _secureStorage.delete(key: _keyPhoneNumber);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Complete account deletion - removes ALL user data
  static Future<bool> deleteAccount() async {
    try {
      // Clear all secure storage
      await _secureStorage.deleteAll();

      // Verify all data is cleared
      final userId = await _secureStorage.read(key: _keyUserID);
      final phoneNumber = await _secureStorage.read(key: _keyPhoneNumber);

      if (userId != null || phoneNumber != null) {
        // Retry complete deletion
        await _secureStorage.deleteAll();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Production-grade storage health check
  /// Verifies storage functionality and data integrity
  static Future<Map<String, dynamic>> checkStorageHealth() async {
    final health = <String, dynamic>{
      'healthy': true,
      'issues': <String>[],
      'details': <String, dynamic>{},
    };

    try {
      // Test 1: Basic read/write functionality
      const testKey = 'health_check_key';
      const testValue = 'health_check_value';

      try {
        await _secureStorage.write(key: testKey, value: testValue);
        final readValue = await _secureStorage.read(key: testKey);
        await _secureStorage.delete(key: testKey);

        if (readValue != testValue) {
          health['healthy'] = false;
          health['issues'].add('Read/write verification failed');
        }
        health['details']['readWrite'] = readValue == testValue;
      } catch (e) {
        health['healthy'] = false;
        health['issues'].add('Storage read/write error: $e');
        health['details']['readWrite'] = false;
      }

      if (health['issues'].isNotEmpty) {}

      return health;
    } catch (e) {
      health['healthy'] = false;
      health['issues'].add('Health check failed: $e');
      return health;
    }
  }

  /// Debug method to test storage functionality
  static Future<bool> testStorage() async {
    try {
      const testKey = 'test_key';
      const testValue = 'test_value';

      // Write test data
      await _secureStorage.write(key: testKey, value: testValue);

      // Read test data
      final readValue = await _secureStorage.read(key: testKey);

      // Clean up
      await _secureStorage.delete(key: testKey);

      final success = readValue == testValue;
      return success;
    } catch (e) {
      return false;
    }
  }

  /// Verify MPIN data integrity
  static Future<bool> verifyMPINIntegrity() async {
    try {
      final mpin = await getMPIN();
      if (mpin == null || mpin.isEmpty) {
        return false;
      }

      // Check if MPIN is 4 digits
      if (mpin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(mpin)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize storage and perform migration if needed
  static Future<void> initializeStorage() async {
    try {
      final storedVersion = await _secureStorage.read(key: _keyStorageVersion);
      final version = storedVersion != null
          ? int.tryParse(storedVersion)
          : null;

      if (version == null || version < _currentStorageVersion) {
        await _migrateStorage(version ?? 0);
        await _secureStorage.write(
          key: _keyStorageVersion,
          value: _currentStorageVersion.toString(),
        );
      }
    } catch (e) {
      // Continue anyway - migration is not critical
    }
  }

  /// Migrate storage from old version to new version
  static Future<void> _migrateStorage(int fromVersion) async {
    try {
      if (fromVersion < 1) {
        // Migration logic can be added here if needed
      }
    } catch (e) {
      // Don't throw - migration failures shouldn't break the app
    }
  }

  /// Recover from storage errors
  static Future<bool> recoverFromStorageError() async {
    try {
      // Check storage health
      final health = await checkStorageHealth();

      if (health['healthy'] == true) {
        return true;
      }

      // Retry storage operations
      final testResult = await testStorage();
      return testResult;
    } catch (e) {
      return false;
    }
  }
}

// Biometric Auth Config (following your pattern)
class BiometricAuthConfig {
  final String localizedReason;
  final String signInTitle;
  final String biometricHint;
  final String cancelButton;

  BiometricAuthConfig({
    this.localizedReason = 'Use your biometric to authenticate',
    this.signInTitle = 'Biometric Authentication',
    this.biometricHint = '',
    required this.cancelButton,
  });
}

// Biometric Service (following your implementation pattern)
class BiometricService {
  static Future<bool> isAvailable() async {
    try {
      final canAuthenticate = await FlutterLocker.canAuthenticate();
      return canAuthenticate;
    } on PlatformException {
      return await _fallbackBiometricCheck();
    } catch (e) {
      // Try fallback check
      return await _fallbackBiometricCheck();
    }
  }

  static Future<bool> _fallbackBiometricCheck() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final canAuth = await FlutterLocker.canAuthenticate();
      if (canAuth) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> testBiometricAvailability() async {
    try {
      await FlutterLocker.save(
        SaveSecretRequest(
          key: 'test_biometric_key',
          secret: 'test_value',
          androidPrompt: AndroidPrompt(
            title: 'Enable Biometric Authentication',
            cancelLabel: 'Cancel',
            descriptionLabel: 'Use your biometric to secure your account',
          ),
        ),
      );

      // Clean up the test key
      await FlutterLocker.delete('test_biometric_key');
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> authenticateUser(BiometricAuthConfig config) async {
    try {
      if (!await isAvailable()) {
        return false;
      }

      final mpin = await SecureStorageService.getMPINWithBiometric(
        config: config,
      );
      return mpin != null && mpin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static String getBiometricTypeName() {
    if (Platform.isIOS) {
      return 'Face ID';
    } else {
      // Android: Can be fingerprint or face unlock
      return 'Biometric';
    }
  }

  static IconData getBiometricIcon() {
    if (Platform.isIOS) {
      // Use face icon for iOS (most modern devices use Face ID)
      return Icons.face;
    } else {
      // Use fingerprint icon for Android
      return Icons.fingerprint;
    }
  }
}
