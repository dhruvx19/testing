import 'dart:convert';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
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

  
  
  Future<void> fetchUnreadCount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await EcliniqHttpClient.get(
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
          
        } else {
          
        }
      } else {
        
      }
    } catch (e) {
      _errorMessage = e.toString();
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  
  
  
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
        
        if (response['data'] != null &&
            (response['data'] as Map).containsKey('counts') &&
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
