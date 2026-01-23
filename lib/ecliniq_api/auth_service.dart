import 'dart:convert';
import 'package:ecliniq/ecliniq_api/models/otp_verification_model.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class AuthService {
  Future<Map<String, dynamic>> loginOrRegisterUser(String phone) async {
    final url = Uri.parse(Endpoints.loginOrRegisterUser);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        return {
          'success': true,
          'challengeId': data['challengeId'],
          'phone': data['phone'],
          'userId': data['userId'],
          'isNewUser': data['isNewUser'] ?? false,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<OTPVerificationResponse> verifyOTP(
    String challengeId,
    String phone,
    String otp,
  ) async {
    final url = Uri.parse(Endpoints.verifyUser);

    try {
      // Debug logging

      final requestBody = {
        'challengeId': challengeId,
        'phone': phone,
        'otp': otp,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return OTPVerificationResponse.success(responseData);
      } else {
        // Try to get the actual error message from the server
        String errorMessage = 'Invalid OTP or verification failed';

        if (responseData is Map<String, dynamic>) {
          // Try different common error message formats
          errorMessage =
              responseData['message'] ??
              responseData['error'] ??
              responseData['data']?['message'] ??
              'Invalid OTP or verification failed';

          // Log specific error details
        }

        return OTPVerificationResponse.error(errorMessage);
      }
    } catch (e) {
      return OTPVerificationResponse.error(
        'Failed to connect to the server: $e',
      );
    }
  }

  Future<Map<String, dynamic>> setupMPIN(
    String mpin, {
    String? authToken,
  }) async {
    final url = Uri.parse('${Endpoints.localhost}/api/auth/create-mpin');
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      // Include auth token if provided (user should be authenticated after OTP)
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'mpin': mpin}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'MPIN created successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'MPIN setup failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> loginWithMPIN(String phone, String mpin) async {
    final url = Uri.parse('${Endpoints.localhost}/api/auth/login-with-mpin');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userName':
              phone, // Backend expects userName (can be email or mobile)
          'mpin': mpin,
        }),
      );

      // Handle non-200 status codes
      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message':
                errorData['message'] ??
                errorData['error'] ??
                'MPIN login failed with status ${response.statusCode}',
          };
        } catch (_) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'message': 'MPIN login failed with status ${response.statusCode}',
          };
        }
      }

      // Parse response body
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid response format from server: $e',
        };
      }

      // Check if success is explicitly false (error response)
      final isExplicitlyFailed =
          responseData['success'] == false ||
          responseData['success'] == 'false';

      if (isExplicitlyFailed) {
        // API returned explicit failure
        return {
          'success': false,
          'statusCode': responseData['statusCode'] ?? response.statusCode,
          'message':
              responseData['message'] ??
              responseData['error'] ??
              'Invalid MPIN or login failed',
        };
      }

      final isSuccess =
          responseData['success'] == true ||
          responseData['success'] == 'true' ||
          (responseData['success'] == null && response.statusCode == 200);

      if (isSuccess) {
        // Try to get data from responseData['data'] first
        dynamic data = responseData['data'];

        // If data is null, check if token is directly in responseData (fallback)
        if (data == null && responseData['token'] != null) {
          data = responseData;
        }

        if (data != null && data is Map<String, dynamic>) {
          final token = data['token'];
          if (token != null && token.toString().isNotEmpty) {
            // Extract userId from token if needed, or use phone as identifier
            return {
              'success': true,
              'token': token.toString(),
              'roleNames': data['roleNames'] ?? [],
              'message':
                  data['message'] ??
                  responseData['message'] ??
                  'Login successful',
            };
          } else {}
        } else {}

        // If we got here, token is missing
        return {
          'success': false,
          'message': 'Token not found in response. Response: ${response.body}',
        };
      } else {
        // Login failed
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['error'] ??
              'MPIN login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> sendExistingContactOTP({
    required String type, // "mobile" or "email"
    String? authToken,
  }) async {
    final url = Uri.parse(Endpoints.sendExistingContactOTP);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'type': type}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        return {
          'success': true,
          'challengeId': data['challengeId'],
          'sentTo': data['sentTo'], // "mobile" or "email"
          'contact': data['contact'], // Masked contact
          'message': responseData['message'] ?? 'OTP sent to existing contact',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to send OTP to existing contact',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> verifyExistingContactOtp({
    required String challengeId,
    required String otp,
    String? authToken,
  }) async {
    final url = Uri.parse(Endpoints.verifyExistingContactOtp);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'challengeId': challengeId, 'otp': otp}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        return {
          'success': true,
          'verificationToken': data['verificationToken'],
          'message':
              responseData['message'] ??
              'Existing contact verified successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to verify existing contact OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> sendNewContactOtp({
    required String type, // "mobile" or "email"
    required String newContact, // New mobile number or email
    String? authToken,
  }) async {
    final url = Uri.parse(Endpoints.sendNewContactOtp);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'type': type, 'newContact': newContact}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        return {
          'success': true,
          'challengeId': data['challengeId'],
          'maskedContact': data['maskedContact'],
          'message': responseData['message'] ?? 'OTP sent to new contact',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to send OTP to new contact',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> verifyNewContact({
    required String challengeId, // From send-new-otp response
    required String otp, // OTP from new contact
    String? authToken,
  }) async {
    final url = Uri.parse(Endpoints.verifyNewContactOtp);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'challengeId': challengeId, 'otp': otp}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        return {
          'success': true,
          'newContact': data['phone'] ?? data['emailId'] ?? data['email'],
          'message': responseData['message'] ?? 'Contact changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to verify new contact',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> forgetMpinSendOtp({
    required String phone,
    String? authToken,
  }) async {
    final url = Uri.parse(Endpoints.forgetMpinSendOtp);
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'phone': phone}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        return {
          'success': true,
          'challengeId': data['challengeId'],
          'phone': data['phone'],
          'message': responseData['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> forgetMpinVerifyOtp({
    required String challengeId,
    required String otp,
    String? phone,
  }) async {
    final url = Uri.parse(Endpoints.forgetMpinVerifyOtp);
    try {
      final requestBody = <String, dynamic>{
        'challengeId': challengeId,
        'otp': otp,
      };

      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final data = responseData['data'];
        return {
          'success': true,
          'phone': data['phone'],
          'message': responseData['message'] ?? 'OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to verify OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  Future<Map<String, dynamic>> forgetMpinReset({
    required String mpin,
    required String phone,
  }) async {
    final url = Uri.parse(Endpoints.forgetMpinReset);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mpin': mpin, 'phone': phone}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'MPIN reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset MPIN',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }
}
