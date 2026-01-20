import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';

/// Manages authentication flow and determines which screen to show
class AuthFlowManager {
  static Future<String> getInitialRoute() async {
    try {
      final hasValidSession = await SessionService.hasValidSession();

      if (hasValidSession) {
        final isOnboardingComplete =
            await SessionService.isOnboardingComplete();

        if (isOnboardingComplete) {
          SessionService.clearFlowState();
          return 'home';
        } else {
          return 'onboarding';
        }
      }

      final results = await Future.wait([
        SessionService.getFlowState(),
        SessionService.isFirstLaunch(),
        SecureStorageService.hasMPIN(),
      ]);

      final savedFlowState = results[0] as String?;
      final isFirstLaunch = results[1] as bool;
      final hasMPIN = results[2] as bool;

      if (savedFlowState != null && savedFlowState.isNotEmpty) {
        if ([
          'phone_input',
          'otp',
          'mpin_setup',
          'biometric_setup',
          'onboarding',
        ].contains(savedFlowState)) {
          // Map flow states to routes
          if (savedFlowState == 'phone_input' || savedFlowState == 'otp') {
            return 'onboarding'; // Start from welcome/phone input
          } else if (savedFlowState == 'mpin_setup' ||
              savedFlowState == 'biometric_setup') {
            return 'onboarding'; // Start from welcome/phone input
          } else if (savedFlowState == 'onboarding') {
            return 'onboarding'; // Resume onboarding
          }
        }
      }

      if (isFirstLaunch) {
        Future.wait([
          SecureStorageService.deleteMPIN(),
          SecureStorageService.setBiometricEnabled(false),
          SessionService.clearFlowState(),
        ]);

        // Always show welcome screen for first launch (new user flow)
        return 'onboarding';
      }

      if (hasMPIN) {
        // Returning user with MPIN - show login page
        return 'login';
      } else {
        // User without MPIN - show welcome/onboarding screen
        return 'onboarding';
      }
    } catch (e) {
      // On error, default to onboarding
      return 'onboarding';
    }
  }

  /// Check if user is registered
  /// NOTE: MPIN check removed - always returns false
  static Future<bool> isUserRegistered() async {
    // No-op: UI only, always returns false
    return false;
  }

  /// Check if user is authenticated (has valid session)
  static Future<bool> isUserAuthenticated() async {
    try {
      return await SessionService.hasValidSession();
    } catch (e) {
      return false;
    }
  }

  /// Check if onboarding is complete
  static Future<bool> isOnboardingComplete() async {
    try {
      return await SessionService.isOnboardingComplete();
    } catch (e) {
      return false;
    }
  }
}
