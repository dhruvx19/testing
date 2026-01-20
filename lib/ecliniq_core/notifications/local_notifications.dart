import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> showDownloadSuccess({
    required String fileName,
  }) async {
    await init();

    // Create notification channel for Android (required for Android 8.0+)
    const androidChannel = AndroidNotificationChannel(
      'downloads_channel',
      'Downloads',
      description: 'Notifications for file downloads',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create the channel (idempotent - safe to call multiple times)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const androidDetails = AndroidNotificationDetails(
      'downloads_channel',
      'Downloads',
      channelDescription: 'Notifications for file downloads',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use timestamp as ID to show multiple download notifications
    final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;

    await _plugin.show(
      notificationId,
      'Download complete',
      fileName,
      details,
    );
  }
}
