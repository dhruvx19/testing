import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';


class AuthFlowManager {
  static Future<String> getInitialRoute() async {
    try {
      final results = await Future.wait([
        SessionService.hasValidSession(),
        SessionService.isOnboardingComplete(),
        SessionService.isFirstLaunch(),
        SecureStorageService.hasMPIN(),
        SecureStorageService.isExistingUser(),
      ]);

      final hasValidSession = results[0] as bool;
      final isOnboardingComplete = results[1] as bool;
      final isFirstLaunch = results[2] as bool;
      final hasMPIN = results[3] as bool;
      final isExisting = results[4] as bool;

      // 1. Fresh install/First launch ALWAYS goes to onboarding
      if (isFirstLaunch) {
        Future.wait([
          SecureStorageService.deleteMPIN(),
          SecureStorageService.setBiometricEnabled(false),
          SessionService.clearFlowState(),
        ]);
        return 'onboarding';
      }

      // 2. If logged in and onboarding is finished, go home (re-login screen for security)
      if (hasValidSession && isOnboardingComplete) {
        SessionService.clearFlowState();
        return 'login';
      }

      // 3. If onboarding was completed before, OR user has MPIN, OR identified as existing
      // Skip onboarding and go to login/mpin
      if (isOnboardingComplete || hasMPIN || isExisting) {
        return 'login';
      }

      // 4. Default to saved flow state or onboarding
      final savedFlowState = await SessionService.getFlowState();
      if (savedFlowState != null && savedFlowState.isNotEmpty) {
        if ([
          'phone_input',
          'otp',
          'mpin_setup',
          'biometric_setup',
          'onboarding',
        ].contains(savedFlowState)) {
          return 'onboarding';
        }
      }

      return 'onboarding';
    } catch (e) {
      return 'onboarding';
    }
  }

  
  
  static Future<bool> isUserRegistered() async {
    
    return false;
  }

  
  static Future<bool> isUserAuthenticated() async {
    try {
      return await SessionService.hasValidSession();
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> isOnboardingComplete() async {
    try {
      return await SessionService.isOnboardingComplete();
    } catch (e) {
      return false;
    }
  }
}
