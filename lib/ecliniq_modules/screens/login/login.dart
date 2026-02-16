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
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final String? phoneNumber;
  final bool initialOtpMode;
  final bool showSelectionMode;

  const LoginPage({
    super.key,
    this.phoneNumber,
    this.initialOtpMode = false,
    this.showSelectionMode = false,
  });

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
  bool _showMPINScreen = false;
  bool _isOTPMode = false;
  String _phoneNumber = '';
  bool _isButtonPressed = false;
  bool _isOTPButtonPressed = false;
  bool _userExplicitlyChoseMPIN = false;
  bool _showLoadingOverlay = false;
  String? _userName;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _mpinSubmitTimer;

  int _resendTimer = 150;
  bool _canResend = false;
  Timer? _otpResendTimer;

  bool get isButtonEnabled => _phoneNumber.length == 10 && !_isLoading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(_onMPINChanged);
    _phoneController.addListener(_onPhoneNumberChanged);

    if (widget.phoneNumber != null) {
      _phoneNumber = widget.phoneNumber!;
      _phoneController.text = _phoneNumber;
      
      if (widget.showSelectionMode) {
        _showMPINScreen = false;
        _isOTPMode = false;
        _userExplicitlyChoseMPIN = false;
      } else {
        _showMPINScreen = true;
        _isOTPMode = widget.initialOtpMode;
        _userExplicitlyChoseMPIN = !widget.initialOtpMode;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.phoneNumber == null) {
        await _loadSavedPhoneNumber();
      }

      await _loadUserName();

      await _checkBiometricAvailability();
    });

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textController.removeListener(_onMPINChanged);
    _phoneController.removeListener(_onPhoneNumberChanged);
    _mpinSubmitTimer?.cancel();
    _otpResendTimer?.cancel();
    _textController.dispose();
    _otpController.dispose();
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startOTPResendTimer() {
    _canResend = false;
    _resendTimer = 150;

    _otpResendTimer?.cancel();
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            _otpResendTimer?.cancel();
          }
        });
      }
    });
  }

  String _formatResendTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _showLoadingOverlay = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phone = _phoneNumber.isNotEmpty
          ? _phoneNumber
          : _phoneController.text.trim();

      final success = await authProvider.loginOrRegisterUser(phone);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showLoadingOverlay = false;
        });

        if (success) {
          _startOTPResendTimer();
          _otpController.clear();

          CustomSuccessSnackBar.show(
            context: context,
            title: 'OTP Resent',
            subtitle: 'OTP sent successfully to +91 $phone',
            duration: const Duration(seconds: 3),
          );
        } else {
          CustomErrorSnackBar.show(
            context: context,
            title: 'Failed to resend OTP',
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

  Future<void> _loadSavedPhoneNumber() async {
    try {
      final savedPhone = await SecureStorageService.getPhoneNumber();
      if (savedPhone != null && savedPhone.isNotEmpty && mounted) {
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

  Future<void> _loadUserName() async {
    try {
      final name = await SecureStorageService.getUserName();
      if (name != null && name.isNotEmpty && mounted) {
        setState(() {
          _userName = name.trim().split(' ').first;
        });
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

    if (state == AppLifecycleState.resumed && mounted) {
      _checkBiometricAvailability();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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

    if (_entered != v) {
      setState(() {
        _entered = v;

        if (v.isEmpty) {
          _showPin = false;

          _isLoading = false;
          _showLoadingOverlay = false;
        }
      });
    }

    _mpinSubmitTimer?.cancel();

    if (v.length == 4) {
      setState(() {
        _isLoading = true;
        _showLoadingOverlay = true;
      });

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

    if (_entered != v) {
      setState(() {
        _entered = v;

        if (v.isEmpty) {
          _showPin = false;
          _isLoading = false;
          _showLoadingOverlay = false;
        }
      });
    }

    _mpinSubmitTimer?.cancel();

    if (v.length == 6) {
      setState(() {
        _isLoading = true;
        _showLoadingOverlay = true;
      });

      _mpinSubmitTimer = Timer(Duration.zero, () {
        if (mounted) {
          _handleOTPLogin(v);
        }
      });
    }
  }

  Future<void> _handleOTPLogin(String otp) async {
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

      final success = await authProvider.verifyOTP(otp);

      if (mounted) {
        if (success) {
          setState(() {
            _isLoading = false;
          });

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
              } catch (e2) {}
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

    await SecureStorageService.storePhoneNumber(phone);

    await _checkBiometricAvailability();

    setState(() {
      _phoneNumber = phone;
      _showMPINScreen = true;
      _isOTPMode = false;
      _isLoading = false;
      _userExplicitlyChoseMPIN = true;
    });
  }

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
      await SecureStorageService.storePhoneNumber(phone);

      await _checkBiometricAvailability();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.loginOrRegisterUser(phone);

      if (mounted) {
        if (success) {
          setState(() {
            _phoneNumber = phone;
            _showMPINScreen = true;
            _isOTPMode = true;
            _isLoading = false;
            _showLoadingOverlay = false;
            _userExplicitlyChoseMPIN = false;
            _otpController.clear();
          });

          _startOTPResendTimer();

          CustomSuccessSnackBar.show(
            context: context,
            title: 'OTP Sent',
            subtitle: 'OTP sent successfully to +91 $phone',
            duration: const Duration(seconds: 3),
          );
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
      if (mounted) {
        try {
          final isEnabled = await SecureStorageService.isBiometricEnabled();
          setState(() {
            _isBiometricAvailable = isEnabled || _isBiometricAvailable;
            _isBiometricEnabled = isEnabled;
          });
        } catch (_) {}
      }
    }
  }

  void _navigateToForgotPin() {
    final phoneController = TextEditingController();
    EcliniqRouter.push(
      PhoneInputScreen(
        phoneController: phoneController,
        onClose: () {
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
    final phoneController = TextEditingController();
    EcliniqRouter.push(
      PhoneInputScreen(
        phoneController: phoneController,
        onClose: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          EcliniqRouter.pop();
        },
        fadeAnimation: AlwaysStoppedAnimation(1.0),
        isForgotPinFlow: false,
      ),
    );
  }

  void _navigateToPhoneInputForSessionRenewal() {
    final phoneController = TextEditingController();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    EcliniqRouter.pushAndRemoveUntil(
      PhoneInputScreen(
        phoneController: phoneController,
        onClose: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          EcliniqRouter.pop();
        },
        fadeAnimation: AlwaysStoppedAnimation(1.0),
        isForgotPinFlow: false,
      ),
      (route) => route.isFirst,
    );
  }

  Future<void> _requestBiometricPermission(String mpin) async {
    try {
      if (!await BiometricService.isAvailable()) {
        return;
      }

      if (await SecureStorageService.isBiometricEnabled()) {
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
        return;
      }

      final success = await SecureStorageService.storeMPINWithBiometric(mpin);

      if (success) {
        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
      } else {}
    } catch (e) {}
  }

  Future<void> _handleMPINLogin(String mpin) async {
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

      final success = await authProvider.loginWithMPIN(mpin);

      if (mounted) {
        if (success) {
          setState(() {
            _isLoading = false;
          });

          if (_isBiometricAvailable && !_isBiometricEnabled) {
            _requestBiometricPermission(mpin)
                .timeout(const Duration(seconds: 1), onTimeout: () {})
                .catchError((e) {});
          }

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
                return;
              } catch (e2) {
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
          if (authProvider.errorMessage == 'SESSION_EXPIRED') {
            setState(() {
              _isLoading = false;
              _showLoadingOverlay = false;
              _entered = '';
              _textController.clear();
              _showMPINScreen = false;
              _userExplicitlyChoseMPIN = false;
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
    if (_isLoading) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _showLoadingOverlay = true;
    });

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
      final mpin = await SecureStorageService.getMPIN();
      if (mpin != null && mpin.isNotEmpty) {
        await _requestBiometricPermission(mpin);

        final isEnabled = await SecureStorageService.isBiometricEnabled();
        if (!isEnabled) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _showLoadingOverlay = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _isBiometricEnabled = true;
          });
        }
      } else {
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.loginWithBiometric().timeout(
        const Duration(seconds: 35),
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

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (!mounted) {
        return;
      }

      if (success) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        scheduleMicrotask(() {
          if (mounted) {
            EcliniqRouter.pushAndRemoveUntil(
              const HomeScreen(),
              (route) => false,
            );
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _showLoadingOverlay = false;
          });
        }

        if (authProvider.errorMessage == 'SESSION_EXPIRED') {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            _navigateToPhoneInputForSessionRenewal();
          }
        } else {
          final errorMsg = authProvider.errorMessage ?? '';

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
            final mpin = await SecureStorageService.getMPIN();
            if (mpin != null && mpin.isNotEmpty) {
              await _requestBiometricPermission(mpin);

              await _checkBiometricAvailability();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showLoadingOverlay = false;
        });

        if (e.toString().toLowerCase().contains('timeout')) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          CustomErrorSnackBar.show(
            context: context,
            title: 'Timeout',
            subtitle: 'Biometric authentication timed out. Please try again.',
            duration: const Duration(seconds: 3),
          );
        } else {
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

  Widget _buildPhoneInputScreen() {
    final spacingFromPhoto = 16.0;
    final profilePhotoBottom = 59.0;
    final contentPaddingTop = 56.0;
    final requiredSpacing =
        (profilePhotoBottom + spacingFromPhoto) - contentPaddingTop;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: keyboardVisible
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: requiredSpacing.clamp(16.0, double.infinity),
                  ),
                  Text(
                    'Enter Your Mobile Number to Login',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

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
                          padding:
                              EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                context,
                                horizontal: 12,
                                vertical: 6,
                              ),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Color(0xffD6D6D6),
                                width: 0.5,
                              ),
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
                              ? EcliniqButtonType.brandPrimary.backgroundColor(
                                  context,
                                )
                              : EcliniqButtonType.brandPrimary
                                    .disabledBackgroundColor(context),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              4,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Using M-Pin',
                              style:
                                  EcliniqTextStyles.responsiveHeadlineMedium(
                                    context,
                                  ).copyWith(
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
                        style:
                            EcliniqTextStyles.responsiveHeadlineMedium(
                              context,
                            ).copyWith(
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMPINScreen() {
    final screenW = MediaQuery.of(context).size.width;

    final availableWidth = (screenW - 32.0).clamp(120.0, double.infinity);

    const minSlotWidth = 30.0;
    const maxSlotWidth = 80.0;
    const minMargin = 4.0;
    const preferredMargin = 8.0;

    double finalSlotWidth;
    double finalMargin;

    final preferredTotalMarginSpace = 3 * (preferredMargin * 2);
    final calculatedSlotWidth =
        (availableWidth - preferredTotalMarginSpace) / 4;

    if (calculatedSlotWidth >= minSlotWidth) {
      finalSlotWidth = calculatedSlotWidth.clamp(minSlotWidth, maxSlotWidth);
      finalMargin = preferredMargin;
    } else {
      final maxMarginSpace = availableWidth - (minSlotWidth * 4);
      if (maxMarginSpace > 0) {
        finalMargin = (maxMarginSpace / 6).clamp(minMargin, preferredMargin);

        final totalMarginSpace = 3 * (finalMargin * 2);
        finalSlotWidth = ((availableWidth - totalMarginSpace) / 4).clamp(
          minSlotWidth,
          maxSlotWidth,
        );
      } else {
        finalSlotWidth = minSlotWidth;
        finalMargin = minMargin;
      }
    }

    final totalMarginSpace = 3 * (finalMargin * 2);
    var calculatedTotalWidth = (finalSlotWidth * 4) + totalMarginSpace;

    if (calculatedTotalWidth > availableWidth) {
      final scaleFactor = availableWidth / calculatedTotalWidth;
      finalSlotWidth = (finalSlotWidth * scaleFactor);
      finalMargin = (finalMargin * scaleFactor);
      calculatedTotalWidth = (finalSlotWidth * 4) + (3 * (finalMargin * 2));
    }

    finalSlotWidth = finalSlotWidth.clamp(minSlotWidth, maxSlotWidth);
    finalMargin = finalMargin.clamp(minMargin, preferredMargin);

    final finalTotalWidth = ((finalSlotWidth * 4) + (3 * (finalMargin * 2)))
        .clamp(0.0, availableWidth);
    final responsiveLetterSpacing = finalSlotWidth + 4;

    final spacingFromPhoto = 16.0;
    final profilePhotoBottom = 59.0;
    final contentPaddingTop = 56.0;
    final secondSizedBoxHeight = 8.0;
    final requiredSpacing =
        (profilePhotoBottom + spacingFromPhoto) -
        contentPaddingTop -
        secondSizedBoxHeight;

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

          const SizedBox(height: 14),
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
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
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
                                                : (i == _entered.length &&
                                                          _focusNode.hasFocus
                                                      ? '|'
                                                      : '-'),
                                            style:
                                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                                  context,
                                                ).copyWith(
                                                  fontWeight: FontWeight.w400,
                                                  color: i < _entered.length
                                                      ? Colors.black
                                                      : (i == _entered.length &&
                                                                _focusNode
                                                                    .hasFocus
                                                            ? const Color(
                                                                0xFF2372EC,
                                                              )
                                                            : const Color(
                                                                0xffD6D6D6,
                                                              )),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isOTPMode)
                      Row(
                        children: [
                          Text(
                            "Didn’t receive the OTP",
                            style:
                                EcliniqTextStyles.responsiveBodySmall(
                                  context,
                                ).copyWith(
                                  color: Color(0xff8E8E8E),
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Inter',
                                ),
                          ),
                          const Spacer(),
                          if (!_canResend)
                            Row(
                              children: [
                                SvgPicture.asset(
                                  EcliniqIcons.clockCircle.assetPath,
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatResendTimer(_resendTimer),
                                  style: EcliniqTextStyles.responsiveBodySmall(
                                    context,
                                  ).copyWith(color: const Color(0xff424242)),
                                ),
                              ],
                            ),
                        ],
                      )
                    else
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
                          'Forgot PIN?',
                          style: EcliniqTextStyles.responsiveBodySmall(context)
                              .copyWith(
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Inter',
                              ),
                        ),
                      ),
                    if (_isOTPMode)
                      GestureDetector(
                        onTap: _canResend && !_isLoading ? _resendOTP : null,
                        child: Text(
                          'Resend',
                          style:
                              EcliniqTextStyles.responsiveHeadlineXMedium(
                                context,
                              ).copyWith(
                                color: _canResend && !_isLoading
                                    ? const Color(0xff2372EC)
                                    : const Color(0xffB8B8B8),
                              ),
                        ),
                      ),
                  ],
                ),
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
                  child: !_showPin
                      ? Row(
                          children: [
                            Text(
                              'Show PIN',
                              style:
                                  EcliniqTextStyles.responsiveBodySmall(
                                    context,
                                  ).copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: _entered.isEmpty
                                        ? Color(0xffB8B8B8)
                                        : const Color(0xFF2372EC),
                                  ),
                            ),
                            SizedBox(width: 6),
                            SvgPicture.asset(
                              EcliniqIcons.eyeOpen.assetPath,
                              width: 18,
                              height: 18,
                              colorFilter: ColorFilter.mode(
                                _entered.isEmpty
                                    ? Color(0xffB8B8B8)
                                    : const Color(0xFF2372EC),
                                BlendMode.srcIn,
                              ),
                              errorBuilder: (c, e, s) =>
                                  const SizedBox.shrink(),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              'Hide PIN',
                              style:
                                  EcliniqTextStyles.responsiveBodySmall(
                                    context,
                                  ).copyWith(
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
                              EcliniqIcons.eyeClosed.assetPath,
                              width: 18,
                              height: 18,
                              errorBuilder: (c, e, s) =>
                                  const SizedBox.shrink(),
                            ),
                          ],
                        ),
                ),
            ],
          ),

          const SizedBox(height: 80),
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
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : (_isBiometricEnabled
                        ? _handleBiometricLogin
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
                          }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Color(0xffF2F7FF),

                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Color(0xff96BFFF), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.faceId.assetPath,
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isBiometricEnabled
                          ? (_isLoading
                                ? 'Authenticating...'
                                : 'Use ${BiometricService.getBiometricTypeName()}')
                          : 'Use ${BiometricService.getBiometricTypeName()}',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2372EC),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                  padding: EdgeInsets.only(bottom: _showMPINScreen ? 0 : 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: headerHeight,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
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
                            Padding(
                              padding: const EdgeInsets.only(bottom: 116.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    EcliniqIcons.loginLogo.assetPath,
                                    height: 44,
                                    width: 198,
                                  ),

                                  Text(
                                    _userName != null && _userName!.isNotEmpty
                                        ? 'Welcome back, ${_userName!.split(' ').first}!'
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
                      if (!_showMPINScreen)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0, top: 4),
                          child: GestureDetector(
                            onTap: () {
                              EcliniqRouter.push(const LoginTroublePage());
                            },
                            child: Text(
                              'Trouble signing in?',
                              style:
                                  EcliniqTextStyles.responsiveHeadlineBMedium(
                                    context,
                                  ).copyWith(
                                    color: Color(0xff424242),
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Inter',
                                  ),
                              textAlign: TextAlign.center,
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

        if (_showLoadingOverlay)
          Container(
            color: Colors.transparent,
            child: const Center(child: EcliniqLoader(size: 28)),
          ),
      ],
    );
  }
}
