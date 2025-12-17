import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/home_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/my_visits/my_visits.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/health_files.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/profile_page.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ecliniq/ecliniq_api/device_token_service.dart';


/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
  log('Background message data: ${message.data}');
  // Handle background message here if needed
}

/// Push notification service for handling Firebase Cloud Messaging
class EcliniqPushNotifications {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static RemoteMessage? _initialMessage;

  /// Get FCM token for the device
  /// @returns FCM token string or null if unavailable
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      log('FCM Token: $token');
      print('=============================================');
      print('FCM TOKEN: $token');
      print('=============================================');
      return token;
    } catch (e) {
      log('Error getting FCM token: $e');
      return null;
    }
  }

  /// Initialize push notifications
  /// Sets up background message handler and notification presentation options
  static Future<void> init() async {
    try {
      // Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Configure notification presentation options for iOS
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );


      // Check if app was opened from a notification
      _initialMessage = await _messaging.getInitialMessage();
      
      log('Push notifications initialized');

      // Register device token
      await registerDeviceToken();
    } catch (e) {
      log('Error initializing push notifications: $e');
    }
  }

  /// Register device token with backend
  static Future<void> registerDeviceToken() async {
    try {
      final token = await getToken();
      if (token == null) return;

      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      String deviceId = '';
      String deviceName = '';
      String deviceModel = '';
      String osVersion = '';
      String platform = '';

      if (Platform.isAndroid) {
        platform = 'ANDROID';
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceName = androidInfo.brand; // or model
        deviceModel = androidInfo.model;
        osVersion = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        platform = 'IOS';
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        deviceName = iosInfo.name;
        deviceModel = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      await DeviceTokenService().registerDeviceToken(
        token: token,
        platform: platform,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceModel: deviceModel,
        appVersion: packageInfo.version,
        osVersion: osVersion,
      );
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        log('FCM Token refreshed: $newToken');
        print('=============================================');
        print('FCM TOKEN REFRESHED: $newToken');
        print('=============================================');
        await DeviceTokenService().registerDeviceToken(
          token: newToken,
          platform: platform,
          deviceId: deviceId,
          deviceName: deviceName,
          deviceModel: deviceModel,
          appVersion: packageInfo.version,
          osVersion: osVersion,
        );
      });

    } catch (e) {
      log('Error registering device token: $e');
    }
  }

  /// Set up notification listeners
  /// Should be called after app initialization
  static void setNotificationListeners() {
    log('Setting up notification listeners');

    // Handle notification that opened the app
    if (_initialMessage != null) {
      _handleNotification(data: _initialMessage!.data);
      _initialMessage = null;
    }

    // Handle notification when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification opened app: ${message.messageId}');
      log('Notification data: ${message.data}');
      _handleNotification(data: message.data);
    });

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('=== FOREGROUND NOTIFICATION RECEIVED ===');
      print('ID: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      print('========================================');

      log('Foreground notification received: ${message.messageId}');
      log('Notification title: ${message.notification?.title}');
      log('Notification body: ${message.notification?.body}');
      log('Notification data: ${message.data}');
      
      // You can show a local notification here if needed
      // or handle the notification UI in your app
    });
  }

  /// Handle notification data and navigate accordingly
  /// @param data - Notification data payload
  static void _handleNotification({
    required Map<String, dynamic>? data,
  }) {
    if (data == null) return;

    log('Handling notification with data: $data');

    final type = data['type'] as String?;
    final path = data['path'] as String?;
    final screen = data['screen'] as String?;

    // Determine navigation based on notification data
    final navigationTarget = type ?? path ?? screen;

    switch (navigationTarget) {
      case 'home':
      case 'HOME':
        _navigateToHome();
        break;

      case 'visits':
      case 'my_visits':
      case 'MY_VISITS':
        _navigateToMyVisits();
        break;

      case 'health_files':
      case 'HEALTH_FILES':
        _navigateToHealthFiles();
        break;

      case 'profile':
      case 'PROFILE':
        _navigateToProfile();
        break;

      // Add more cases for specific screens
      // Example: appointment details
      case 'appointment':
      case 'APPOINTMENT':
        final appointmentId = data['appointmentId'] as String?;
        if (appointmentId != null) {
          // Navigate to appointment details
          // _navigateToAppointmentDetails(appointmentId);
        }
        break;

      default:
        log('Unknown notification type: $navigationTarget');
        // Default to home if unknown type
        _navigateToHome();
    }
  }

  /// Navigate to home screen
  static void _navigateToHome() {
    EcliniqRouter.pushReplacement(
      const HomeScreen(),
      transition: PageTransitionType.fade,
    );
  }

  /// Navigate to my visits screen
  static void _navigateToMyVisits() {
    EcliniqRouter.pushReplacement(
      const MyVisits(),
      transition: PageTransitionType.fade,
    );
  }

  /// Navigate to health files screen
  static void _navigateToHealthFiles() {
    EcliniqRouter.pushReplacement(
      const HealthFiles(),
      transition: PageTransitionType.fade,
    );
  }

  /// Navigate to profile screen
  static void _navigateToProfile() {
    EcliniqRouter.pushReplacement(
      const ProfilePage(),
      transition: PageTransitionType.fade,
    );
  }

  /// Request notification permissions
  /// @returns true if permission granted, false otherwise
  static Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      log('Notification permission status: ${settings.authorizationStatus}');
      return isGranted;
    } catch (e) {
      log('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Subscribe to a topic
  /// @param topic - Topic name to subscribe to
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
    } catch (e) {
      log('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  /// @param topic - Topic name to unsubscribe from
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Delete FCM token
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      log('FCM token deleted');
    } catch (e) {
      log('Error deleting FCM token: $e');
    }
  }
}

