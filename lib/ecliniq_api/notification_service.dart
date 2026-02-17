import 'dart:convert';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  Future<Map<String, dynamic>> getAllNotifications({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getAllNotifications);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch notifications',
          'data': null,
          'errors': responseData['errors'] ?? response.body,
          'meta': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
        'errors': e.toString(),
        'meta': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> markAsRead({
    required String notificationId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.markAsRead(notificationId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.patch(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to mark notification as read',
          'data': null,
          'errors': responseData['errors'] ?? response.body,
          'meta': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
        'errors': e.toString(),
        'meta': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<Map<String, dynamic>> markAllAsRead({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.markAllAsRead);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.patch(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to mark all notifications as read',
          'data': null,
          'errors': responseData['errors'] ?? response.body,
          'meta': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
        'errors': e.toString(),
        'meta': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
