import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ecliniq/ecliniq_core/notifications/appointment_notification_test_helper.dart';
import 'package:ecliniq/ecliniq_core/notifications/appointment_lock_screen_notification.dart';

/// Test widget for appointment lock screen notifications
/// @description Add this widget to any screen for quick testing
/// 
/// Usage:
/// ```dart
/// TestNotificationWidget()
/// ```
class TestNotificationWidget extends StatefulWidget {
  const TestNotificationWidget({super.key});

  @override
  State<TestNotificationWidget> createState() => _TestNotificationWidgetState();
}

class _TestNotificationWidgetState extends State<TestNotificationWidget> {
  bool _isLoading = false;

  Future<void> _testNotification(String testName, Future<void> Function() test) async {
    setState(() => _isLoading = true);
    try {
      await test();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $testName completed! Check lock screen.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Test Lock Screen Notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _testNotification(
                      'Queue Not Started',
                      () => AppointmentNotificationTestHelper.testShowNotification(
                        userToken: 76,
                        currentRunningToken: 0,
                      ),
                    ),
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Test: Queue Not Started'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _testNotification(
                      'Tokens Ahead',
                      () => AppointmentNotificationTestHelper.testShowNotification(
                        userToken: 76,
                        currentRunningToken: 45,
                      ),
                    ),
                    icon: const Icon(Icons.queue),
                    label: const Text('Test: Tokens Ahead (31)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _testNotification(
                      'Your Turn',
                      () => AppointmentNotificationTestHelper.testUpdateNotification(
                        userToken: 76,
                        newRunningToken: 76,
                      ),
                    ),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Test: Your Turn'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _testNotification(
                      'Update Token',
                      () => AppointmentNotificationTestHelper.testUpdateNotification(
                        userToken: 76,
                        newRunningToken: 50,
                      ),
                    ),
                    icon: const Icon(Icons.update),
                    label: const Text('Test: Update Token'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _testNotification(
                      'Dismiss',
                      () => AppointmentNotificationTestHelper.testDismissNotification(),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Test: Dismiss'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _testNotification(
                              'All Tests',
                              () => AppointmentNotificationTestHelper.runAllTests(),
                            ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run All Tests'),
                  ),
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final status = await AppointmentLockScreenNotification
                                    .checkIOSPermissions();
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('iOS Notification Status'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Alert: ${status['alert'] ?? 'Unknown'}'),
                                            Text('Badge: ${status['badge'] ?? 'Unknown'}'),
                                            Text('Sound: ${status['sound'] ?? 'Unknown'}'),
                                            const SizedBox(height: 16),
                                            Text(
                                              status['message'] ?? '',
                                              style: TextStyle(
                                                color: status['allGranted'] == true
                                                    ? Colors.green
                                                    : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Check iOS Permissions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                if (Platform.isIOS) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '📱 iOS Testing Instructions:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. After tapping a test button, IMMEDIATELY:\n'
                              '   • Press Home button (or swipe up) to background app\n'
                              '   • OR press Power button to lock device\n'
                              '2. Wait 2-3 seconds\n'
                              '3. Check lock screen or swipe down for Notification Center\n\n'
                              '⚠️ iOS does NOT show notifications on lock screen when app is in foreground!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '💡 Make sure "Lock Screen" is enabled in Settings → Notifications → Your App',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                } else {
                  return const Text(
                    '💡 Tip: Lock your device to see the notification on lock screen',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

