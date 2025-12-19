import 'dart:async';

import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/mpin/set_mpin.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class ChangeMPINScreen extends StatefulWidget {
  final String? preloadedPhoneNumber;
  final String? preloadedMaskedPhone;
  
  const ChangeMPINScreen({
    super.key,
    this.preloadedPhoneNumber,
    this.preloadedMaskedPhone,
  });

  @override
  State<ChangeMPINScreen> createState() => _ChangeMPINScreenState();
}

class _ChangeMPINScreenState extends State<ChangeMPINScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingOTP = false;
  bool _isVerifying = false;
  bool _isButtonPressed = false;
  String? _errorMessage;
  String? _phoneNumber;
  String? _maskedPhone;

  Timer? _timer;
  int _resendTimer = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    // If phone number is preloaded, use it and skip loading step
    if (widget.preloadedPhoneNumber != null && widget.preloadedMaskedPhone != null) {
      _phoneNumber = widget.preloadedPhoneNumber;
      _maskedPhone = widget.preloadedMaskedPhone;
      // Send OTP immediately without loading phone number
      _sendOTP();
    } else {
      // Load phone number first, then send OTP
      _loadPhoneNumberAndSendOTP();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        if (mounted) {
          setState(() {
            _resendTimer--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _canResend = true;
          });
        }
        timer.cancel();
      }
    });
  }

  Future<void> _loadPhoneNumberAndSendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_phoneNumber == null) {
        final phone = await SecureStorageService.getPhoneNumber();

        if (phone == null || phone.isEmpty) {
          setState(() {
            _errorMessage = 'Phone number not found. Please try again.';
            _isLoading = false;
          });
          return;
        }

        String phoneNumber = phone.replaceAll(RegExp(r'^\+?91'), '').trim();

        if (phoneNumber.length != 10) {
          setState(() {
            _errorMessage = 'Invalid phone number format.';
            _isLoading = false;
          });
          return;
        }

        _maskedPhone = '******${phoneNumber.substring(phoneNumber.length - 4)}';
        _phoneNumber = phoneNumber;
      }

      // Phone number loaded, now send OTP
      setState(() {
        _isLoading = false;
      });

      await _sendOTP();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendOTP() async {
    if (_phoneNumber == null) {
      setState(() {
        _errorMessage = 'Phone number is required';
      });
      return;
    }

    setState(() {
      _isSendingOTP = true;
      _errorMessage = null;
    });

    try {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgetMpinSendOtp(_phoneNumber!);

      if (!mounted) return;

      if (success) {
        setState(() {
          _isSendingOTP = false;
        });
        _startTimer();
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Failed to send OTP';
          _isSendingOTP = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isSendingOTP = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    await _sendOTP();
  }

  Future<void> _verifyAndProceed() async {
    // Check if OTP is valid
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    // Check if already verifying
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgetMpinVerifyOtp(
        _otpController.text,
      );

      if (!mounted) return;

      if (success) {
        // Reset verifying state
        setState(() {
          _isVerifying = false;
        });

        // Navigate to MPIN set screen
        // Use push to maintain navigation stack (SecuritySettings -> ChangeMPIN -> MPINSet)
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MPINSet(isResetMode: true),
          ),
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Failed to verify OTP';
          _isVerifying = false;
          _otpController.clear(); // Clear OTP on error
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isVerifying = false;
        _otpController.clear(); // Clear OTP on error
      });
    }
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _isOtpValid => _otpController.text.length == 6;

  Widget _buildVerifyButton() {
    final isButtonEnabled = _isOtpValid && !_isVerifying;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTapDown: isButtonEnabled
            ? (_) => setState(() => _isButtonPressed = true)
            : null,
        onTapUp: isButtonEnabled
            ? (_) {
                setState(() => _isButtonPressed = false);
                _verifyAndProceed();
              }
            : null,
        onTapCancel: isButtonEnabled
            ? () => setState(() => _isButtonPressed = false)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isVerifying
                ? const Color(0xFF2372EC)
                : _isButtonPressed
                ? const Color(0xFF0E4395) // Pressed color
                : _isOtpValid
                ? const Color(0xFF2372EC) // Enabled color
                : const Color(0xffF9F9F9), // Disabled color
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: _isVerifying
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: EcliniqLoader(color: Colors.white, size: 24),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify & Next',
                        style: EcliniqTextStyles.headlineMedium.copyWith(
                          color: _isOtpValid
                              ? Colors.white
                              : const Color(0xffD6D6D6),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset(
                        EcliniqIcons.arrowRight.assetPath,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          _isOtpValid ? Colors.white : const Color(0xff8E8E8E),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 58,
        titleSpacing: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change M-PIN',
          style: EcliniqTextStyles.headlineMedium.copyWith(
            color: const Color(0xff424242),
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: const Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For your security, please verify your existing account information.',
              style: EcliniqTextStyles.headlineXMedium.copyWith(
                color: const Color(0xff424242),
              ),
            ),
            // Show shimmer only while loading phone number, not while sending OTP
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: 200,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    ShimmerLoading(
                      width: 150,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            if (_maskedPhone != null) ...[
              Row(
                children: [
                  Text(
                    'OTP sent to ',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      color: const Color(0xff424242),
                    ),
                  ),
                  Text(
                    '+91 $_maskedPhone',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: const Color(0xff424242),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: EcliniqTextStyles.bodyMedium.copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                autoFocus: true,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 52,
                  fieldWidth: 45,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  activeColor: const Color(0xff2372EC),
                  selectedColor: const Color(0xff2372EC),
                  inactiveColor: const Color(0xff626060),
                  borderWidth: 1,
                  activeBorderWidth: 0.5,
                  selectedBorderWidth: 1,
                  inactiveBorderWidth: 1,
                  fieldOuterPadding: const EdgeInsets.symmetric(horizontal: 2),
                ),
                enableActiveFill: true,
                errorTextSpace: 16,
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      // Clear error message when user starts typing
                      if (_errorMessage != null) {
                        _errorMessage = null;
                      }
                    });
                  }
                },
                onCompleted: (value) {
                  // Auto-verify when 6 digits are entered
                  // _verifyAndProceed(); // Uncomment if you want auto-submit
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Didn\'t receive the OTP',
                    style: EcliniqTextStyles.bodySmall.copyWith(
                      color: const Color(0xff8E8E8E),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.clockCircle.assetPath,
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimer(_resendTimer),
                        style: EcliniqTextStyles.bodySmall.copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _canResend ? _resendOTP : null,
                child: Text(
                  'Resend',
                  style: EcliniqTextStyles.headlineXMedium.copyWith(
                    color: const Color(0xff2372EC),
                  ),
                ),
              ),
              const Spacer(),
              _buildVerifyButton(),
            ] else if (_errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: EcliniqTextStyles.bodyMedium.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _loadPhoneNumberAndSendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: EcliniqTextStyles.titleXLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
