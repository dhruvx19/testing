import 'dart:async';
import 'dart:math';

import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/home_screen.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/phone_input.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login_trouble.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/action_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class CardHoleClipper extends CustomClipper<Path> {
  final double radius;
  final double centerYOffset;

  CardHoleClipper({required this.radius, required this.centerYOffset});

  @override
  Path getClip(Size size) {
    final Path outer = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(18),
        ),
      );
    final Offset center = Offset(size.width / 2, centerYOffset);
    final Path hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(PathOperation.difference, outer, hole);
  }

  @override
  bool shouldReclip(covariant CardHoleClipper oldClipper) {
    return oldClipper.radius != radius ||
        oldClipper.centerYOffset != centerYOffset;
  }
}

class TopEdgePainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;
  final double holeRadius;
  final double holeCenterYOffset;
  final double cornerRadius;
  final double bandHeight;

  TopEdgePainter({
    required this.leftColor,
    required this.rightColor,
    required this.holeRadius,
    required this.holeCenterYOffset,
    this.cornerRadius = 18.0,
    this.bandHeight = 36.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 1.6;
    final outer = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(cornerRadius),
        ),
      );
    final center = Offset(size.width / 2, holeCenterYOffset);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: holeRadius));
    final cardPath = Path.combine(PathOperation.difference, outer, hole);

    final bandHeightLocal = (strokeWidth * 3).clamp(2.0, 12.0);
    final clipHeight = max(bandHeightLocal, holeRadius + center.dy);

    final gradient = LinearGradient(colors: [leftColor, rightColor]);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, clipHeight),
      );

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipHeight));
    canvas.drawPath(cardPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TopEdgePainter oldDelegate) {
    return oldDelegate.leftColor != leftColor ||
        oldDelegate.rightColor != rightColor ||
        oldDelegate.holeRadius != holeRadius ||
        oldDelegate.holeCenterYOffset != holeCenterYOffset;
  }
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  bool _showPin = false;
  String _entered = '';
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _showMPINScreen =
      false; // Track if we should show MPIN screen or phone input
  bool _isOTPMode = false; // Track if OTP mode is active
  String _phoneNumber = ''; // Store phone number for MPIN verification
  bool _isButtonPressed = false; // Track button press state
  bool _isOTPButtonPressed = false; // Track OTP button press state
  bool _userExplicitlyChoseMPIN =
      false; // Track if user explicitly chose MPIN (don't auto-trigger biometric)
  bool _showLoadingOverlay = false; // Track if loading overlay should be shown
  String? _userName; // Store user's name for welcome message
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _mpinSubmitTimer;

  /// Getter to check if button should be enabled based on phone number validity
  bool get isButtonEnabled => _phoneNumber.length == 10 && !_isLoading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(_onMPINChanged);
    _phoneController.addListener(_onPhoneNumberChanged);
    // Reset loading state when page is initialized
    _isLoading = false;
    // Optimize: Defer heavy operations to post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load saved phone number and pre-fill
      await _loadSavedPhoneNumber();
      // Load user name from JWT token
      await _loadUserName();
      // Check biometric availability
      await _checkBiometricAvailability();

      // Don't auto-trigger biometric - user must explicitly click the button
    });
  }

  /// Load saved phone number from secure storage and pre-fill the input
  Future<void> _loadSavedPhoneNumber() async {
    try {
      final savedPhone = await SecureStorageService.getPhoneNumber();
      if (savedPhone != null && savedPhone.isNotEmpty && mounted) {
        // Remove country code if present (e.g., +91 or 91)
        String phoneNumber = savedPhone
            .replaceAll(RegExp(r'^\+?91'), '')
            .trim();
        if (phoneNumber.length == 10) {
          _phoneController.text = phoneNumber;
          setState(() {
            _phoneNumber = phoneNumber;
          });
        }
      }
    } catch (e) {}
  }

  /// Load user name from secure storage
  Future<void> _loadUserName() async {
    try {
      final name = await SecureStorageService.getUserName();
      if (name != null && name.isNotEmpty && mounted) {
        setState(() {
          _userName = name.trim();
        });
      }
    } catch (e) {
      // Silently fail - name is optional
    }
  }

  void _onPhoneNumberChanged() {
    final phone = _phoneController.text.trim();
    setState(() {
      _phoneNumber = phone;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Re-check biometric availability when app comes to foreground
    // This helps if user enabled biometric in device settings while app was in background
    if (state == AppLifecycleState.resumed && mounted) {
      _checkBiometricAvailability();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset loading state when dependencies change (e.g., when navigating back)
    if (_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _onMPINChanged() {
    final v = _textController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (v.length > 4) {
      _textController.text = v.substring(0, 4);
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: 4),
      );
      return;
    }

    // Update UI without full setState for better performance
    if (_entered != v) {
      setState(() {
        _entered = v;
        // Reset show PIN when PIN is cleared
        if (v.isEmpty) {
          _showPin = false;
          // Hide loader if user clears MPIN
          _isLoading = false;
          _showLoadingOverlay = false;
        }
      });
    }

    // Cancel previous timer
    _mpinSubmitTimer?.cancel();

    // Auto-submit immediately when 4 digits entered
    if (v.length == 4) {
      // Show loader immediately when user enters 4th digit
      setState(() {
        _isLoading = true;
        _showLoadingOverlay = true;
      });

      // Use microtask to ensure UI updates first, then submit immediately
      _mpinSubmitTimer = Timer(Duration.zero, () {
        if (mounted) {
          _handleMPINLogin(v);
        }
      });
    }
  }

  void _onOTPChanged(String value) {
    final v = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (v.length > 6) {
      _otpController.text = v.substring(0, 6);
      _otpController.selection = TextSelection.fromPosition(
        TextPosition(offset: 6),
      );
      return;
    }

    // Update UI
    if (_entered != v) {
      setState(() {
        _entered = v;
        // Reset show PIN when OTP is cleared
        if (v.isEmpty) {
          _showPin = false;
          _isLoading = false;
          _showLoadingOverlay = false;
        }
      });
    }

    // Cancel previous timer
    _mpinSubmitTimer?.cancel();

    // Auto-submit immediately when 6 digits entered
    if (v.length == 6) {
      // Show loader immediately when user enters 6th digit
      setState(() {
        _isLoading = true;
        _showLoadingOverlay = true;
      });

      // Use microtask to ensure UI updates first, then submit immediately
      _mpinSubmitTimer = Timer(Duration.zero, () {
        if (mounted) {
          _handleOTPLogin(v);
        }
      });
    }
  }

  Future<void> _handleOTPLogin(String otp) async {
    // Ensure we have phone number
    if (_phoneNumber.isEmpty) {
      setState(() {
        _isLoading = false;
        _showLoadingOverlay = false;
      });
      CustomErrorSnackBar.show(
        context: context,
        title: 'Validation Error',
        subtitle: 'Phone number is required',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Verify OTP using the API
      final success = await authProvider.verifyOTP(otp);

      if (mounted) {
        if (success) {
          setState(() {
            _isLoading = false;
          });

          // Check if this is a new user or needs profile setup
          // We might need to redirect to MPIN setup if they don't have one
          // But for now, following existing flow to Home
          
          // Navigate to home screen
          scheduleMicrotask(() {
            if (!mounted) return;
            try {
              final navigator = EcliniqRouter.navigatorKey.currentState;
              if (navigator != null) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
                return;
              }
            } catch (e) {
              try {
                EcliniqRouter.pushAndRemoveUntil(
                  const HomeScreen(),
                  (route) => false,
                );
              } catch (e2) {
                // Handle error
              }
            }
          });
        } else {
          setState(() {
            _isLoading = false;
            _showLoadingOverlay = false;
            _entered = '';
            _otpController.clear();
          });
          CustomErrorSnackBar.show(
            context: context,
            title: 'Authentication Failed',
            subtitle: authProvider.errorMessage ?? 'Invalid OTP',
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showLoadingOverlay = false;
        });
        CustomErrorSnackBar.show(
          context: context,
          title: 'Login Failed',
          subtitle: 'Login failed: ${e.toString()}',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  // Removed _autoTriggerBiometric - biometric only triggers when user explicitly clicks the button

  /// Handle phone number submission - move to MPIN screen
  /// User explicitly chose MPIN, so always show MPIN screen (don't skip to biometric)
  Future<void> _handlePhoneSubmit() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      CustomErrorSnackBar.show(
        context: context,
        title: 'Validation Error',
        subtitle: 'Please enter a valid 10-digit phone number',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Save phone number to secure storage
    await SecureStorageService.storePhoneNumber(phone);

    // Check biometric availability first
    await _checkBiometricAvailability();

    // User explicitly clicked "Login Using MPin", so always show MPIN screen
    // Don't skip to biometric even if it's enabled
    setState(() {
      _phoneNumber = phone;
      _showMPINScreen = true;
      _isOTPMode = false;
      _isLoading = false;
      _userExplicitlyChoseMPIN = true; // Mark that user explicitly chose MPIN
    });

    // Don't auto-trigger biometric when user explicitly chose MPIN
    // User can still use biometric button on MPIN screen if they want
  }

  /// Handle phone number submission - move to OTP screen
  Future<void> _handleOTPPhoneSubmit() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      CustomErrorSnackBar.show(
        context: context,
        title: 'Validation Error',
        subtitle: 'Please enter a valid 10-digit phone number',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showLoadingOverlay = true;
    });

    try {
      // Save phone number to secure storage
      await SecureStorageService.storePhoneNumber(phone);

      // Check biometric availability first
      await _checkBiometricAvailability();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Call API to send OTP
      final success = await authProvider.loginOrRegisterUser(phone);

      if (mounted) {
        if (success) {
          // User explicitly clicked "Login using OTP", so show OTP screen
          setState(() {
            _phoneNumber = phone;
            _showMPINScreen = true;
            _isOTPMode = true;
            _isLoading = false;
            _userExplicitlyChoseMPIN = false;
            _otpController.clear();
          });
        } else {
          setState(() {
             _isLoading = false;
             _showLoadingOverlay = false;
          });
          CustomErrorSnackBar.show(
            context: context,
            title: 'Failed to send OTP',
            subtitle: authProvider.errorMessage ?? 'Please try again',
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showLoadingOverlay = false;
        });
        CustomErrorSnackBar.show(
          context: context,
          title: 'Error',
          subtitle: e.toString(),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await BiometricService.isAvailable();
      final isEnabled = await SecureStorageService.isBiometricEnabled();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
        });
      }
    } catch (e) {
      // On error, still try to show the button if we can't determine availability
      // This is better UX than hiding it completely
      if (mounted) {
        try {
          // Try to get enabled status even if availability check failed
          final isEnabled = await SecureStorageService.isBiometricEnabled();
          setState(() {
            // If biometric was previously enabled, assume it's available
            // This prevents the button from disappearing if check temporarily fails
            _isBiometricAvailable = isEnabled || _isBiometricAvailable;
            _isBiometricEnabled = isEnabled;
          });
        } catch (_) {
          // If everything fails, keep current state
        }
      }
    }
  }

  void _navigateToForgotPin() {
    // Navigate to phone input for forgot PIN flow
    final phoneController = TextEditingController();
    EcliniqRouter.push(
      PhoneInputScreen(
        phoneController: phoneController,
        onClose: () {
          // Reset loading state when coming back
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          EcliniqRouter.pop();
        },
        fadeAnimation: AlwaysStoppedAnimation(1.0),
        isForgotPinFlow: true,
      ),
    );
  }

  void _navigateToCreateNewMPIN() {
    // Navigate to phone input for create new MPIN flow
    // User will set MPIN, then verify with OTP on same number
    final phoneController = TextEditingController();
    EcliniqRouter.push(
      PhoneInputScreen(
        phoneController: phoneController,
        onClose: () {
          // Reset loading state when coming back
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          EcliniqRouter.pop();
        },
        fadeAnimation: AlwaysStoppedAnimation(1.0),
        isForgotPinFlow: false, // Normal flow but will create new MPIN
      ),
    );
  }

  void _navigateToPhoneInputForSessionRenewal() {
    // Navigate to phone input to get new session (MPIN already exists, so will skip MPIN setup)
    final phoneController = TextEditingController();
    // Reset loading state before navigation
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    EcliniqRouter.pushAndRemoveUntil(
      PhoneInputScreen(
        phoneController: phoneController,
        onClose: () {
          // Reset loading state when coming back
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          EcliniqRouter.pop();
        },
        fadeAnimation: AlwaysStoppedAnimation(1.0),
        isForgotPinFlow:
            false, // Normal flow, but MPIN exists so will skip MPIN setup
      ),
      (route) => route.isFirst,
    );
  }

  /// Request biometric permission using native dialog (like location permission)
  /// This will trigger the native biometric permission dialog automatically
  Future<void> _requestBiometricPermission(String mpin) async {
    try {
      // Check if biometric is available
      if (!await BiometricService.isAvailable()) {
        return;
      }

      // Check if already enabled
      if (await SecureStorageService.isBiometricEnabled()) {
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
        return;
      }

      // This will trigger the native biometric permission dialog automatically
      // The native dialog will appear just like location permission dialog
      final success = await SecureStorageService.storeMPINWithBiometric(mpin);

      if (success) {
        // Update local state
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
      } else {
        // User skipped or denied - that's okay, continue without biometric
      }
    } catch (e) {
      // Continue without biometric if permission request fails
    }
  }

  Future<void> _handleMPINLogin(String mpin) async {
    // Ensure we have phone number
    if (_phoneNumber.isEmpty) {
      setState(() {
        _isLoading = false;
        _showLoadingOverlay = false;
      });
      CustomErrorSnackBar.show(
        context: context,
        title: 'Validation Error',
        subtitle: 'Phone number is required',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Loading state and overlay already set when 4th digit was entered

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Phone number is already stored in secure storage, loginWithMPIN will retrieve it
      final success = await authProvider.loginWithMPIN(mpin);

      // Removed debug logging for performance

      if (mounted) {
        if (success) {
          // Keep loading overlay showing (already shown when 4th digit entered)
          setState(() {
            _isLoading = false;
            // _showLoadingOverlay already true from when user entered 4th digit
          });

          // After successful MPIN login, ask for biometric permission if available and not enabled
          // Run in background (non-blocking) so it doesn't delay navigation
          if (_isBiometricAvailable && !_isBiometricEnabled) {
            // Don't await - let it run in background while we navigate
            _requestBiometricPermission(mpin)
                .timeout(
                  const Duration(seconds: 1),
                  onTimeout: () {
                    // Silently timeout
                  },
                )
                .catchError((e) {
                  // Silently handle errors
                });
          }

          // Navigate immediately using microtask for fastest execution
          scheduleMicrotask(() {
            if (!mounted) return;

            try {
              // Use the router's navigator key directly - most reliable method
              final navigator = EcliniqRouter.navigatorKey.currentState;
              if (navigator != null) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
                return;
              }
            } catch (e) {
              // Fallback: Use router method
              try {
                EcliniqRouter.pushAndRemoveUntil(
                  const HomeScreen(),
                  (route) => false,
                );
                return;
              } catch (e2) {
                // Last resort: Use post-frame callback
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    try {
                      final navigator = EcliniqRouter.navigatorKey.currentState;
                      if (navigator != null) {
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e3) {
                      if (mounted) {
                        CustomActionSnackBar.show(
                          context: context,
                          title: 'Navigation Error',
                          subtitle:
                              'Login successful but navigation failed. Please restart the app.',
                          duration: const Duration(seconds: 5),
                        );
                      }
                    }
                  }
                });
              }
            }
          });
        } else {
          // Check if session expired - go back to phone input
          if (authProvider.errorMessage == 'SESSION_EXPIRED') {
            // Reset state and go back to phone input
            setState(() {
              _isLoading = false;
              _showLoadingOverlay = false;
              _entered = '';
              _textController.clear();
              _showMPINScreen = false;
              _userExplicitlyChoseMPIN = false; // Reset flag
            });
            CustomActionSnackBar.show(
              context: context,
              title: 'Session Expired',
              subtitle: 'Please login again',
              duration: const Duration(seconds: 4),
            );
          } else {
            setState(() {
              _isLoading = false;
              _showLoadingOverlay = false;
              _entered = '';
              _textController.clear();
            });
            CustomErrorSnackBar.show(
              context: context,
              title: 'Authentication Failed',
              subtitle: authProvider.errorMessage ?? 'Invalid MPIN',
              duration: const Duration(seconds: 3),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showLoadingOverlay = false;
        });
        CustomErrorSnackBar.show(
          context: context,
          title: 'Login Failed',
          subtitle: 'Login failed: ${e.toString()}',
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      return;
    }

    if (!mounted) return;

    // Show loader immediately when user clicks biometric button
    setState(() {
      _isLoading = true;
      _showLoadingOverlay = true;
    });

    // Check if biometric is actually available before proceeding
    if (!_isBiometricAvailable) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showLoadingOverlay = false;
        });
      }
      CustomErrorSnackBar.show(
        context: context,
        title: 'Biometric Unavailable',
        subtitle: 'Biometric authentication is not available on this device',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (!_isBiometricEnabled) {
      // Get MPIN from storage to enable biometric
      final mpin = await SecureStorageService.getMPIN();
      if (mpin != null && mpin.isNotEmpty) {
        await _requestBiometricPermission(mpin);
        // Re-check if enabled after permission request
        final isEnabled = await SecureStorageService.isBiometricEnabled();
        if (!isEnabled) {
          // User skipped or denied, can't proceed with biometric login
          if (mounted) {
            setState(() {
              _isLoading = false;
              _showLoadingOverlay = false;
            });
          }
          return;
        }
        // Update state and continue with biometric login
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
            // Keep loading overlay showing
          });
        }
      } else {
        // Can't enable biometric without MPIN
        if (mounted) {
          setState(() {
            _isLoading = false;
            _showLoadingOverlay = false;
          });
          CustomErrorSnackBar.show(
            context: context,
            title: 'MPIN Required',
            subtitle: 'MPIN not found. Please login with MPIN first.',
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }
    }

    // Loading state already set when function was called

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Add timeout wrapper to ensure we don't hang forever
      final success = await authProvider.loginWithBiometric().timeout(
        const Duration(
          seconds: 35,
        ), // Slightly longer than auth_provider timeout
        onTimeout: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _showLoadingOverlay = false;
            });
            CustomActionSnackBar.show(
              context: context,
              title: 'Timeout',
              subtitle: 'Biometric authentication timed out. Please try again.',
              duration: const Duration(seconds: 3),
            );
          }
          return false;
        },
      );

      // Always reset loading state first, before any navigation
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!mounted) {
        return;
      }

      if (success) {
        // Keep loading overlay showing (already shown when user clicked button)
        if (mounted) {
          setState(() {
            _isLoading = false;
            // _showLoadingOverlay already true from when user clicked button
          });
        }

        // Navigate immediately using microtask for fastest execution
        scheduleMicrotask(() {
          if (mounted) {
            EcliniqRouter.pushAndRemoveUntil(
              const HomeScreen(),
              (route) => false,
            );
          }
        });
      } else {
        // Hide loading overlay on error
        if (mounted) {
          setState(() {
            _showLoadingOverlay = false;
          });
        }

        // Check if session expired - navigate to phone input
        if (authProvider.errorMessage == 'SESSION_EXPIRED') {
          // Add a small delay to ensure state is reset before navigation
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            _navigateToPhoneInputForSessionRenewal();
          }
        } else {
          // Don't show error if user cancelled biometric
          final errorMsg = authProvider.errorMessage ?? '';

          // Check if it's a cancellation or user error
          final isUserCancellation =
              errorMsg.toLowerCase().contains('cancel') ||
              errorMsg.toLowerCase().contains('cancelled') ||
              errorMsg.toLowerCase().contains('user') ||
              errorMsg.toLowerCase().contains('not available') ||
              errorMsg.toLowerCase().contains('not enabled') ||
              errorMsg.toLowerCase().contains('timeout');

          if (errorMsg.isNotEmpty && !isUserCancellation) {
            if (mounted) {
              CustomErrorSnackBar.show(
                context: context,
                title: 'Error',
                subtitle: errorMsg,
                duration: const Duration(seconds: 3),
              );
            }
          } else if (errorMsg.toLowerCase().contains('not enabled')) {
            // If biometric is not enabled, redirect to setup
            final mpin = await SecureStorageService.getMPIN();
            if (mpin != null && mpin.isNotEmpty) {
              await _requestBiometricPermission(mpin);
              // Re-check availability after permission request
              await _checkBiometricAvailability();
            }
          }
        }
      }
    } catch (e) {
      // Always reset loading state on exception
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showLoadingOverlay = false;
        });

        // Check if it's a timeout exception
        if (e.toString().toLowerCase().contains('timeout')) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          CustomErrorSnackBar.show(
            context: context,
            title: 'Timeout',
            subtitle: 'Biometric authentication timed out. Please try again.',
            duration: const Duration(seconds: 3),
          );
        } else {
          // Only show error for unexpected exceptions
          CustomErrorSnackBar.show(
            context: context,
            title: 'Biometric Login Failed',
            subtitle: 'Biometric login failed: ${e.toString()}',
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  /// Build phone input screen
  Widget _buildPhoneInputScreen() {
    // Calculate spacing: Profile photo bottom is at 59px (-35 + 94)
    // Text should start at 59 + 16 = 75px
    // Content padding is 56px, so we need 75 - 56 = 19px spacing
    final spacingFromPhoto = 16.0;
    final profilePhotoBottom = 59.0; // -35 (top) + 94 (height)
    final contentPaddingTop = 56.0;
    final requiredSpacing = (profilePhotoBottom + spacingFromPhoto) - contentPaddingTop;
    
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: requiredSpacing.clamp(16.0, double.infinity)),
        Text(
          'Enter Your Mobile Number to Login',
          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Phone input field
        Container(
          width: double.infinity,
          height: EcliniqTextStyles.getResponsiveButtonHeight(
            context,
            baseHeight: 56.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xff626060), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Color(0xffD6D6D6), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '+91',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff424242),
                          ),
                    ),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      EcliniqIcons.arrowDown.assetPath,
                      width: 20,
                      height: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  maxLength: 10,
                  decoration: InputDecoration(
                    hintText: 'Mobile Number',
                    hintStyle:
                        EcliniqTextStyles.responsiveHeadlineXMedium(
                          context,
                        ).copyWith(
                          color: Color(0xffD6D6D6),
                          fontWeight: FontWeight.w400,
                        ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding:
                        EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                          context,
                          horizontal: 14,
                          vertical: 2,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Next button
        SizedBox(
          width: double.infinity,
          height: EcliniqTextStyles.getResponsiveButtonHeight(
            context,
            baseHeight: 55.0,
          ),
          child: GestureDetector(
            onTapDown: isButtonEnabled
                ? (_) {
                    setState(() {
                      _isButtonPressed = true;
                    });
                  }
                : null,
            onTapUp: isButtonEnabled
                ? (_) {
                    setState(() {
                      _isButtonPressed = false;
                    });
                    _handlePhoneSubmit();
                  }
                : null,
            onTapCancel: () {
              setState(() {
                _isButtonPressed = false;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: _isButtonPressed
                    ? Color(0xFF0E4395)
                    : isButtonEnabled
                    ? EcliniqButtonType.brandPrimary.backgroundColor(context)
                    : EcliniqButtonType.brandPrimary.disabledBackgroundColor(
                        context,
                      ),
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Using M-Pin',
                    style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                        .copyWith(
                          color: _isButtonPressed
                              ? Colors.white
                              : isButtonEnabled
                              ? Colors.white
                              : Color(0xffD6D6D6),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // OTP button
        GestureDetector(
          onTapDown: isButtonEnabled
              ? (_) {
                  setState(() {
                    _isOTPButtonPressed = true;
                  });
                }
              : null,
          onTapUp: isButtonEnabled
              ? (_) {
                  setState(() {
                    _isOTPButtonPressed = false;
                  });
                  _handleOTPPhoneSubmit();
                }
              : null,
          onTapCancel: () {
            setState(() {
              _isOTPButtonPressed = false;
            });
          },
          child: Center(
            child: Text(
              'Login using OTP',
              style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                  .copyWith(
                    fontWeight: FontWeight.w400,
                    color: _isOTPButtonPressed
                        ? Color(0xffB8B8B8)
                        : isButtonEnabled
                        ? Color(0xff2372EC)
                        : Color(0xffB8B8B8),
                  ),
            ),
          ),
        ),

        const Spacer(),

        // Trouble signing in link
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? MediaQuery.of(context).viewInsets.bottom + 40
                : 16,
          ),
          child: GestureDetector(
            onTap: () {
              EcliniqRouter.push(const LoginTroublePage());
            },
            child: Text(
              'Trouble signing in?',
              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w400,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  /// Build MPIN screen
  Widget _buildMPINScreen() {
    // Calculate responsive dimensions based on available screen width
    final screenW = MediaQuery.of(context).size.width;
    // Fixed 16 padding on each side (32 total)
    final availableWidth = (screenW - 32.0).clamp(120.0, double.infinity);

    // Minimum and maximum constraints
    const minSlotWidth = 30.0;
    const maxSlotWidth = 80.0;
    const minMargin = 4.0;
    const preferredMargin = 8.0;

    // Calculate optimal slot width and margin
    double finalSlotWidth;
    double finalMargin;

    // Try with preferred margin first
    final preferredTotalMarginSpace =
        3 * (preferredMargin * 2); // 3 gaps * 16 pixels each
    final calculatedSlotWidth =
        (availableWidth - preferredTotalMarginSpace) / 4;

    if (calculatedSlotWidth >= minSlotWidth) {
      // Preferred margin works, use it
      finalSlotWidth = calculatedSlotWidth.clamp(minSlotWidth, maxSlotWidth);
      finalMargin = preferredMargin;
    } else {
      // Need to reduce margin to fit minimum slot width
      // Calculate maximum margin space available
      final maxMarginSpace = availableWidth - (minSlotWidth * 4);
      if (maxMarginSpace > 0) {
        // Calculate margin per gap (divide by 3 gaps, then by 2 for each side)
        finalMargin = (maxMarginSpace / 6).clamp(minMargin, preferredMargin);
        // Recalculate slot width with reduced margin
        final totalMarginSpace = 3 * (finalMargin * 2);
        finalSlotWidth = ((availableWidth - totalMarginSpace) / 4).clamp(
          minSlotWidth,
          maxSlotWidth,
        );
      } else {
        // Extremely small screen - use minimum values
        finalSlotWidth = minSlotWidth;
        finalMargin = minMargin;
      }
    }

    // Calculate final total width
    final totalMarginSpace = 3 * (finalMargin * 2);
    var calculatedTotalWidth = (finalSlotWidth * 4) + totalMarginSpace;

    // Final safety check: ensure total width never exceeds available width
    if (calculatedTotalWidth > availableWidth) {
      // Scale down proportionally to fit exactly
      final scaleFactor = availableWidth / calculatedTotalWidth;
      finalSlotWidth = (finalSlotWidth * scaleFactor);
      finalMargin = (finalMargin * scaleFactor);
      calculatedTotalWidth = (finalSlotWidth * 4) + (3 * (finalMargin * 2));
    }

    // Ensure values are within bounds
    finalSlotWidth = finalSlotWidth.clamp(minSlotWidth, maxSlotWidth);
    finalMargin = finalMargin.clamp(minMargin, preferredMargin);

    // Final total width - must be <= availableWidth
    final finalTotalWidth = ((finalSlotWidth * 4) + (3 * (finalMargin * 2)))
        .clamp(0.0, availableWidth);
    final responsiveLetterSpacing = finalSlotWidth + 4;

    // Calculate spacing: Profile photo bottom is at 59px (-35 + 94)
    // Text should start at 59 + 16 = 75px
    // Content padding is 56px, and there's an 8px SizedBox before text
    // So we need 75 - 56 - 8 = 11px for first SizedBox
    final spacingFromPhoto = 16.0;
    final profilePhotoBottom = 59.0; // -35 (top) + 94 (height)
    final contentPaddingTop = 56.0;
    final secondSizedBoxHeight = 8.0;
    final requiredSpacing = (profilePhotoBottom + spacingFromPhoto) - contentPaddingTop - secondSizedBoxHeight;
    
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? MediaQuery.of(context).viewInsets.bottom
            : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: requiredSpacing.clamp(16.0, double.infinity)),

          // Back button to go back to phone input
          const SizedBox(height: 8),
          Text(
            _isOTPMode
                ? 'Enter Your OTP to Sign In'
                : 'Enter Your MPIN to Sign In',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                .copyWith(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
            textAlign: TextAlign.center,
          ),

          _isOTPMode
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _otpController,
                    autoFocus: true,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    textStyle:
                        EcliniqTextStyles.responsiveHeadlineZMedium(
                          context,
                        ).copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff424242),
                        ),
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
                      ),
                      fieldHeight: EcliniqTextStyles.getResponsiveButtonHeight(
                        context,
                        baseHeight: 52.0,
                      ),
                      fieldWidth: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        45,
                      ),
                      activeFillColor: Colors.white,
                      selectedFillColor: Colors.white,
                      inactiveFillColor: Colors.white,
                      activeColor: const Color(0xff626060),
                      selectedColor: const Color(0xff2372EC),
                      inactiveColor: const Color(0xff626060),
                      borderWidth: 1,
                      activeBorderWidth: 0.5,
                      selectedBorderWidth: 0.5,
                      inactiveBorderWidth: 0.5,
                      fieldOuterPadding: const EdgeInsets.symmetric(
                        horizontal: 2,
                      ),
                    ),
                    enableActiveFill: true,
                    onChanged: _onOTPChanged,
                  ),
                )
              : GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    FocusScope.of(context).requestFocus(_focusNode);
                    SystemChannels.textInput.invokeMethod('TextInput.show');
                  },
                  child: SizedBox(
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Ensure we never exceed the available width
                            final maxWidth = constraints.maxWidth.isFinite
                                ? constraints.maxWidth
                                : finalTotalWidth;
                            final safeTotalWidth = finalTotalWidth.clamp(
                              0.0,
                              maxWidth,
                            );

                            return SizedBox(
                              width: safeTotalWidth,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < 4; i++) ...[
                                    if (i > 0) SizedBox(width: finalMargin * 2),
                                    SizedBox(
                                      width: finalSlotWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            i < _entered.length
                                                ? (_showPin ? _entered[i] : '*')
                                                : '-',
                                            style:
                                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                                  context,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w400,
                                                  color: i < _entered.length
                                                      ? Colors.black
                                                      : Color(0xffD6D6D6),
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            height: 0.5,
                                            width: finalSlotWidth,
                                            decoration: BoxDecoration(
                                              color: Color(0xff8E8E8E),
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final maxWidth = constraints.maxWidth.isFinite
                                  ? constraints.maxWidth
                                  : finalTotalWidth;
                              final safeWidth = finalTotalWidth.clamp(
                                0.0,
                                maxWidth,
                              );
                              return SizedBox(
                                width: safeWidth,
                                child: TextField(
                                  controller: _textController,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  textAlign: TextAlign.center,
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineBMedium(
                                        context,
                                      ).copyWith(
                                        color: Colors.transparent,
                                        letterSpacing: responsiveLetterSpacing,
                                        fontFamily: 'Inter',
                                      ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  cursorColor: Colors.transparent,
                                  autofocus: false,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _navigateToForgotPin();
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isOTPMode ? "Didn't receive OTP?" : 'Forgot PIN?',
                      style: EcliniqTextStyles.responsiveBodySmall(context)
                          .copyWith(
                            color: Color(0xff424242),
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                          ),
                    ),
                  ),
                ],
              ),
              if (!_isOTPMode)
                GestureDetector(
                  onTap: _entered.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _showPin = !_showPin;
                          });
                        },
                  child: Row(
                    children: [
                      Text(
                        'Show PIN',
                        style: EcliniqTextStyles.responsiveBodySmall(context)
                            .copyWith(
                              fontWeight: FontWeight.w400,
                              color: _entered.isEmpty
                                  ? Color(0xffB8B8B8)
                                  : (_showPin
                                        ? const Color(0xFF2372EC)
                                        : Color(0xff424242)),
                            ),
                      ),
                      SizedBox(width: 6),
                      SvgPicture.asset(
                        _showPin
                            ? EcliniqIcons.eyeOpen.assetPath
                            : EcliniqIcons.eyeClosed.assetPath,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          _entered.isEmpty
                              ? Color(0xffB8B8B8)
                              : (_showPin
                                    ? const Color(0xFF2372EC)
                                    : Color(0xff424242)),
                          BlendMode.srcIn,
                        ),
                        errorBuilder: (c, e, s) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          //if (_isBiometricAvailable) ...[
          const SizedBox(height: 40),
          Row(
            children: [
              const Expanded(
                child: Divider(
                  thickness: 1,
                  color: Color(0xFFD6D6D6),
                  indent: 100.0,
                  endIndent: 14,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(
                  thickness: 1,
                  color: Color(0xFFD6D6D6),
                  endIndent: 100.0,
                  indent: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: _isBiometricEnabled
                ? OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleBiometricLogin,
                    icon: SvgPicture.asset(
                      EcliniqIcons.faceId.assetPath,
                      width: 22,
                      height: 22,
                    ),
                    label: Text(
                      _isLoading
                          ? 'Authenticating...'
                          : 'Use ${BiometricService.getBiometricTypeName()}',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2372EC),
                          ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(150, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: Color(0xff96BFFF),
                        width: 0.5,
                      ),
                      backgroundColor: Color(0xffF2F7FF),
                      foregroundColor: Color(0xffF2F7FF),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final mpin = await SecureStorageService.getMPIN();
                            if (mpin != null && mpin.isNotEmpty) {
                              await _requestBiometricPermission(mpin);
                              await _checkBiometricAvailability();
                              if (_isBiometricEnabled && mounted) {
                                await _handleBiometricLogin();
                              }
                            } else {
                              CustomErrorSnackBar.show(
                                context: context,
                                title: 'MPIN Required',
                                subtitle:
                                    'Please enter MPIN first to enable biometric',
                                duration: const Duration(seconds: 3),
                              );
                            }
                          },
                    icon: SvgPicture.asset(
                      EcliniqIcons.faceId.assetPath,
                      width: 22,
                      height: 22,
                    ),
                    label: Text(
                      'Use ${BiometricService.getBiometricTypeName()}',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2372EC),
                          ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(150, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(color: Color(0x382372EC)),
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade100,
                    ),
                  ),
          ),
        ],
        // ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final headerHeight = (screenH * 0.38).clamp(260.0, 420.0).toDouble();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: _showMPINScreen ? 0 : 50,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: headerHeight,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF2372EC),
                                    Color(0xFFF8DFFF),
                                  ],
                                  stops: [0.0, 0.95],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.45,
                                child: Image.asset(
                                  EcliniqIcons.lottie.assetPath,
                                  fit: BoxFit.cover,
                                  cacheWidth: 800,
                                  cacheHeight: 600,
                                  filterQuality: FilterQuality.low,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  EcliniqIcons.loginLogo.assetPath,
                                  height: 44,
                                  width: 198,
                                ),

                                Text(
                                  _userName != null && _userName!.isNotEmpty
                                      ? 'Welcome back, ${_userName!}!'
                                      : 'Welcome back!',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineXLarge(
                                        context,
                                      ).copyWith(
                                        color: Colors.white,
                                        fontFamily: 'Rubik',
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Your Healthcare Platform',
                                  style:
                                      EcliniqTextStyles.responsiveTitleXLarge(
                                        context,
                                      ).copyWith(
                                        color: Colors.white,
                                        fontFamily: 'Rubik',
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, -65),
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Stack(
                                    children: [
                                      PhysicalShape(
                                        clipper: CardHoleClipper(
                                          radius: 52.0,
                                          centerYOffset: 14.0,
                                        ),
                                        color: Colors.white,
                                        elevation: 0,
                                        child: const SizedBox.expand(),
                                      ),
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: TopEdgePainter(
                                            leftColor: const Color(
                                              0xFFBF50FF,
                                            ).withOpacity(0.3),
                                            rightColor: const Color(
                                              0xFF0064FF,
                                            ).withOpacity(0.4),
                                            holeRadius: 52.0,
                                            holeCenterYOffset: 14.0,
                                            cornerRadius: 18.0,
                                            bandHeight: 36.0,
                                          ),
                                        ),
                                      ),

                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16.0,
                                            56.0,
                                            16.0,
                                            0.0,
                                          ),
                                          child: _showMPINScreen
                                              ? _buildMPINScreen()
                                              : _buildPhoneInputScreen(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // if (_showMPINScreen)
                                Positioned(
                                  top: -35,
                                  left: 16,
                                  right: 16,
                                  child: Center(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      width: 94,
                                      height: 94,
                                      child: Center(
                                        child: ClipOval(
                                          child: SvgPicture.asset(
                                            'lib/ecliniq_icons/assets/Group.svg',

                                            width: 80,
                                            fit: BoxFit.contain,

                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                                      EcliniqIcons
                                                          .userCircle
                                                          .assetPath,
                                                      width: 72,
                                                      height: 72,
                                                      fit: BoxFit.cover,
                                                    ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Loading overlay with spinner
        if (_showLoadingOverlay)
          Container(
            color: Colors.transparent,
            child: const Center(child: EcliniqLoader(size: 28)),
          ),
      ],
    );
  }
}
