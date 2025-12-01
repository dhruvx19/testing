import 'dart:async';
import 'dart:math';

import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/phone_input.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/home/home_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  // Feature flag: Set to false to disable biometric for production
  static const bool _enableBiometric = false;
  
  bool _showPin = false;
  String _entered = '';
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _showMPINScreen =
      false; // Track if we should show MPIN screen or phone input
  String _phoneNumber = ''; // Store phone number for MPIN verification
  bool _isButtonPressed = false; // Track button press state
  final TextEditingController _textController = TextEditingController();
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
      // Check biometric availability
      if (_enableBiometric) {
        await _checkBiometricAvailability();

        // If biometric is enabled and phone number is pre-filled, auto-trigger biometric
        // This allows direct biometric login without showing phone/MPIN screens (like Alaan)
        if (mounted &&
            _isBiometricAvailable &&
            _isBiometricEnabled &&
            _phoneNumber.isNotEmpty) {
          // Small delay to ensure UI is ready
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted && !_showMPINScreen && !_isLoading) {
            await _handleBiometricLogin();
          }
        }
      }
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
    if (_enableBiometric && state == AppLifecycleState.resumed && mounted) {
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
        }
      });
    }

    // Cancel previous timer
    _mpinSubmitTimer?.cancel();

    // Auto-submit when 4 digits entered (with small delay for better UX)
    if (v.length == 4) {
      _mpinSubmitTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted && !_isLoading) {
          _handleMPINLogin(v);
        }
      });
    }
  }

  Future<void> _autoTriggerBiometric() async {
    // Auto-trigger biometric if available and enabled (after a short delay)
    // Only trigger on MPIN screen and if user hasn't started typing MPIN
    if (!_showMPINScreen) return; // Only on MPIN screen

    await Future.delayed(const Duration(milliseconds: 800));

    // Double-check all conditions before triggering
    if (!mounted) return;
    if (_isLoading) return;
    if (!_isBiometricAvailable) return;
    if (!_isBiometricEnabled) return;
    if (_entered.isNotEmpty) return; // User has started typing

    try {
      // Don't set loading state here - let _handleBiometricLogin() handle it
      // This prevents race conditions
      await _handleBiometricLogin();
    } catch (e) {
      // Silently fail - user can still use MPIN
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle phone number submission - move to MPIN screen or biometric if enabled
  Future<void> _handlePhoneSubmit() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save phone number to secure storage
    await SecureStorageService.storePhoneNumber(phone);

    // Check biometric availability first
    await _checkBiometricAvailability();

    // If biometric is enabled and available, skip MPIN screen and go directly to biometric
    if (_isBiometricAvailable && _isBiometricEnabled) {
      setState(() {
        _phoneNumber = phone;
        _showMPINScreen = false; // Don't show MPIN screen
        _isLoading = false;
      });

      // Trigger biometric login directly (like Alaan - no MPIN screen)
      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Small delay for smooth transition
      if (mounted) {
        await _handleBiometricLogin();
      }
    } else {
      // Move to MPIN screen if biometric not enabled
      setState(() {
        _phoneNumber = phone;
        _showMPINScreen = true;
        _isLoading = false;
      });

      // Auto-trigger biometric if enabled (only on MPIN screen)
      if (mounted && _showMPINScreen) {
        _autoTriggerBiometric();
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
    if (_isLoading) return;

    // Ensure we have phone number
    if (_phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Phone number is already stored in secure storage, loginWithMPIN will retrieve it
      final success = await authProvider.loginWithMPIN(mpin);

      // Debug logging
      print(
        'MPIN Login result: success=$success, errorMessage=${authProvider.errorMessage}',
      );

      if (mounted) {
        if (success) {
          print('✅✅✅ LOGIN SUCCESS - Starting navigation process...');

          // Reset loading state immediately
          setState(() {
            _isLoading = false;
          });

          print('✅ Step 1: Loading state reset, mounted: $mounted');

          // After successful MPIN login, ask for biometric permission if available and not enabled
          // Wrap in try-catch to ensure navigation happens even if biometric setup fails
          if (_isBiometricAvailable && !_isBiometricEnabled) {
            print('📱 Requesting biometric permission...');
            try {
              await _requestBiometricPermission(mpin).timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  print(
                    '⏱️ Biometric permission request timed out, continuing...',
                  );
                },
              );
              print('✅ Biometric permission request completed');
            } catch (e) {
              // Log error but don't block navigation
              print('⚠️ Biometric permission request failed: $e');
            }
          } else {
            print(
              'ℹ️ Skipping biometric permission (available: $_isBiometricAvailable, enabled: $_isBiometricEnabled)',
            );
          }

          // Ensure we're still mounted after biometric request
          if (!mounted) {
            print('❌ Widget not mounted after biometric, cannot navigate');
            return;
          }

          print(
            '✅ Step 2: About to navigate, context type: ${context.runtimeType}',
          );
          print(
            '✅ Step 3: Navigator key available: ${EcliniqRouter.navigatorKey.currentState != null}',
          );

          // SIMPLIFIED: Just navigate directly using the most reliable method
          print('🚀 NAVIGATING NOW...');

          try {
            // Use the router's navigator key directly
            final navigator = EcliniqRouter.navigatorKey.currentState;
            if (navigator != null && mounted) {
              print('✅ Navigator found, pushing HomeScreen...');
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) {
                    print('🏠 HomeScreen builder called!');
                    return const HomeScreen();
                  },
                ),
                (route) {
                  print('🗑️ Removing route: ${route.settings.name}');
                  return false; // Remove all previous routes
                },
              );
              print(
                '✅✅✅ NAVIGATION COMPLETE - HomeScreen should be visible now!',
              );
              return; // Exit function
            } else {
              print('❌ Navigator is null or widget not mounted');
            }
          } catch (e, stackTrace) {
            print('❌❌❌ NAVIGATION ERROR: $e');
            print('Stack: $stackTrace');
          }

          // Fallback navigation methods
          bool navigationSuccess = false;

          // Method 2: Try direct Navigator with root context
          if (!navigationSuccess && mounted) {
            try {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
              navigationSuccess = true;
              print('✅ Navigation via root Navigator completed successfully');
            } catch (e, stackTrace) {
              print('❌ Root Navigator failed: $e');
              print('Stack trace: $stackTrace');
            }
          }

          // Method 3: Try regular Navigator
          if (!navigationSuccess && mounted) {
            try {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
              navigationSuccess = true;
              print(
                '✅ Navigation via regular Navigator completed successfully',
              );
            } catch (e, stackTrace) {
              print('❌ Regular Navigator failed: $e');
              print('Stack trace: $stackTrace');
            }
          }

          // Method 4: Try router method
          if (!navigationSuccess && mounted) {
            try {
              EcliniqRouter.pushAndRemoveUntil(
                const HomeScreen(),
                (route) => false,
              );
              navigationSuccess = true;
              print('✅ Navigation via EcliniqRouter completed successfully');
            } catch (e, stackTrace) {
              print('❌ EcliniqRouter failed: $e');
              print('Stack trace: $stackTrace');
            }
          }

          if (!navigationSuccess) {
            print(
              '⚠️ First navigation attempt failed, trying fallback methods...',
            );

            // Final fallback: Use post-frame callback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                print('🔄 Post-frame callback: Attempting navigation again...');
                try {
                  final navigator = EcliniqRouter.navigatorKey.currentState;
                  if (navigator != null) {
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                    print('✅✅✅ Post-frame navigation succeeded!');
                    return;
                  }
                } catch (e) {
                  print('❌ Post-frame navigation also failed: $e');
                }

                // Last resort: Show error
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Login successful but navigation failed. Please restart the app.',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              }
            });
          }
        } else {
          // Check if session expired - go back to phone input
          if (authProvider.errorMessage == 'SESSION_EXPIRED') {
            // Reset state and go back to phone input
            setState(() {
              _isLoading = false;
              _entered = '';
              _textController.clear();
              _showMPINScreen = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please login again.'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            setState(() {
              _isLoading = false;
              _entered = '';
              _textController.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Invalid MPIN'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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

    // Check if biometric is actually available before proceeding
    if (!_isBiometricAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometric authentication is not available on this device',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
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
            });
          }
          return;
        }
        // Update state and continue with biometric login
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
      } else {
        // Can't enable biometric without MPIN
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('MPIN not found. Please login with MPIN first.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

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
            });
            _showBiometricFailureOptions('Biometric authentication timed out');
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
        // Navigate to home
        EcliniqRouter.pushAndRemoveUntil(const HomeScreen(), (route) => false);
        // Don't reset loading state here as we're navigating away
      } else {
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
              errorMsg.toLowerCase().contains('user');

          if (errorMsg.isNotEmpty && !isUserCancellation) {
            if (mounted) {
              // Show options dialog for authentication failure
              _showBiometricFailureOptions(errorMsg);
            }
          } else if (errorMsg.toLowerCase().contains('not enabled')) {
            // If biometric is not enabled, redirect to setup
            final mpin = await SecureStorageService.getMPIN();
            if (mpin != null && mpin.isNotEmpty) {
              await _requestBiometricPermission(mpin);
              // Re-check availability after permission request
              await _checkBiometricAvailability();
            }
          } else if (isUserCancellation) {
            // User cancelled - focus on MPIN input
            _focusMPINInput();
          }
        }
      }
    } catch (e) {
      // Always reset loading state on exception
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Check if it's a timeout exception
        if (e.toString().toLowerCase().contains('timeout')) {
          _showBiometricFailureOptions('Biometric authentication timed out');
        } else {
          // Show options for other failures
          _showBiometricFailureOptions('Biometric authentication failed');
        }
      }
    }
  }

  /// Show options dialog when biometric fails
  void _showBiometricFailureOptions(String errorMessage) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Authentication Failed'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            const SizedBox(height: 16),
            const Text(
              'Please choose an option to continue:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Focus on MPIN input
              _focusMPINInput();
            },
            child: const Text(
              'Use MPIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2372EC),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry biometric
              Future.delayed(const Duration(milliseconds: 300), () {
                _handleBiometricLogin();
              });
            },
            icon: ImageIcon(
              const AssetImage('lib/ecliniq_icons/assets/Face Scan Square.png'),
              size: 20,
            ),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2372EC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Focus on MPIN input field
  void _focusMPINInput() {
    if (!mounted) return;
    // Clear any existing input
    _textController.clear();
    setState(() {
      _entered = '';
    });
    // Focus on the MPIN input after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  /// Build phone input screen
  Widget _buildPhoneInputScreen() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 35),
        const Text(
          'Enter Your Mobile Number to Login',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Phone input field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xff626060), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff424242),
                      ),
                    ),
                    const SizedBox(width: 4),
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
                  decoration: const InputDecoration(
                    hintText: 'Mobile Number',
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
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
          height: 52,
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
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Using M-Pin',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      color: _isButtonPressed
                          ? Colors.white
                          : isButtonEnabled
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const Spacer(),
      ],
    );
  }

  /// Build MPIN screen
  Widget _buildMPINScreen(
    double slotWidth,
    double totalOverlayWidth,
    double screenW,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 35),

          // Back button to go back to phone input
          const SizedBox(height: 8),
          const Text(
            'Enter Your MPIN to Sign In',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: Color(0xff424242),
            ),
            textAlign: TextAlign.center,
          ),

       
          GestureDetector(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final ch = i < _entered.length
                          ? (_showPin ? _entered[i] : '*')
                          : '';
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ch,
                              style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              width: slotWidth,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  Center(
                    child: SizedBox(
                      width: totalOverlayWidth.clamp(200.0, screenW - 48.0),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.transparent,
                          fontSize: 18,
                          letterSpacing: slotWidth + 4,
                          fontFamily: 'Inter',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        cursorColor: Colors.transparent,
                        autofocus: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ShimmerLoading(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            )
          else ...[
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
                      child: const Text(
                        'Forgot PIN?',
                        style: TextStyle(
                          color: Color(0xff424242),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _entered.isEmpty
                              ? Color(0xffB8B8B8)
                              : (_showPin
                                    ? const Color(0xFF2372EC)
                                    : Color(0xffB8B8B8)),
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
                                    : Color(0xffB8B8B8)),
                          BlendMode.srcIn,
                        ),
                        errorBuilder: (c, e, s) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_enableBiometric && _isBiometricAvailable) ...[
              const SizedBox(height: 30),
              Row(
                children: [
                  const Expanded(
                    child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
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
                    child: Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                          style: const TextStyle(
                            fontSize: 18,
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
                          side: const BorderSide(color: Color(0x382372EC)),
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade100,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                final mpin =
                                    await SecureStorageService.getMPIN();
                                if (mpin != null && mpin.isNotEmpty) {
                                  await _requestBiometricPermission(mpin);
                                  await _checkBiometricAvailability();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter MPIN first'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
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
                          style: const TextStyle(
                            fontSize: 18,
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
                          side: const BorderSide(color: Color(0x382372EC)),
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade100,
                        ),
                      ),
              ),
            ],
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final headerHeight = (screenH * 0.38).clamp(260.0, 420.0).toDouble();

    final slotWidth = 66.0;
    final totalOverlayWidth = (slotWidth + 16) * 4;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
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
                            colors: [Color(0xFF2372EC), Color(0xFFF8DFFF)],
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
                            EcliniqIcons.nameLogo.assetPath,
                            height: 40,
                            width: 198,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Welcome back, Ketan!',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Rubik',
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Your Healthcare Platform',
                            style: TextStyle(
                              color: Color(0xE5FFFFFF),
                              fontFamily: 'Rubik',
                              fontSize: 16,
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
                                      18.0,
                                      56.0,
                                      18.0,
                                      0.0,
                                    ),
                                    child: _showMPINScreen
                                        ? _buildMPINScreen(
                                            slotWidth,
                                            totalOverlayWidth,
                                            screenW,
                                          )
                                        : _buildPhoneInputScreen(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // if (_showMPINScreen)
                          Positioned(
                            top: -35,
                            left: 18,
                            right: 18,
                            child: Center(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
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
                                          (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => Image.asset(
                                            EcliniqIcons.userCircle.assetPath,
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
    );
  }
}
