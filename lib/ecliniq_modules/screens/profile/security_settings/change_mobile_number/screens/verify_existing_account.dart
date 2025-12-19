import 'dart:async';

import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'add_mobile_number.dart';

class VerifyExistingAccount extends StatefulWidget {
  final String? challengeId;
  final String? maskedContact;
  final String? existingPhone;
  final String? preloadedPhone;
  final String? preloadedMaskedPhone;

  const VerifyExistingAccount({
    super.key,
    this.challengeId,
    this.maskedContact,
    this.existingPhone,
    this.preloadedPhone,
    this.preloadedMaskedPhone,
  });

  @override
  State<VerifyExistingAccount> createState() => _VerifyExistingAccountState();
}

class _VerifyExistingAccountState extends State<VerifyExistingAccount> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isSendingOTP = false;
  bool _isButtonPressed = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _maskedContact;
  String? _challengeId;
  Timer? _timer;
  int _resendTimer = 150; // 2 minutes 30 seconds
  bool _canResend = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    
    // If phone is preloaded, use it and send OTP immediately
    if (widget.preloadedPhone != null && widget.preloadedMaskedPhone != null) {
      _maskedContact = widget.preloadedMaskedPhone;
      // Send OTP immediately without showing loading state
      _sendOTPToExistingContact();
    } else if (widget.challengeId != null && widget.maskedContact != null) {
      // Use provided data if available
      _challengeId = widget.challengeId;
      _maskedContact = widget.maskedContact;
    } else {
      // Fallback: fetch OTP (this should rarely happen now)
      _sendOTPToExistingContact();
    }
    
    _startTimer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 150;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
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

  Future<void> _sendOTPToExistingContact() async {
    if (!mounted) return;

    setState(() {
      _isSendingOTP = true;
      _errorMessage = null;
    });

    try {
      final authToken = await SessionService.getAuthToken();
      final result = await _authService.sendExistingContactOTP(
        type: 'mobile',
        authToken: authToken,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Process contact to ensure consistent format (remove +91 if present, we'll add it in display)
        String contact = result['contact'] ?? '';
        // Remove +91 prefix if present to ensure consistent display format
        if (contact.startsWith('+91')) {
          contact = contact.substring(3).trim();
        } else if (contact.startsWith('91')) {
          contact = contact.substring(2).trim();
        }
        
        setState(() {
          _challengeId = result['challengeId'];
          // Only update masked contact if we don't have preloaded one
          if (widget.preloadedMaskedPhone == null) {
            _maskedContact = contact;
          }
          _isSendingOTP = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to send OTP';
          _isSendingOTP = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isSendingOTP = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || !mounted) return;

    setState(() {
      _canResend = false;
      _resendTimer = 150;
    });
    _startTimer();
    await _sendOTPToExistingContact();
  }

  Future<void> _verifyAndProceed() async {
    if (!mounted) return;

    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    if (_challengeId == null) {
      setState(() {
        _errorMessage = 'Challenge ID not found. Please try again.';
      });
      return;
    }

    // Check if already verifying
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    // Step 2: Verify existing contact OTP
    try {
      final authToken = await SessionService.getAuthToken();
      final result = await _authService.verifyExistingContactOtp(
        challengeId: _challengeId!,
        otp: _otpController.text,
        authToken: authToken,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Reset verifying state
        setState(() {
          _isVerifying = false;
        });
        
        // Navigate to add mobile number screen with verificationToken
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddMobileNumber(verificationToken: result['verificationToken']),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to verify OTP';
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

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
          'Verify Existing Account',
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
            if (_maskedContact != null) ...[
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
                    '+91 $_maskedContact',
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
                          color: const Color(0xff424242),
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
            ],
          ],
        ),
      ),
    );
  }
}