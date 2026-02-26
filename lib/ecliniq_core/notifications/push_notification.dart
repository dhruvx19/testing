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

  try {
    await LocalNotifications.init();
    await AppointmentLockScreenNotification.init();

    final data = message.data;

    // ── SLOT_LIVE_UPDATE: silent lock screen update (NO popup banner) ─────────
    // IMPORTANT for backend team: send as DATA-ONLY FCM message.
    // Do NOT include a "notification" field in the FCM payload — if you do,
    // Firebase will automatically show a system popup banner regardless.
    // Correct FCM server payload shape:
    //   { "data": { "notificationType": "SLOT_LIVE_UPDATE", "yourToken": "15",
    //               "currentToken": "10", "estimatedTime": "12:30 PM", ... },
    //     "android": { "priority": "high" }  }   <-- NO "notification" key
    final notificationType = data['notificationType'] as String?;
    if (notificationType == 'SLOT_LIVE_UPDATE') {
      await EcliniqPushNotifications._handleSlotLiveUpdateFromData(data);
      return;
    }

    // ── Legacy payload format: appointment_token_update ──────────────────────
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
      return;
    }
  } catch (e) {
    log('Error handling background notification: $e');
  }
}


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

  
  
  static Future<void> init() async {
    try {
      
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );


      
      _initialMessage = await _messaging.getInitialMessage();
      
      log('Push notifications initialized');

      
    } catch (e) {
      log('Error initializing push notifications: $e');
    }
  }

  
  
  
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
        deviceName = androidInfo.brand; 
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
      
      
      _messaging.onTokenRefresh.listen((newToken) async {
        log('FCM Token refreshed: $newToken');
        
        
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

  
  
  static void setNotificationListeners() {
    log('Setting up notification listeners');

    
    if (_initialMessage != null) {
      _handleNotification(data: _initialMessage!.data);
      _initialMessage = null;
    }

    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('Notification opened app: ${message.messageId}');
      log('Notification data: ${message.data}');
      _handleNotification(data: message.data);
    });

    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Foreground notification received: ${message.messageId}');
      log('Notification title: ${message.notification?.title}');
      log('Notification body: ${message.notification?.body}');
      log('Notification data: ${message.data}');
      
      // Handle new SLOT_LIVE_UPDATE format
      final notificationType = message.data['notificationType'] as String?;
      if (notificationType == 'SLOT_LIVE_UPDATE') {
        _handleSlotLiveUpdateFromData(message.data);
        return;
      }

      // Legacy token update
      _handleAppointmentTokenUpdate(message);
    });
  }

  
  
  static void _handleNotification({
    required Map<String, dynamic>? data,
  }) {
    if (data == null) return;

    log('Handling notification with data: $data');

    final type = data['type'] as String?;
    final path = data['path'] as String?;
    final screen = data['screen'] as String?;

    
    if (type == 'appointment_token_update' || type == 'token_update') {
      _handleAppointmentTokenUpdateFromData(data);
      return;
    }

    
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

      
      
      case 'appointment':
      case 'APPOINTMENT':
        final appointmentId = data['appointmentId'] as String?;
        if (appointmentId != null) {
          
          
        }
        break;

      default:
        log('Unknown notification type: $navigationTarget');
        
        _navigateToHome();
    }
  }

  // ── New handler: SLOT_LIVE_UPDATE payload ──────────────────────────────────
  //
  // Backend FCM payload structure expected:
  // data: {
  //   "notificationType": "SLOT_LIVE_UPDATE",
  //   "appointmentId": "...",
  //   "doctorName": "Dr. Milind Chauhan",
  //   "yourToken": "15",
  //   "currentToken": "10",
  //   "estimatedTime": "12:30 PM",
  //   "waitTimeMinutes": "50",
  //   "timeline": "{\"start\":1,\"current\":10,\"yourNo\":15}"
  // }
  static Future<void> _handleSlotLiveUpdateFromData(
    Map<String, dynamic> data,
  ) async {
    try {
      final appointmentId = data['appointmentId'] as String?;
      final doctorName = data['doctorName'] as String? ?? 'Your Doctor';
      final hospitalName = data['hospitalName'] as String? ?? 'eClinic-Q';
      final yourToken =
          data['yourToken'] != null
              ? int.tryParse(data['yourToken'].toString())
              : null;
      final currentToken =
          data['currentToken'] != null
              ? int.tryParse(data['currentToken'].toString())
              : null;
      final estimatedTimeStr = data['estimatedTime'] as String?;
      final waitTimeMinutes =
          data['waitTimeMinutes'] != null
              ? int.tryParse(data['waitTimeMinutes'].toString())
              : null;

      if (appointmentId == null || yourToken == null) {
        log(
          'SLOT_LIVE_UPDATE: Missing required fields (appointmentId / yourToken)',
        );
        return;
      }

      // Parse estimatedTime from a human-readable string like "12:30 PM"
      // Fall back to now + waitTimeMinutes if not parseable as ISO.
      DateTime appointmentTime;
      if (estimatedTimeStr != null) {
        final iso = DateTime.tryParse(estimatedTimeStr);
        if (iso != null) {
          appointmentTime = iso;
        } else {
          // estimatedTimeStr is like "12:30 PM" — reconstruct a DateTime for today
          try {
            final now = DateTime.now();
            final parts = estimatedTimeStr.split(' ');
            final timeParts = parts[0].split(':');
            int hour = int.parse(timeParts[0]);
            final minute = int.parse(timeParts[1]);
            final isPM = parts.length > 1 && parts[1].toUpperCase() == 'PM';
            if (isPM && hour != 12) hour += 12;
            if (!isPM && hour == 12) hour = 0;
            appointmentTime = DateTime(now.year, now.month, now.day, hour, minute);
          } catch (_) {
            appointmentTime = DateTime.now().add(
              Duration(minutes: waitTimeMinutes ?? 30),
            );
          }
        }
      } else {
        appointmentTime = DateTime.now().add(
          Duration(minutes: waitTimeMinutes ?? 30),
        );
      }

      final appointmentData = api_models.AppointmentData(
        id: appointmentId,
        patientId: '',
        bookedFor: 'SELF',
        doctorId: '',
        doctorSlotScheduleId: '',
        tokenNo: yourToken,
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await AppointmentLockScreenNotification.updateNotification(
        appointment: appointmentData,
        currentRunningToken: currentToken,
        doctorName: doctorName,
        hospitalName: hospitalName,
        appointmentTime: appointmentTime,
      );

      log(
        'SLOT_LIVE_UPDATE: notification updated — token $currentToken/$yourToken for $doctorName',
      );
    } catch (e) {
      log('Error handling SLOT_LIVE_UPDATE: $e');
    }
  }

  // ── Legacy handler ──────────────────────────────────────────────────────────
  static Future<void> _handleAppointmentTokenUpdate(RemoteMessage message) async {
    try {
      final data = message.data;
      if (data.isEmpty) return;

      final type = data['type'] as String?;
      if (type != 'appointment_token_update' && type != 'token_update') {
        return; 
      }

      await _handleAppointmentTokenUpdateFromData(data);
    } catch (e) {
      log('Error handling appointment token update: $e');
    }
  }

  
  
  
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

      
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        log('Auth token not available for fetching appointment details');
        return;
      }

      
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

  
  static void _navigateToHome() {
    EcliniqRouter.pushReplacement(
      const HomeScreen(),
      transition: PageTransitionType.fade,
    );
  }

  
  static void _navigateToMyVisits() {
    EcliniqRouter.pushReplacement(
      const MyVisits(),
      transition: PageTransitionType.fade,
    );
  }

  
  static void _navigateToHealthFiles() {
    EcliniqRouter.pushReplacement(
      const HealthFiles(),
      transition: PageTransitionType.fade,
    );
  }

  
  static void _navigateToProfile() {
    EcliniqRouter.pushReplacement(
      const ProfilePage(),
      transition: PageTransitionType.fade,
    );
  }

  
  
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

  
  
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      log('Subscribed to topic: $topic');
    } catch (e) {
      log('Error subscribing to topic $topic: $e');
    }
  }

  
  
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      log('Unsubscribed from topic: $topic');
    } catch (e) {
      log('Error unsubscribing from topic $topic: $e');
    }
  }

  
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      log('FCM token deleted');
    } catch (e) {
      log('Error deleting FCM token: $e');
    }
  }

  /// For testing only — simulates a backend SLOT_LIVE_UPDATE FCM push
  /// so you can verify lock screen updates without a real FCM message.
  static Future<void> simulateSlotLiveUpdate({
    required int yourToken,
    required int currentToken,
    String doctorName = 'Dr. Milind Chauhan',
    String hospitalName = 'eClinic-Q',
    String estimatedTime = '12:30 PM',
  }) async {
    final waitMinutes = yourToken > currentToken ? (yourToken - currentToken) * 2 : 0;
    await _handleSlotLiveUpdateFromData({
      'notificationType': 'SLOT_LIVE_UPDATE',
      'appointmentId': 'test-appointment-${DateTime.now().millisecondsSinceEpoch}',
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'yourToken': yourToken.toString(),
      'currentToken': currentToken.toString(),
      'estimatedTime': estimatedTime,
      'waitTimeMinutes': waitMinutes.toString(),
    });
  }

}
