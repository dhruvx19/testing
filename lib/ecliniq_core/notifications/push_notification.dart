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
import 'package:ecliniq/ecliniq_core/notifications/appointment_lock_screen_notification.dart';
import 'package:ecliniq/ecliniq_api/models/appointment.dart' as api_models;
import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecliniq/ecliniq_core/notifications/local_notifications.dart';


@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
  log('Background message data: ${message.data}');
  
  // Initialize notification services
  try {
    await LocalNotifications.init();
    await AppointmentLockScreenNotification.init();
    
    final data = message.data;
    
    // Handle appointment token updates for lock screen
    final type = data['type'] as String?;
    if (type == 'appointment_token_update' || type == 'token_update') {
      final appointmentId = data['appointmentId'] as String?;
      final currentRunningToken = data['currentRunningToken'] != null
          ? int.tryParse(data['currentRunningToken'].toString())
          : null;
      final userToken = data['userToken'] != null
          ? int.tryParse(data['userToken'].toString())
          : null;
      final doctorName = data['doctorName'] as String? ?? 'Doctor';
      final hospitalName = data['hospitalName'] as String? ?? 'Clinic';
      final appointmentTimeStr = data['appointmentTime'] as String?;
      
      if (appointmentId != null && userToken != null) {
        try {
          final appointmentTime = appointmentTimeStr != null
              ? DateTime.parse(appointmentTimeStr)
              : DateTime.now();
          
          final appointmentData = api_models.AppointmentData(
            id: appointmentId,
            patientId: '',
            bookedFor: 'SELF',
            doctorId: '',
            doctorSlotScheduleId: '',
            tokenNo: userToken,
            status: 'CONFIRMED',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await AppointmentLockScreenNotification.updateNotification(
            appointment: appointmentData,
            currentRunningToken: currentRunningToken,
            doctorName: doctorName,
            hospitalName: hospitalName,
            appointmentTime: appointmentTime,
          );
        } catch (e) {
          log('Error updating lock screen notification in background: $e');
        }
      }
      return; // Don't process other notification types
    }
    
    // Handle other appointment updates (non-token updates)
    // These can be handled by regular FCM notifications or other services
    // The lock screen notification service handles token-specific updates
  } catch (e) {
    log('Error handling background notification: $e');
  }
}

/// Push notification service for handling Firebase Cloud Messaging
class EcliniqPushNotifications {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static RemoteMessage? _initialMessage;


  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      log('FCM Token: $token');
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

      // Note: Device token registration will be called after user login
    } catch (e) {
      log('Error initializing push notifications: $e');
    }
  }

  /// Register device token with backend
  /// Should be called after user successfully logs in
  /// @param authToken - Authentication token for the logged-in user
  static Future<void> registerDeviceToken({String? authToken}) async {
    try {
      final token = await getToken();
      if (token == null) {
        log('FCM token is null, skipping device token registration');
        return;
      }

      if (authToken == null || authToken.isEmpty) {
        log('Auth token is missing, skipping device token registration');
        return;
      }

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
        authToken: authToken,
      );
      
      log('Device token registration initiated with auth token');
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        log('FCM Token refreshed: $newToken');
        
        // Get current auth token from storage
        final prefs = await SharedPreferences.getInstance();
        final currentAuthToken = prefs.getString('auth_token');
        
        if (currentAuthToken != null && currentAuthToken.isNotEmpty) {
          await DeviceTokenService().registerDeviceToken(
            token: newToken,
            platform: platform,
            deviceId: deviceId,
            deviceName: deviceName,
            deviceModel: deviceModel,
            appVersion: packageInfo.version,
            osVersion: osVersion,
            authToken: currentAuthToken,
          );
        } else {
          log('Auth token not available for token refresh registration');
        }
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
      log('Foreground notification received: ${message.messageId}');
      log('Notification title: ${message.notification?.title}');
      log('Notification body: ${message.notification?.body}');
      log('Notification data: ${message.data}');
      
      // Handle appointment token updates for lock screen notification
      _handleAppointmentTokenUpdate(message);
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

    // Check if this is an appointment token update
    if (type == 'appointment_token_update' || type == 'token_update') {
      _handleAppointmentTokenUpdateFromData(data);
      return;
    }

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

  /// Handle appointment token update from FCM message
  /// @description Processes FCM messages for token updates and shows/updates lock screen notification
  /// @param message - FCM RemoteMessage with token update data
  static Future<void> _handleAppointmentTokenUpdate(RemoteMessage message) async {
    try {
      final data = message.data;
      if (data.isEmpty) return;

      final type = data['type'] as String?;
      if (type != 'appointment_token_update' && type != 'token_update') {
        return; // Not a token update notification
      }

      await _handleAppointmentTokenUpdateFromData(data);
    } catch (e) {
      log('Error handling appointment token update: $e');
    }
  }

  /// Handle appointment token update from notification data
  /// @description Fetches appointment details and updates lock screen notification
  /// @param data - Notification data payload with appointment and token info
  static Future<void> _handleAppointmentTokenUpdateFromData(
      Map<String, dynamic> data) async {
    try {
      final appointmentId = data['appointmentId'] as String?;
      final currentRunningToken = data['currentRunningToken'] != null
          ? int.tryParse(data['currentRunningToken'].toString())
          : null;
      final userToken = data['userToken'] != null
          ? int.tryParse(data['userToken'].toString())
          : null;

      if (appointmentId == null) {
        log('Appointment ID missing in token update notification');
        return;
      }

      // Get auth token
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        log('Auth token not available for fetching appointment details');
        return;
      }

      // Fetch appointment details from backend
      final appointmentService = AppointmentService();
      final appointmentDetailResponse =
          await appointmentService.getAppointmentDetail(
        appointmentId: appointmentId,
        authToken: authToken,
      );

      if (!appointmentDetailResponse.success ||
          appointmentDetailResponse.data == null) {
        log('Failed to fetch appointment details for lock screen notification');
        return;
      }

      final appointmentDetail = appointmentDetailResponse.data!;
      final doctor = appointmentDetail.doctor;
      final location = appointmentDetail.location;
      final schedule = appointmentDetail.schedule;

      // Extract appointment data
      final appointmentData = api_models.AppointmentData(
        id: appointmentDetail.appointmentId,
        patientId: appointmentDetail.patient.name,
        bookedFor: appointmentDetail.bookedFor,
        doctorId: doctor.userId,
        doctorSlotScheduleId: schedule.date.toIso8601String(),
        tokenNo: userToken ?? appointmentDetail.tokenNo ?? 0,
        status: appointmentDetail.status,
        createdAt: appointmentDetail.createdAt,
        updatedAt: appointmentDetail.updatedAt,
      );

      // Show or update lock screen notification
      await AppointmentLockScreenNotification.updateNotification(
        appointment: appointmentData,
        currentRunningToken: currentRunningToken,
        doctorName: doctor.name,
        hospitalName: location.name,
        appointmentTime: schedule.startTime,
      );

      log('Lock screen notification updated for appointment: $appointmentId');
    } catch (e) {
      log('Error processing appointment token update: $e');
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

