import 'dart:developer';

import 'package:ecliniq/ecliniq_api/models/appointment.dart' as api_models;
import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/notifications/appointment_lock_screen_notification.dart';

/// Helper service for showing appointment lock screen notifications
/// @description Provides easy-to-use methods to show and manage appointment notifications
class AppointmentNotificationHelper {
  /// Show lock screen notification after booking an appointment
  /// @description Fetches appointment details and displays lock screen notification
  /// @param appointmentId - The appointment ID to track
  /// @param currentRunningToken - Optional current running token (if available)
  static Future<void> showNotificationAfterBooking({
    required String appointmentId,
    int? currentRunningToken,
  }) async {
    try {
      // Get auth token
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        log('Auth token not available for showing appointment notification');
        return;
      }

      // Fetch appointment details
      final appointmentService = AppointmentService();
      final appointmentDetailResponse =
          await appointmentService.getAppointmentDetail(
        appointmentId: appointmentId,
        authToken: authToken,
      );

      if (!appointmentDetailResponse.success ||
          appointmentDetailResponse.data == null) {
        log('Failed to fetch appointment details for notification');
        return;
      }

      final appointmentDetail = appointmentDetailResponse.data!;
      final doctor = appointmentDetail.doctor;
      final location = appointmentDetail.location;
      final schedule = appointmentDetail.schedule;

      // Create appointment data
      final appointmentData = api_models.AppointmentData(
        id: appointmentDetail.appointmentId,
        patientId: appointmentDetail.patient.name,
        bookedFor: appointmentDetail.bookedFor,
        doctorId: doctor.userId,
        doctorSlotScheduleId: schedule.date.toIso8601String(),
        tokenNo: appointmentDetail.tokenNo ?? 0,
        status: appointmentDetail.status,
        createdAt: appointmentDetail.createdAt,
        updatedAt: appointmentDetail.updatedAt,
      );

      // Show lock screen notification
      await AppointmentLockScreenNotification.showAppointmentNotification(
        appointment: appointmentData,
        currentRunningToken: currentRunningToken,
        doctorName: doctor.name,
        hospitalName: location.name,
        appointmentTime: schedule.startTime,
      );

      log('Lock screen notification shown for appointment: $appointmentId');
    } catch (e) {
      log('Error showing appointment notification: $e');
    }
  }

  /// Update lock screen notification with new token information
  /// @description Updates the notification when token status changes
  /// @param appointmentId - The appointment ID being tracked
  /// @param currentRunningToken - New current running token from backend
  static Future<void> updateNotificationWithToken({
    required String appointmentId,
    int? currentRunningToken,
  }) async {
    try {
      // Get auth token
      final authToken = await SessionService.getAuthToken();
      if (authToken == null) {
        log('Auth token not available for updating appointment notification');
        return;
      }

      // Fetch appointment details
      final appointmentService = AppointmentService();
      final appointmentDetailResponse =
          await appointmentService.getAppointmentDetail(
        appointmentId: appointmentId,
        authToken: authToken,
      );

      if (!appointmentDetailResponse.success ||
          appointmentDetailResponse.data == null) {
        log('Failed to fetch appointment details for notification update');
        return;
      }

      final appointmentDetail = appointmentDetailResponse.data!;
      final doctor = appointmentDetail.doctor;
      final location = appointmentDetail.location;
      final schedule = appointmentDetail.schedule;

      // Create appointment data
      final appointmentData = api_models.AppointmentData(
        id: appointmentDetail.appointmentId,
        patientId: appointmentDetail.patient.name,
        bookedFor: appointmentDetail.bookedFor,
        doctorId: doctor.userId,
        doctorSlotScheduleId: schedule.date.toIso8601String(),
        tokenNo: appointmentDetail.tokenNo ?? 0,
        status: appointmentDetail.status,
        createdAt: appointmentDetail.createdAt,
        updatedAt: appointmentDetail.updatedAt,
      );

      // Update lock screen notification
      await AppointmentLockScreenNotification.updateNotification(
        appointment: appointmentData,
        currentRunningToken: currentRunningToken,
        doctorName: doctor.name,
        hospitalName: location.name,
        appointmentTime: schedule.startTime,
      );

      log('Lock screen notification updated for appointment: $appointmentId');
    } catch (e) {
      log('Error updating appointment notification: $e');
    }
  }

  /// Dismiss the lock screen notification
  /// @description Call this when appointment is completed or cancelled
  static Future<void> dismissNotification() async {
    await AppointmentLockScreenNotification.dismissNotification();
  }

  /// Check if notification is currently active
  /// @returns true if notification is showing
  static bool isNotificationActive() {
    return AppointmentLockScreenNotification.isNotificationActive();
  }
}

