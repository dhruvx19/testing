import 'dart:developer';
import 'dart:io';

import 'package:ecliniq/ecliniq_api/models/appointment.dart' as api_models;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';



class AppointmentLockScreenNotification {
  static const int _notificationId =
      9999; 
  static const String _channelId = 'appointment_tracking';
  static const String _channelName = 'Appointment Tracking';
  static const String _channelDescription =
      'Real-time appointment token updates';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _currentAppointmentId;
  
  
  static const MethodChannel _customNotificationChannel =
      MethodChannel('com.example.ecliniq/custom_notifications');

  
  
  static Future<void> init() async {
    if (_initialized) return;

    try {
      
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      
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

      
      if (Platform.isAndroid) {
        await _createAndroidChannel();
      }

      _initialized = true;
      log('Appointment lock screen notification service initialized');
    } catch (e) {
      log('Error initializing lock screen notification: $e');
    }
  }

  
  static Future<void> _createAndroidChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high, 

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

  
  
  
  
  
  
  
  
  static Future<void> showAppointmentNotification({
    required api_models.AppointmentData appointment,
    int? currentRunningToken,
    required String doctorName,
    required String hospitalName,
    required DateTime appointmentTime,
  }) async {
    try {
      await init();

      
      if (Platform.isAndroid) {
        
        try {
          final androidImplementation = _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          if (androidImplementation != null) {
            
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

      
      final estimatedMinutes = tokensAhead != null ? tokensAhead * 2 : 0;

      
      final timeFormat = DateFormat('h:mm a');
      final formattedExpectedTime = timeFormat.format(appointmentTime);

      
      
      final title = 'Your Appointment with';
      String body;
      String subtitle;

      
      
      
      String tokenProgressLine = '';
      String tokenLabelsLine = '';
      
      if (runningToken > 0) {
        
        final _ = userToken > runningToken ? userToken : (runningToken + 5);
        final startToCurrent = runningToken;
        final currentToYour = userToken > runningToken ? (userToken - runningToken) : 0;
        
        
        tokenProgressLine = 'S';
        
        if (startToCurrent > 0) {
          final progressLength = startToCurrent > 10 ? 8 : startToCurrent;
          tokenProgressLine += ' ${'─' * progressLength} ';
        }
        tokenProgressLine += '$runningToken';
        
        if (currentToYour > 0) {
          final progressLength = currentToYour > 10 ? 8 : currentToYour;
          tokenProgressLine += ' ${'─' * progressLength} ';
        }
        tokenProgressLine += '$userToken';
        
        
        tokenLabelsLine = 'Start';
        final startSpacing = runningToken > 10 ? '    ' : '   ';
        tokenLabelsLine += startSpacing;
        tokenLabelsLine += 'Current';
        final currentSpacing = currentToYour > 10 ? '    ' : '   ';
        tokenLabelsLine += currentSpacing;
        tokenLabelsLine += 'Your No.';
      }

      if (runningToken == 0) {
        
        body = '$doctorName\nQueue';
        subtitle = 'Expected Time: $formattedExpectedTime';
      } else if (tokensAhead != null && tokensAhead > 0) {
        
        body = '$doctorName\nin $estimatedMinutes min';
        subtitle = 'Expected Time: $formattedExpectedTime\n'
            '$tokenProgressLine\n$tokenLabelsLine';
      } else if (userToken == runningToken) {
        
        body = '$doctorName\n🎉 Your turn!';
        subtitle = 'Expected Time: $formattedExpectedTime';
      } else if (userToken < runningToken) {
        
        body = '$doctorName\nYour token has been called';
        subtitle = 'Expected Time: $formattedExpectedTime';
      } else {
        
        body = '$doctorName';
        subtitle = 'Expected Time: $formattedExpectedTime\n'
            '$tokenProgressLine\n$tokenLabelsLine';
      }

      
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          
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
          return; 
        } catch (e) {
          log('⚠️ Failed to show custom native notification (falling back to default): $e');
          
        }
      }

      
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true, 
        autoCancel: false, 
        showWhen: false,
        
        styleInformation: BigTextStyleInformation(
          '$body\n\n$subtitle',
          contentTitle: title,
          summaryText: hospitalName,
          htmlFormatContent: false,
        ),
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public, 
        fullScreenIntent: false,
        color: const Color(0xFF0066CC), 
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      
      
      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel
            .timeSensitive, 
        threadIdentifier: 'appointment_${appointment.id}',
        categoryIdentifier: 'APPOINTMENT_TRACKING',
        subtitle: subtitle, 
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

  
  
  
  
  
  
  
  static Future<void> updateNotification({
    required api_models.AppointmentData appointment,
    int? currentRunningToken,
    required String doctorName,
    required String hospitalName,
    required DateTime appointmentTime,
  }) async {
    
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
        return; 
      } catch (e) {
        log('⚠️ Failed to update custom notification (falling back to default): $e');
        
      }
    }

    
    await showAppointmentNotification(
      appointment: appointment,
      currentRunningToken: currentRunningToken,
      doctorName: doctorName,
      hospitalName: hospitalName,
      appointmentTime: appointmentTime,
    );
  }

  
  
  static Future<void> dismissNotification() async {
    try {
      
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          await _customNotificationChannel.invokeMethod('dismissCustomNotification');
          log('✅ Custom native notification/Live Activity dismissed');
        } catch (e) {
          log('⚠️ Failed to dismiss custom notification, using default: $e');
        }
      }
      
      
      await _plugin.cancel(_notificationId);
      _currentAppointmentId = null;
      log('Lock screen notification dismissed');
    } catch (e) {
      log('Error dismissing lock screen notification: $e');
    }
  }

  
  
  static void _onNotificationTapped(NotificationResponse response) {
    log('Notification tapped: ${response.payload}');
    
    
  }

  
  
  static bool isNotificationActive() {
    return _currentAppointmentId != null;
  }

  
  
  static String? getCurrentAppointmentId() {
    return _currentAppointmentId;
  }

  
  
  
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
