import 'package:ecliniq/ecliniq_core/auth/auth_flow_manager.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/onboarding_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  
  Future<void> _navigateToNextScreen() async {
    
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      // 1. Try biometric login if enabled
      final isBiometricEnabled = await SecureStorageService.isBiometricEnabled();
      if (isBiometricEnabled && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.loginWithBiometric();
        
        if (success && mounted) {
          EcliniqRouter.pushReplacement(const HomeScreen());
          return;
        }
      }
      
      // 2. Fallback to normal flow
      final initialRoute = await AuthFlowManager.getInitialRoute();

      Widget? nextScreen;
      switch (initialRoute) {
        case 'onboarding':
          nextScreen = const EcliniqWelcomeScreen();
          break;
        case 'login':
          nextScreen = const LoginPage();
          break;
        case 'home':
          nextScreen = const HomeScreen();
          break;
        default:
          nextScreen = const EcliniqWelcomeScreen();
      }

      
      if (mounted) {
        EcliniqRouter.pushReplacement(nextScreen);
      }
    } catch (e) {
      
      if (mounted) {
        EcliniqRouter.pushReplacement(const EcliniqWelcomeScreen());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: _buildLogo()),
    );
  }

  
  Widget _buildLogo() {
    
    try {
      
      return Image.asset(
        EcliniqIcons.splashScreenLogo.assetPath,
        width: 290,
        height: 290,
      );
    } catch (e) {
      
      return Image.asset(
        EcliniqIcons.main.assetPath,
        width: 200,
        height: 200,
        fit: BoxFit.contain,
        cacheWidth: 400,
        cacheHeight: 400,
      );
    }
  }
}
