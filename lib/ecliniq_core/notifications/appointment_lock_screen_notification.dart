import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:ecliniq/ecliniq_api/models/appointment.dart' as api_models;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

/// Lock screen notification service for appointment token updates
/// Similar to Zomato's order tracking notifications
class AppointmentLockScreenNotification {
  static const int _notificationId =
      9999; // Fixed ID for persistent notification
  static const String _channelId = 'appointment_tracking';
  static const String _channelName = 'Appointment Tracking';
  static const String _channelDescription =
      'Real-time appointment token updates';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _currentAppointmentId;
  
  // Method channel for custom native notifications (Android)
  static const MethodChannel _customNotificationChannel =
      MethodChannel('com.example.ecliniq/custom_notifications');

  /// Initialize the notification service
  /// @description Sets up notification channels for Android and iOS
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Android notification channel setup
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS notification settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channel for lock screen
      if (Platform.isAndroid) {
        await _createAndroidChannel();
      }

      _initialized = true;
      log('Appointment lock screen notification service initialized');
    } catch (e) {
      log('Error initializing lock screen notification: $e');
    }
  }

  /// Create Android notification channel with high priority for lock screen
  static Future<void> _createAndroidChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high, // High importance for lock screen

      enableVibration: false,
      playSound: false,
      showBadge: false,
      enableLights: false,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Show lock screen notification with appointment details
  /// @description Displays a persistent notification on lock screen showing
  /// current token, running token, and appointment details
  /// @param appointment - Appointment data with token information
  /// @param currentRunningToken - Currently running token number from backend
  /// @param doctorName - Name of the doctor
  /// @param hospitalName - Name of the hospital/clinic
  /// @param appointmentTime - Scheduled appointment time
  static Future<void> showAppointmentNotification({
    required api_models.AppointmentData appointment,
    int? currentRunningToken,
    required String doctorName,
    required String hospitalName,
    required DateTime appointmentTime,
  }) async {
    try {
      await init();

      // Request notification permissions if not already granted
      if (Platform.isAndroid) {
        // Android 13+ requires runtime notification permission
        try {
          final androidImplementation = _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          if (androidImplementation != null) {
            // Check if notification permission is granted (Android 13+)
            final granted = await androidImplementation.areNotificationsEnabled();
            if (granted != null && !granted) {
              log(
                '⚠️ Android notification permissions not granted. Please enable in Settings → Apps → Your App → Notifications',
              );
            } else {
              log('✅ Android notification permissions granted');
            }
          }
        } catch (e) {
          log('Error checking Android notification permissions: $e');
        }
      } else if (Platform.isIOS) {
        final iosImplementation = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        if (iosImplementation != null) {
          final result = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: false,
          );
          if (!result!) {
            log(
              '⚠️ iOS notification permissions not granted. Please enable in Settings → Notifications → Your App',
            );
          } else {
            log('✅ iOS notification permissions granted');
          }
        }
      }

      _currentAppointmentId = appointment.id;

      final userToken = appointment.tokenNo;
      final runningToken = currentRunningToken ?? 0;
      final tokensAhead = runningToken > 0 && userToken > runningToken
          ? userToken - runningToken
          : null;

      // Calculate estimated time (assuming ~2-3 minutes per token)
      final estimatedMinutes = tokensAhead != null ? tokensAhead * 2 : 0;

      // Format appointment time
      final timeFormat = DateFormat('h:mm a');
      final formattedExpectedTime = timeFormat.format(appointmentTime);

      // Build notification content matching the AppointmentWaitingScreen design
      // UI format only - logic unchanged
      final title = 'Your Appointment with';
      String body;
      String subtitle;

      // Create progress indicator line with tokens
      // Format: S ──── 74 ──── 76
      //         Start  Current Your No.
      String tokenProgressLine = '';
      String tokenLabelsLine = '';
      
      if (runningToken > 0) {
        // Calculate progress visualization
        final totalTokens = userToken > runningToken ? userToken : (runningToken + 5);
        final startToCurrent = runningToken;
        final currentToYour = userToken > runningToken ? (userToken - runningToken) : 0;
        
        // Create visual progress line
        tokenProgressLine = 'S';
        // Add progress line from Start to Current
        if (startToCurrent > 0) {
          final progressLength = startToCurrent > 10 ? 8 : startToCurrent;
          tokenProgressLine += ' ${'─' * progressLength} ';
        }
        tokenProgressLine += '$runningToken';
        // Add progress line from Current to Your
        if (currentToYour > 0) {
          final progressLength = currentToYour > 10 ? 8 : currentToYour;
          tokenProgressLine += ' ${'─' * progressLength} ';
        }
        tokenProgressLine += '$userToken';
        
        // Create labels line
        tokenLabelsLine = 'Start';
        final startSpacing = runningToken > 10 ? '    ' : '   ';
        tokenLabelsLine += startSpacing;
        tokenLabelsLine += 'Current';
        final currentSpacing = currentToYour > 10 ? '    ' : '   ';
        tokenLabelsLine += currentSpacing;
        tokenLabelsLine += 'Your No.';
      }

      if (runningToken == 0) {
        // Queue not started
        body = '$doctorName\nQueue';
        subtitle = 'Expected Time: $formattedExpectedTime';
      } else if (tokensAhead != null && tokensAhead > 0) {
        // Format matching AppointmentWaitingScreen: Doctor name on one line, "in X min" on next
        body = '$doctorName\nin $estimatedMinutes min';
        subtitle = 'Expected Time: $formattedExpectedTime\n'
            '$tokenProgressLine\n$tokenLabelsLine';
      } else if (userToken == runningToken) {
        // Your turn
        body = '$doctorName\n🎉 Your turn!';
        subtitle = 'Expected Time: $formattedExpectedTime';
      } else if (userToken < runningToken) {
        // Token called
        body = '$doctorName\nYour token has been called';
        subtitle = 'Expected Time: $formattedExpectedTime';
      } else {
        // Default case
        body = '$doctorName';
        subtitle = 'Expected Time: $formattedExpectedTime\n'
            '$tokenProgressLine\n$tokenLabelsLine';
      }

      // Use custom native notification (Android) or Live Activity (iOS)
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          // Prepare time info string
          String timeInfoText = '';
          if (runningToken == 0) {
            timeInfoText = 'Queue not started yet';
          } else if (tokensAhead != null && tokensAhead > 0) {
            timeInfoText = 'in $estimatedMinutes min';
          } else if (userToken == runningToken) {
            timeInfoText = '🎉 Your turn!';
          } else if (userToken < runningToken) {
            timeInfoText = 'Your token has been called';
          }

          // Call native method to show custom notification / Live Activity
          await _customNotificationChannel.invokeMethod('showCustomNotification', {
            'title': title,
            'doctorName': doctorName,
            'timeInfo': timeInfoText,
            'expectedTime': formattedExpectedTime,
            'currentToken': runningToken,
            'userToken': userToken,
            'hospitalName': hospitalName,
          });

          log('✅ Custom native notification/Live Activity shown');
          _currentAppointmentId = appointment.id;
          return; // Exit early, native notification handles it
        } catch (e) {
          log('⚠️ Failed to show custom native notification (falling back to default): $e');
          // Fall through to default notification if native method fails (e.g. old iOS version)
        }
      }

      // Default notification for fallback scenarios
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true, // Persistent notification
        autoCancel: false, // Don't auto-cancel
        showWhen: false,
        // Use custom layout for rich UI matching AppointmentWaitingScreen
        styleInformation: BigTextStyleInformation(
          '$body\n\n$subtitle',
          contentTitle: title,
          summaryText: hospitalName,
          htmlFormatContent: false,
        ),
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public, // Show on lock screen
        fullScreenIntent: false,
        color: const Color(0xFF0066CC), // Blue color matching AppointmentWaitingScreen design
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      // iOS notification details - configured for lock screen display
      // Format matches AppointmentWaitingScreen design
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel
            .timeSensitive, // Time-sensitive shows on lock screen
        threadIdentifier: 'appointment_${appointment.id}',
        categoryIdentifier: 'APPOINTMENT_TRACKING',
        subtitle: subtitle, // Shows: "Expected Time: XX:XX" and "S Start • X Current • Y Your No."
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        _notificationId,
        title,
        body,
        notificationDetails,
        payload: 'appointment_${appointment.id}',
      );

      log(
        '🔔 Lock screen notification shown for appointment: ${appointment.id}',
      );

      if (Platform.isAndroid) {
        log('📱 Android Debug Info:');
        log('   - Title: $title');
        log('   - Body: $body');
        log('   - Channel: $_channelName (High importance)');
        log('   - Visibility: Public (shows on lock screen)');
        log('   - Ongoing: true (persistent notification)');
        log('   ✅ Android notifications work on lock screen automatically');
        log('   💡 Make sure "Show on lock screen" is enabled in device settings');
      } else if (Platform.isIOS) {
        log('📱 iOS Debug Info:');
        log('   - Title: $title');
        log('   - Body: $body');
        log('   - Interruption Level: timeSensitive');
        log('   - Thread ID: appointment_${appointment.id}');
        log(
          '   ⚠️ IMPORTANT: On iOS, lock your device or background the app to see notification on lock screen',
        );
        log(
          '   ⚠️ If app is in foreground, notification may only show in Notification Center',
        );

          // Check if notification permissions are granted
          final iosImplementation = _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          if (iosImplementation != null) {
            final permissions = await iosImplementation.checkPermissions();
            if (permissions != null) {
             
            } else {
              log('   - Permissions: null (not available)');
            }
          }
      }
    } catch (e) {
      log('Error showing lock screen notification: $e');
    }
  }

  /// Update existing notification with new token information
  /// @description Updates the lock screen notification when token status changes
  /// @param appointment - Updated appointment data
  /// @param currentRunningToken - New current running token from backend
  /// @param doctorName - Name of the doctor
  /// @param hospitalName - Name of the hospital/clinic
  /// @param appointmentTime - Scheduled appointment time
  static Future<void> updateNotification({
    required api_models.AppointmentData appointment,
    int? currentRunningToken,
    required String doctorName,
    required String hospitalName,
    required DateTime appointmentTime,
  }) async {
    // If appointment ID changed, show new notification
    if (_currentAppointmentId != appointment.id) {
      await showAppointmentNotification(
        appointment: appointment,
        currentRunningToken: currentRunningToken,
        doctorName: doctorName,
        hospitalName: hospitalName,
        appointmentTime: appointmentTime,
      );
      return;
    }

    // Try native update first (Android & iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final userToken = appointment.tokenNo;
        final runningToken = currentRunningToken ?? 0;
        final tokensAhead = runningToken > 0 && userToken > runningToken
            ? userToken - runningToken
            : null;
        final estimatedMinutes = tokensAhead != null ? tokensAhead * 2 : 0;
        final timeFormat = DateFormat('h:mm a');
        final formattedExpectedTime = timeFormat.format(appointmentTime);

        String timeInfoText = '';
        if (runningToken == 0) {
          timeInfoText = 'Queue not started yet';
        } else if (tokensAhead != null && tokensAhead > 0) {
          timeInfoText = 'in $estimatedMinutes min';
        } else if (userToken == runningToken) {
          timeInfoText = '🎉 Your turn!';
        } else if (userToken < runningToken) {
          timeInfoText = 'Your token has been called';
        }

        await _customNotificationChannel.invokeMethod('updateCustomNotification', {
          'doctorName': doctorName,
          'timeInfo': timeInfoText,
          'expectedTime': formattedExpectedTime,
          'currentToken': runningToken,
          'userToken': userToken,
          'hospitalName': hospitalName,
        });

        log('✅ Custom native notification/Live Activity updated');
        return; // Exit early, native notification handles it
      } catch (e) {
        log('⚠️ Failed to update custom notification (falling back to default): $e');
        // Fall through to default notification
      }
    }

    // Otherwise update existing notification (iOS or fallback)
    await showAppointmentNotification(
      appointment: appointment,
      currentRunningToken: currentRunningToken,
      doctorName: doctorName,
      hospitalName: hospitalName,
      appointmentTime: appointmentTime,
    );
  }

  /// Dismiss the lock screen notification
  /// @description Removes the persistent notification when appointment is completed or cancelled
  static Future<void> dismissNotification() async {
    try {
      // Try native dismiss first (Android & iOS)
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await _customNotificationChannel.invokeMethod('dismissCustomNotification');
          log('✅ Custom native notification/Live Activity dismissed');
        } catch (e) {
          log('⚠️ Failed to dismiss custom notification, using default: $e');
        }
      }
      
      // Also dismiss default notification
      await _plugin.cancel(_notificationId);
      _currentAppointmentId = null;
      log('Lock screen notification dismissed');
    } catch (e) {
      log('Error dismissing lock screen notification: $e');
    }
  }

  /// Handle notification tap
  /// @description Called when user taps on the notification
  static void _onNotificationTapped(NotificationResponse response) {
    log('Notification tapped: ${response.payload}');
    // You can navigate to appointment details screen here
    // Example: EcliniqRouter.push(AppointmentDetailsScreen(appointmentId: ...));
  }

  /// Check if notification is currently showing
  /// @returns true if notification is active
  static bool isNotificationActive() {
    return _currentAppointmentId != null;
  }

  /// Get current appointment ID being tracked
  /// @returns appointment ID or null
  static String? getCurrentAppointmentId() {
    return _currentAppointmentId;
  }

  /// Check iOS notification permissions status
  /// @description Returns detailed permission status for debugging
  /// @returns Map with permission status details
  static Future<Map<String, dynamic>> checkIOSPermissions() async {
    if (!Platform.isIOS) {
      return {'platform': 'android', 'message': 'Not iOS device'};
    }

    try {
      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosImplementation == null) {
        return {'error': 'iOS implementation not available'};
      }

      final permissions = await iosImplementation.checkPermissions();

      if (permissions == null) {
        return {
          'platform': 'ios',
          'error': 'Permissions check returned null',
          'message': 'Unable to check permissions ⚠️',
        };
      }

      return {
        'platform': 'ios',
  
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
