

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
      resetOnError: true, 
    ),
    iOptions: const IOSOptions(accountName: 'ecliniq_keychain'),
  );

  
  static const String _keyUserID = 'user_id';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyUserName = 'user_name';
  static const String _keyIsExistingUser = 'is_existing_user';

  
  static const String _keyStorageVersion = 'storage_version';
  static const int _currentStorageVersion = 1;

  
  static const String _keyMPIN = 'mpin';
  static const String _keyIsBiometricEnabled = 'is_biometric_enabled';

  
  static String _encryptData(String data) {
    return base64.encode(utf8.encode(data));
  }

  static String _decryptData(String encryptedData) {
    return utf8.decode(base64.decode(encryptedData));
  }

  
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

  
  static Future<bool> deleteMPIN() async {
    try {
      
      await _secureStorage.delete(key: _keyMPIN);

      
      try {
        final encryptedKey = _encryptData(_keyMPIN);
        await FlutterLocker.delete(encryptedKey);
      } catch (e) {
        
      }

      
      await _secureStorage.delete(key: _keyIsBiometricEnabled);

      return true;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> deleteBiometricValue(String key) async {
    try {
      final encryptedKey = _encryptData(key);
      await FlutterLocker.delete(encryptedKey);
      return true;
    } on PlatformException catch (e) {
      
      if (e.code == 'secret_not_found' ||
          e.message?.contains('not found') == true) {
        return true; 
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> cleanupBiometricKeys() async {
    try {
      
      try {
        final encryptedKey = _encryptData(_keyMPIN);
        await FlutterLocker.delete(encryptedKey);
      } catch (e) {
        
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> storeMPIN(String mpin) async {
    try {
      await _secureStorage.write(key: _keyMPIN, value: mpin);
      return true;
    } catch (e) {
      return false;
    }
  }

  
  static Future<String?> getMPIN() async {
    try {
      return await _secureStorage.read(key: _keyMPIN);
    } catch (e) {
      return null;
    }
  }

  
  static Future<bool> verifyMPIN(String mpin) async {
    try {
      final storedMPIN = await getMPIN();
      return storedMPIN == mpin;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> hasMPIN() async {
    try {
      final mpin = await getMPIN();
      return mpin != null && mpin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> storeMPINWithBiometric(String mpin) async {
    try {
      if (!await BiometricService.isAvailable()) {
        return await storeMPIN(mpin);
      }

      final success = await _storeBiometricValue(key: _keyMPIN, value: mpin);

      if (success) {
        
        await storeMPIN(mpin);
        await setBiometricEnabled(true);
      }

      return success;
    } catch (e) {
      
      return await storeMPIN(mpin);
    }
  }

  
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

  
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _keyIsBiometricEnabled,
        value: enabled.toString(),
      );
    } catch (e) {}
  }

  
  static Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _keyIsBiometricEnabled);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  
  static Future<void> setExistingUser(bool value) async {
    try {
      await _secureStorage.write(
        key: _keyIsExistingUser,
        value: value.toString(),
      );
    } catch (e) {}
  }

  
  static Future<bool> isExistingUser() async {
    try {
      final value = await _secureStorage.read(key: _keyIsExistingUser);
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> storeUserInfo(String userId, String phoneNumber) async {
    try {
      
      if (userId.isEmpty || phoneNumber.isEmpty) {
        return false;
      }

      
      if (!RegExp(
        r'^\+?[1-9]\d{1,14}$',
      ).hasMatch(phoneNumber.replaceAll(RegExp(r'[\s-]'), ''))) {}

      
      const maxRetries = 2;
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          await _secureStorage.write(key: _keyUserID, value: userId);
          await _secureStorage.write(key: _keyPhoneNumber, value: phoneNumber);

          
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

  
  static Future<String?> getPhoneNumber() async {
    try {
      return await _secureStorage.read(key: _keyPhoneNumber);
    } catch (e) {
      return null;
    }
  }

  
  static Future<bool> storePhoneNumber(String phoneNumber) async {
    try {
      await _secureStorage.write(key: _keyPhoneNumber, value: phoneNumber);
      return true;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> storeUserName(String userName) async {
    try {
      await _secureStorage.write(key: _keyUserName, value: userName);
      return true;
    } catch (e) {
      return false;
    }
  }

  
  static Future<String?> getUserName() async {
    try {
      return await _secureStorage.read(key: _keyUserName);
    } catch (e) {
      return null;
    }
  }

  
  static Future<bool> clearAll() async {
    try {
      
      await cleanupBiometricKeys();

      
      await _secureStorage.deleteAll();

      
      final userId = await _secureStorage.read(key: _keyUserID);
      final phoneNumber = await _secureStorage.read(key: _keyPhoneNumber);

      if (userId != null || phoneNumber != null) {
        
        await _secureStorage.deleteAll();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> clearSessionData() async {
    try {
      
      await _secureStorage.delete(key: _keyUserID);
      await _secureStorage.delete(key: _keyPhoneNumber);

      
      final userId = await _secureStorage.read(key: _keyUserID);
      final phoneNumber = await _secureStorage.read(key: _keyPhoneNumber);

      if (userId != null || phoneNumber != null) {
        
        await _secureStorage.delete(key: _keyUserID);
        await _secureStorage.delete(key: _keyPhoneNumber);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> deleteAccount() async {
    try {
      
      await _secureStorage.deleteAll();

      
      final userId = await _secureStorage.read(key: _keyUserID);
      final phoneNumber = await _secureStorage.read(key: _keyPhoneNumber);

      if (userId != null || phoneNumber != null) {
        
        await _secureStorage.deleteAll();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  
  
  static Future<Map<String, dynamic>> checkStorageHealth() async {
    final health = <String, dynamic>{
      'healthy': true,
      'issues': <String>[],
      'details': <String, dynamic>{},
    };

    try {
      
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

  
  static Future<bool> testStorage() async {
    try {
      const testKey = 'test_key';
      const testValue = 'test_value';

      
      await _secureStorage.write(key: testKey, value: testValue);

      
      final readValue = await _secureStorage.read(key: testKey);

      
      await _secureStorage.delete(key: testKey);

      final success = readValue == testValue;
      return success;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> verifyMPINIntegrity() async {
    try {
      final mpin = await getMPIN();
      if (mpin == null || mpin.isEmpty) {
        return false;
      }

      
      if (mpin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(mpin)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  
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
      
    }
  }

  
  static Future<void> _migrateStorage(int fromVersion) async {
    try {
      if (fromVersion < 1) {
        
      }
    } catch (e) {
      
    }
  }

  
  static Future<bool> recoverFromStorageError() async {
    try {
      
      final health = await checkStorageHealth();

      if (health['healthy'] == true) {
        return true;
      }

      
      final testResult = await testStorage();
      return testResult;
    } catch (e) {
      return false;
    }
  }
}


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


class BiometricService {
  static Future<bool> isAvailable() async {
    try {
      final canAuthenticate = await FlutterLocker.canAuthenticate();
      return canAuthenticate;
    } on PlatformException {
      return await _fallbackBiometricCheck();
    } catch (e) {
      
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
      
      return 'Biometric';
    }
  }

  static IconData getBiometricIcon() {
    if (Platform.isIOS) {
      
      return Icons.face;
    } else {
      
      return Icons.fingerprint;
    }
  }
}
