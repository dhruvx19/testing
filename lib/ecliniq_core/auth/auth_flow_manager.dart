import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';


class AuthFlowManager {
  static Future<String> getInitialRoute() async {
    try {
      final hasValidSession = await SessionService.hasValidSession();

      if (hasValidSession) {
        final isOnboardingComplete =
            await SessionService.isOnboardingComplete();

        if (isOnboardingComplete) {
          SessionService.clearFlowState();
          return 'login';
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
          
          if (savedFlowState == 'phone_input' || savedFlowState == 'otp') {
            return 'onboarding'; 
          } else if (savedFlowState == 'mpin_setup' ||
              savedFlowState == 'biometric_setup') {
            return 'onboarding'; 
          } else if (savedFlowState == 'onboarding') {
            return 'onboarding'; 
          }
        }
      }

      if (isFirstLaunch) {
        Future.wait([
          SecureStorageService.deleteMPIN(),
          SecureStorageService.setBiometricEnabled(false),
          SessionService.clearFlowState(),
        ]);

        // If user was previously identified as existing, go to login instead of onboarding
        final isExisting = await SecureStorageService.isExistingUser();
        if (isExisting) {
          return 'login';
        }
        
        return 'onboarding';
      }

      final isExisting = await SecureStorageService.isExistingUser();
      if (hasMPIN || isExisting) {
        // If they have an MPIN or were identified as existing, go to login
        return 'login';
      } else {
        return 'onboarding';
      }
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
