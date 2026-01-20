import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_api/notification_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  int _unreadCount = 0;
  String? _errorMessage;
  Map<String, dynamic>? _allNotifications;

  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get allNotifications => _allNotifications;

  /// Fetch unread notification count
  /// @description Gets the count of unread notifications for the patient
  Future<void> fetchUnreadCount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        debugPrint('No auth token found for notifications');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(Endpoints.getUnreadNotificationCount),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
          'x-access-token': authToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final count = data['data']['unreadCount'];
          _unreadCount = count is int ? count : (int.tryParse(count.toString()) ?? 0);
          debugPrint('Unread notification count: $_unreadCount');
        } else {
          debugPrint('Failed to get unread count: ${data['message']}');
        }
      } else {
        debugPrint('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching unread count: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all notifications
  /// @description Retrieves all notifications (new and older) for the patient
  /// @returns Future<Map<String, dynamic>?> - Response containing all notifications or null on error
  Future<Map<String, dynamic>?> fetchAllNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        _errorMessage = 'No authentication token found';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final response = await _notificationService.getAllNotifications(
        authToken: authToken,
      );

      if (response['success'] == true) {
        _allNotifications = response;
        // Update unread count from response
        if (response['data'] != null &&
            response['data']['counts'] != null) {
          _unreadCount = response['data']['counts']['unreadCount'] ?? 0;
        }
        _isLoading = false;
        notifyListeners();
        return response;
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch notifications';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Mark a notification as read
  /// @description Marks a specific notification as read by its ID
  /// @param notificationId - The ID of the notification to mark as read
  /// @returns Future<bool> - True if successful, false otherwise
  Future<bool> markAsRead(String notificationId) async {
    try {
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        _errorMessage = 'No authentication token found';
        notifyListeners();
        return false;
      }

      final response = await _notificationService.markAsRead(
        notificationId: notificationId,
        authToken: authToken,
      );

      if (response['success'] == true) {
        // Update unread count
        if (_unreadCount > 0) {
          _unreadCount--;
        }
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to mark notification as read';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark all notifications as read
  /// @description Marks all unread notifications as read
  /// @returns Future<bool> - True if successful, false otherwise
  Future<bool> markAllAsRead() async {
    try {
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        _errorMessage = 'No authentication token found';
        notifyListeners();
        return false;
      }

      final response = await _notificationService.markAllAsRead(
        authToken: authToken,
      );

      if (response['success'] == true) {
        _unreadCount = 0;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Failed to mark all notifications as read';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
      return false;
    }
  }
}
