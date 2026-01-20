import 'package:ecliniq/ecliniq_core/auth/auth_flow_manager.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/onboarding_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/home_screen.dart';
import 'package:flutter/material.dart';

/// Splash screen that displays the app logo and handles initial navigation
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

  /// Determines the initial route and navigates to the appropriate screen
  Future<void> _navigateToNextScreen() async {
    // Wait for a minimum splash duration (optional - for better UX)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      // Determine the initial route based on auth state
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

      // Navigate to the determined screen
      if (mounted) {
        EcliniqRouter.pushReplacement(nextScreen!);
      }
    } catch (e) {
      // On error, navigate to welcome screen
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

  /// Builds the splash logo widget
  Widget _buildLogo() {
    // Try to use splash screen logo, fallback to main logo
    try {
      // Check if splash screen logo exists, otherwise use main logo
      return Image.asset(
        EcliniqIcons.splashScreenLogo.assetPath,
        width: 290,
        height: 290,
      );
    } catch (e) {
      // Fallback to main logo
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
