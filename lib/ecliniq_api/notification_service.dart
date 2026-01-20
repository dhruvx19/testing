import 'dart:convert';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  /// Get all notifications for the patient
  /// @description Retrieves all notifications (new and older) with pagination support
  /// @param authToken - Authentication token for the patient
  /// @returns Future<Map<String, dynamic>> - Response containing all notifications, unread notifications, counts, and pagination info
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

      final response = await http.get(url, headers: headers);

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

  /// Mark a specific notification as read
  /// @description Marks a single notification as read by its ID
  /// @param notificationId - The ID of the notification to mark as read
  /// @param authToken - Authentication token for the patient
  /// @returns Future<Map<String, dynamic>> - Response indicating success or failure
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

      final response = await http.put(url, headers: headers);

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

  /// Mark all notifications as read
  /// @description Marks all unread notifications for the patient as read
  /// @param authToken - Authentication token for the patient
  /// @returns Future<Map<String, dynamic>> - Response containing count of marked notifications
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

      final response = await http.put(url, headers: headers);

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



