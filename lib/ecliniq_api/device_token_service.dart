import 'dart:convert';
import 'dart:developer';

import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class DeviceTokenService {
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    required String deviceId,
    required String deviceName,
    required String deviceModel,
    required String appVersion,
    required String osVersion,
    String? authToken,
  }) async {
    final url = Uri.parse(Endpoints.registerDeviceToken);
    
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = {
        'token': token,
        'platform': platform,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceModel': deviceModel,
        'appVersion': appVersion,
        'osVersion': osVersion,
      };

      log('Registering device token with body: $body');

      final response = await EcliniqHttpClient.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      log('Register device token response with status code: ${response.statusCode}');
      log('Register device token response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Device token registered successfully');
      } else {
        log('Failed to register device token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error registering device token: $e');
    }
  }
}
