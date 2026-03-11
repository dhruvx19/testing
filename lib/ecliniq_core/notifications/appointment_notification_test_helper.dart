import 'dart:developer';
import 'dart:io';

import 'package:ecliniq/ecliniq_api/models/appointment.dart' as api_models;
import 'package:ecliniq/ecliniq_core/notifications/appointment_lock_screen_notification.dart';



class AppointmentNotificationTestHelper {
  
  
  
  
  
  
  static Future<void> testShowNotification({
    required int userToken,
    int? currentRunningToken,
    String doctorName = 'Dr. Test Doctor',
    String hospitalName = 'Test Hospital',
  }) async {
    try {
      log('🧪 Testing lock screen notification...');
      log('User Token: $userToken');
      log('Running Token: ${currentRunningToken ?? 0}');
      log('📱 Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      
      if (Platform.isIOS) {
        log('');
        log('📱 iOS TESTING INSTRUCTIONS:');
        log('1. ✅ Make sure notification permissions are granted');
        log('2. ✅ Go to Settings → Notifications → Your App');
        log('3. ✅ Enable "Allow Notifications"');
        log('4. ✅ Enable "Lock Screen"');
        log('5. ✅ After tapping test button, IMMEDIATELY:');
        log('   - Press Home button (or swipe up) to background the app');
        log('   - OR press Power button to lock device');
        log('6. ✅ Wait 2-3 seconds');
        log('7. ✅ Check lock screen or swipe down for Notification Center');
        log('');
        log('⚠️ IMPORTANT: iOS does NOT show notifications on lock screen when app is in foreground!');
        log('⚠️ You MUST background the app or lock the device to see it on lock screen');
        log('');
      } else {
        log('💡 Lock your device to see the notification on lock screen');
      }

      final appointmentData = api_models.AppointmentData(
        id: 'test-appointment-${DateTime.now().millisecondsSinceEpoch}',
        patientId: 'test-patient',
        bookedFor: 'SELF',
        doctorId: 'test-doctor',
        doctorSlotScheduleId: 'test-slot',
        tokenNo: userToken,
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await AppointmentLockScreenNotification.showAppointmentNotification(
        appointment: appointmentData,
        currentRunningToken: currentRunningToken,
        doctorName: doctorName,
        hospitalName: hospitalName,
        appointmentTime: DateTime.now().add(const Duration(hours: 2)),
      );

      log('✅ Test notification shown successfully!');
      log('📱 Check your lock screen to see the notification');
    } catch (e) {
      log('❌ Error showing test notification: $e');
      rethrow;
    }
  }

  
  
  static Future<void> testUpdateNotification({
    required int userToken,
    required int newRunningToken,
    String doctorName = 'Dr. Test Doctor',
    String hospitalName = 'Test Hospital',
  }) async {
    try {
      log('🧪 Testing notification update...');
      log('User Token: $userToken');
      log('New Running Token: $newRunningToken');

      final appointmentData = api_models.AppointmentData(
        id: AppointmentLockScreenNotification.getCurrentAppointmentId() ??
            'test-appointment-${DateTime.now().millisecondsSinceEpoch}',
        patientId: 'test-patient',
        bookedFor: 'SELF',
        doctorId: 'test-doctor',
        doctorSlotScheduleId: 'test-slot',
        tokenNo: userToken,
        status: 'CONFIRMED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await AppointmentLockScreenNotification.updateNotification(
        appointment: appointmentData,
        currentRunningToken: newRunningToken,
        doctorName: doctorName,
        hospitalName: hospitalName,
        appointmentTime: DateTime.now().add(const Duration(hours: 2)),
      );

      log('✅ Test notification updated successfully!');
    } catch (e) {
      log('❌ Error updating test notification: $e');
      rethrow;
    }
  }

  
  static Future<void> testDismissNotification() async {
    try {
      log('🧪 Testing notification dismissal...');
      await AppointmentLockScreenNotification.dismissNotification();
      log('✅ Test notification dismissed successfully!');
    } catch (e) {
      log('❌ Error dismissing test notification: $e');
      rethrow;
    }
  }

  
  static Future<void> runAllTests({
    String doctorName = 'Dr. Milind Chauhan',
    String hospitalName = 'eClinic-Q',
  }) async {
    log('🧪 Starting comprehensive notification tests...\n');

    try {
      
      log('Test 1: Queue not started');
      await testShowNotification(
        userToken: 76,
        currentRunningToken: 0,
        doctorName: doctorName,
        hospitalName: hospitalName,
      );
      await Future.delayed(const Duration(seconds: 3));

      
      log('\nTest 2: Tokens ahead');
      await testUpdateNotification(
        userToken: 76,
        newRunningToken: 45,
        doctorName: doctorName,
        hospitalName: hospitalName,
      );
      await Future.delayed(const Duration(seconds: 3));

      
      log('\nTest 3: Your turn');
      await testUpdateNotification(
        userToken: 76,
        newRunningToken: 76,
        doctorName: doctorName,
        hospitalName: hospitalName,
      );
      await Future.delayed(const Duration(seconds: 3));

      
      log('\nTest 4: Dismiss notification');
      await testDismissNotification();

      log('\n✅ All tests completed successfully!');
    } catch (e) {
      log('\n❌ Test failed: $e');
    }
  }
}

