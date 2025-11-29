import 'dart:io';
import 'dart:typed_data';
import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_api/models/upload.dart';
import 'package:ecliniq/ecliniq_api/src/upload_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/auth/jwt_decoder.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UploadService _uploadService = UploadService();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isSavingDetails = false;
  String? _errorMessage;
  String? _challengeId;
  String? _phoneNumber;
  String? _authToken;
  String? _userId;
  String? _profilePhotoKey;
  bool _isNewUser = false;

  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  bool get isSavingDetails => _isSavingDetails;
  String? get errorMessage => _errorMessage;
  String? get challengeId => _challengeId;
  String? get phoneNumber => _phoneNumber;
  String? get authToken => _authToken;
  String? get userId => _userId;
  String? get profilePhotoKey => _profilePhotoKey;
  bool get isAuthenticated => _authToken != null;
  bool get isNewUser => _isNewUser;

  /// Initialize AuthProvider - production-grade initialization
  /// Performs storage health check and migration if needed
  Future<void> initialize() async {
    try {
      // Initialize secure storage (migration, health check)
      await SecureStorageService.initializeStorage();

      // Load saved token
      await _loadSavedToken();

      // Check token expiration
      final isExpired = await SessionService.isTokenExpired();
      if (isExpired && _authToken != null) {
        // Token expired, clear session
        await clearSession();
      }

      //   print('⚠️ Storage health issues detected: ${health['issues']}');
      // }
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<bool> loginOrRegisterUser(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.loginOrRegisterUser(phone);
      _isLoading = false;

      if (result['success']) {
        _challengeId = result['challengeId'];
        _phoneNumber = phone;
        _userId = result['userId'];
        _isNewUser = result['isNewUser'] ?? false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    if (_challengeId == null || _phoneNumber == null) {
      _errorMessage = 'Session expired. Please try again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOTP(
        _challengeId!,
        _phoneNumber!,
        otp,
      );
      _isLoading = false;

      if (result.success) {
        if (result.data != null) {
          try {
            // Extract data from response structure: { success, message, data: { token, userStatus, redirectTo } }
            final responseData = result.data!;
            final data = responseData['data'];

            if (data != null && data['token'] != null) {
              _authToken = data['token'];

              // Extract userStatus and redirectTo if available
              final redirectTo = data['redirectTo'];

              // Set onboarding status based on redirectTo (matches backend logic)
              // redirectTo: 'home' means patient profile exists (onboarding complete)
              // redirectTo: 'profile_setup' means patient profile doesn't exist (onboarding not complete)
              if (redirectTo == 'home') {
                await SessionService.setOnboardingComplete(true);
              } else if (redirectTo == 'profile_setup') {
                await SessionService.setOnboardingComplete(false);
              }
            } else {
              _errorMessage = 'Token not found in response';
              _isLoading = false;
              notifyListeners();
              return false;
            }

            // User ID should already be set from loginOrRegisterUser response
            // But we can also check if it's in the verify response
            if (_userId == null && data != null && data['userId'] != null) {
              _userId = data['userId'];
            }

            if (_authToken != null) {
              // Store user info in secure storage with verification
              if (_userId != null && _phoneNumber != null) {
                final stored = await SecureStorageService.storeUserInfo(
                  _userId!,
                  _phoneNumber!,
                );
                if (!stored) {}
              }

              // Store tokens - JWT decoder will extract expiration from token
              // No need to pass expiresInSeconds as it will be decoded from JWT
              await SessionService.storeTokens(authToken: _authToken!);
            } else {}
          } catch (e) {
            _errorMessage = 'Failed to parse authentication data';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } else {
          _errorMessage = 'Invalid response from server';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result.message ?? 'Verification failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOTP() async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number not found. Please start over.';
      notifyListeners();
      return false;
    }

    return await loginOrRegisterUser(_phoneNumber!);
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    if (_authToken == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return null;
    }

    _isUploadingImage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageKey = await _uploadService.uploadImageComplete(
        authToken: _authToken!,
        imageFile: imageFile,
      );

      if (imageKey != null) {
        _profilePhotoKey = imageKey;
        _isUploadingImage = false;
        notifyListeners();
        return imageKey;
      } else {
        _errorMessage = 'Failed to upload image';
        _isUploadingImage = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Image upload failed: ${e.toString()}';
      _isUploadingImage = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> uploadProfileImageBytes({
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (_authToken == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return null;
    }

    _isUploadingImage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final imageKey = await _uploadService.uploadImageBytesComplete(
        authToken: _authToken!,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (imageKey != null) {
        _profilePhotoKey = imageKey;
        _isUploadingImage = false;
        notifyListeners();
        return imageKey;
      } else {
        _errorMessage = 'Failed to upload image';
        _isUploadingImage = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Image upload failed: ${e.toString()}';
      _isUploadingImage = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> savePatientDetails({
    required String firstName,
    required String lastName,
    required String dob,
    required String gender,
  }) async {
    if (_authToken == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return false;
    }

    _isSavingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = PatientDetailsRequest(
        firstName: firstName,
        lastName: lastName,
        dob: dob,
        gender: gender,
        profilePhoto: _profilePhotoKey,
      );

      final response = await _uploadService.savePatientDetails(
        authToken: _authToken!,
        request: request,
      );

      _isSavingDetails = false;

      if (response.success) {
        // Patient profile saved successfully - mark onboarding as complete
        // This matches backend logic: after profile setup, redirectTo becomes 'home'
        await SessionService.setOnboardingComplete(true);

        _profilePhotoKey = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSavingDetails = false;
      _errorMessage = 'Failed to save details: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearProfilePhoto() {
    _profilePhotoKey = null;
    notifyListeners();
  }

  bool get hasProfilePhoto => _profilePhotoKey != null;

  Future<bool> updatePatientProfile({
    required String firstName,
    required String lastName,
    String? bloodGroup,
    int? height,
    int? weight,
    String? dob, // YYYY-MM-DD
    String? profilePhoto,
  }) async {
    if (_authToken == null) {
      _errorMessage = 'Authentication required';
      notifyListeners();
      return false;
    }

    _isSavingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        if (bloodGroup != null && bloodGroup.isNotEmpty) 'bloodGroup': bloodGroup,
        if (height != null) 'height': height,
        if (weight != null) 'weight': weight,
        if (dob != null && dob.isNotEmpty) 'dob': dob,
        if (profilePhoto != null && profilePhoto.isNotEmpty) 'profilePhoto': profilePhoto,
      };

      final resp = await http.post(
        Uri.parse(Endpoints.updatePatientProfile),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authToken!}',
          'x-access-token': _authToken!,
        },
        body: jsonEncode(body),
      );

      _isSavingDetails = false;

      if (resp.statusCode == 200) {
        notifyListeners();
        return true;
      } else {
        try {
          final m = jsonDecode(resp.body);
          _errorMessage = m['message']?.toString() ?? 'Failed to update profile';
        } catch (_) {
          _errorMessage = 'Failed to update profile';
        }
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSavingDetails = false;
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Load saved token from session storage
  /// Only loads if token is valid and not expired
  Future<void> _loadSavedToken() async {
    try {
      // Check if token is valid before loading
      final hasValidSession = await SessionService.hasValidSession();
      if (hasValidSession) {
        _authToken = await SessionService.getAuthToken();
        final userInfo = await SecureStorageService.getUserInfo();
        _userId = userInfo['userId'];
        notifyListeners();
      } else {
        // Token expired or doesn't exist
        _authToken = null;
        _userId = null;
        notifyListeners();
      }
    } catch (e) {
      _authToken = null;
      _userId = null;
      notifyListeners();
    }
  }

  /// Clear session - production-grade with proper cleanup
  Future<bool> clearSession() async {
    try {
      // Clear in-memory state
      _challengeId = null;
      _phoneNumber = null;
      _errorMessage = null;
      _authToken = null;
      _userId = null;
      _profilePhotoKey = null;
      _isNewUser = false;

      // Clear session using SessionService
      final success = await SessionService.clearSession();

      notifyListeners();

      if (success) {
      } else {}

      return success;
    } catch (e) {
      notifyListeners();
      return false;
    }
  }

  /// Login with MPIN
  /// Returns: true if successful, false if failed
  /// Sets _errorMessage to 'SESSION_EXPIRED' if session expired and backend MPIN login fails
  ///
  /// Matches Alaan's approach: Sends MPIN directly to backend for verification (no local verification)
  Future<bool> loginWithMPIN(String mpin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get phone number from storage
      final userInfo = await SecureStorageService.getUserInfo();
      final phoneNumber = userInfo['phoneNumber'];

      if (phoneNumber == null || phoneNumber.isEmpty) {
        _isLoading = false;
        _errorMessage = 'SESSION_EXPIRED';
        notifyListeners();
        return false;
      }

      // Send MPIN directly to backend for verification (matches Alaan's approach)
      final result = await _authService.loginWithMPIN(phoneNumber, mpin);

      // Debug: Log the result to help diagnose issues
      print('Login result: success=${result['success']}, hasToken=${result['token'] != null}');

      // Check success (handle both bool true and string 'true')
      final isSuccess = result['success'] == true || result['success'] == 'true';
      
      if (isSuccess) {
        // Store token and user info
        final token = result['token'];
        
        // Validate token exists and is not empty
        if (token == null || token.toString().isEmpty) {
          _isLoading = false;
          _errorMessage = 'Token not received from server';
          notifyListeners();
          return false;
        }

        _authToken = token.toString();

        // Extract userId from JWT token payload
        String? extractedUserId;
        try {
          if (_authToken != null && _authToken!.isNotEmpty) {
            final payload = JwtDecoder.decodePayload(_authToken!);
            if (payload != null && payload['id'] != null) {
              extractedUserId = payload['id'].toString();
              _userId = extractedUserId;
            }
          }
        } catch (e) {
          // Log JWT decoding error but continue - userId extraction is optional
          print('Warning: Failed to decode JWT payload: $e');
        }

        // Store token and user info
        try {
          await SessionService.storeTokens(authToken: _authToken!);
          // Store user info with userId and phone number
          final userIdToStore = extractedUserId ?? phoneNumber;
          await SecureStorageService.storeUserInfo(
            userIdToStore,
            phoneNumber,
          );
        } catch (e) {
          // If token storage fails, login should fail
          _isLoading = false;
          _errorMessage = 'Failed to store authentication token: $e';
          notifyListeners();
          return false;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // If backend login fails, check if we have a valid session
        final hasValidSession = await SessionService.hasValidSession();
        if (hasValidSession) {
          // Use existing session
          _authToken = await SessionService.getAuthToken();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'MPIN login failed';
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Login with biometric
  /// Returns: true if successful, false if failed
  /// Sets _errorMessage to 'SESSION_EXPIRED' if session expired (special case)
  Future<bool> loginWithBiometric() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if biometric is available and enabled
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        _isLoading = false;
        _errorMessage =
            'Biometric authentication is not available on this device';
        notifyListeners();
        return false;
      }

      final isEnabled = await SecureStorageService.isBiometricEnabled();
      if (!isEnabled) {
        _isLoading = false;
        _errorMessage = 'Biometric authentication is not enabled';
        notifyListeners();
        return false;
      }

      // Get MPIN using biometric
      final authConfig = BiometricAuthConfig(
        localizedReason: 'Use your biometric to authenticate',
        signInTitle: 'Biometric Authentication',
        cancelButton: 'Cancel',
      );

      final mpin = await SecureStorageService.getMPINWithBiometric(
        config: authConfig,
      );

      if (mpin == null || mpin.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Biometric authentication cancelled or failed';
        notifyListeners();
        return false;
      }

      // Use MPIN login with the retrieved MPIN
      return await loginWithMPIN(mpin);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Biometric login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Setup MPIN via backend API
  /// User should be authenticated (have valid token) after OTP verification
  Future<bool> setupMPIN(String mpin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get auth token if available (user should be authenticated after OTP)
      final authToken = _authToken ?? await SessionService.getAuthToken();

      // Call backend API to setup MPIN
      final result = await _authService.setupMPIN(mpin, authToken: authToken);

      if (result['success'] == true) {
        // Store MPIN locally for biometric and convenience
        await SecureStorageService.storeMPIN(mpin);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = result['message'] ?? 'MPIN setup failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'MPIN setup failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Logout user - clears session
  /// After logout, user will be redirected to login page
  /// Production-grade: Returns success status for proper error handling
  Future<bool> logout() async {
    try {
      final success = await clearSession();

      if (success) {
      } else {}

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    try {
      return await SessionService.isOnboardingComplete();
    } catch (e) {
      return false;
    }
  }

  /// Step 1: Send OTP for forget MPIN
  Future<bool> forgetMpinSendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Include Authorization header if user has a valid session
      final authToken = _authToken ?? await SessionService.getAuthToken();
      final result = await _authService.forgetMpinSendOtp(
        phone: phone,
        authToken: authToken,
      );
      _isLoading = false;

      if (result['success'] == true) {
        _challengeId = result['challengeId'];
        _phoneNumber = phone;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Step 2: Verify OTP for forget MPIN
  Future<bool> forgetMpinVerifyOtp(String otp) async {
    if (_challengeId == null || _phoneNumber == null) {
      _errorMessage = 'Session expired. Please try again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.forgetMpinVerifyOtp(
        challengeId: _challengeId!,
        otp: otp,
        phone: _phoneNumber,
      );
      _isLoading = false;

      if (result['success'] == true) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Step 3: Reset MPIN
  Future<bool> forgetMpinReset(String mpin) async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number not found. Please start over.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.forgetMpinReset(
        mpin: mpin,
        phone: _phoneNumber!,
      );
      _isLoading = false;

      if (result['success'] == true) {
        // Store MPIN locally after successful reset
        await SecureStorageService.storeMPIN(mpin);
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
