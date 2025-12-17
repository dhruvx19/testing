import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/user_details.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

class BiometricSetupPage extends StatefulWidget {
  const BiometricSetupPage({super.key});

  @override
  _BiometricSetupPageState createState() => _BiometricSetupPageState();
}

class _BiometricSetupPageState extends State<BiometricSetupPage> 
    with TickerProviderStateMixin {
  bool _isBiometricAvailable = false;
  bool _isLoading = true;
  bool _isEnabling = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkBiometricAvailability();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await BiometricService.isAvailable();
      
      setState(() {
        _isBiometricAvailable = available;
        _isLoading = false;
      });
      
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _isBiometricAvailable = false;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isEnabling = true);
    
    try {
      // Get MPIN from storage
      final mpin = await SecureStorageService.getMPIN();
      
      if (mpin == null || mpin.isEmpty) {
        _showErrorSnackBar('MPIN not found. Please set up MPIN first.');
        setState(() => _isEnabling = false);
        return;
      }

      // Store MPIN with biometric protection
      final success = await SecureStorageService.storeMPINWithBiometric(mpin);
      
      if (success) {
        HapticFeedback.heavyImpact();
        
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        _showErrorSnackBar('Failed to enable biometric authentication. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to enable biometric authentication.');
    } finally {
      if (mounted) {
        setState(() => _isEnabling = false);
      }
    }
  }

  void _showSuccessDialog() {
    // Check if we came from login page (for setting up biometric)
    final cameFromLogin = Navigator.of(context).canPop();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              '${BiometricService.getBiometricTypeName()} Enabled!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can now use biometric authentication to access your account quickly and securely.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // If we came from login page, go back to login
              // Otherwise, continue with normal flow (always go to user details for new user)
              if (cameFromLogin) {
                Navigator.of(context).pop(); // Go back to login
              } else {
                // Normal flow: After biometric setup, always go to user details page
                _navigateToUserDetails();
              }
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToUserDetails() {
    if (!mounted) return;
    EcliniqRouter.pushAndRemoveUntil(
      const UserDetails(),
      (route) => route.isFirst,
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return EcliniqScaffold(
      backgroundColor: EcliniqScaffold.primaryBlue,
      body: SafeArea(
        child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EcliniqLoader(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Checking biometric availability...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: _isBiometricAvailable
                    ? _buildBiometricAvailable()
                    : _buildBiometricUnavailable(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Biometric Setup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBiometricAvailable() {
    final biometricName = BiometricService.getBiometricTypeName();
    final biometricIcon = BiometricService.getBiometricIcon();
    
    return Column(
      children: [
        const SizedBox(height: 40),
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              biometricIcon,
              size: 64,
              color: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Enable $biometricName',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Use your ${biometricName.toLowerCase()} to quickly and securely access your account without entering your M-PIN every time.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isEnabling ? null : _enableBiometric,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isEnabling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: EcliniqLoader(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Enable $biometricName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            onPressed: _navigateToUserDetails,
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Skip for now',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricUnavailable() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security,
            size: 64,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Biometric Not Available',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your device doesn\'t support biometric authentication or it hasn\'t been set up yet. You can enable it later in your device settings.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _navigateToUserDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: EcliniqScaffold.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}


