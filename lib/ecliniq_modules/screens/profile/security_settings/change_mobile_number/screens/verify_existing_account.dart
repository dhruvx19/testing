import 'dart:async';

import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
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

  final bool _isLoading = false;
  bool _isButtonPressed = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _contact;
  String? _challengeId;
  Timer? _timer;
  int _resendTimer = 30; 
  bool _canResend = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    
    if (widget.preloadedPhone != null && widget.preloadedMaskedPhone != null) {
      _contact = widget.preloadedPhone;
      
      _sendOTPToExistingContact();
    } else if (widget.challengeId != null && widget.maskedContact != null) {
      
      _challengeId = widget.challengeId;
      _contact = widget.maskedContact;
    } else {
      
      _sendOTPToExistingContact();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        setState(() {
          _challengeId = result['challengeId'];
          
          if (widget.preloadedPhone == null) {
            _contact = result['contact'];
          }
        });
        _startTimer();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || !mounted) return;
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

    
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    
    try {
      final authToken = await SessionService.getAuthToken();
      final result = await _authService.verifyExistingContactOtp(
        challengeId: _challengeId!,
        otp: _otpController.text,
        authToken: authToken,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        
        setState(() {
          _isVerifying = false;
        });

        
        if (!mounted) return;
        final addResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddMobileNumber(verificationToken: result['verificationToken']),
          ),
        );

        
        if (addResult != null && mounted) {
          Navigator.pop(context, addResult);
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to verify OTP';
          _isVerifying = false;
          _otpController.clear(); 
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isVerifying = false;
        _otpController.clear(); 
      });
    }
  }

  bool get _isOtpValid => _otpController.text.length == 6;

  Widget _buildVerifyButton() {
    final isButtonEnabled = _isOtpValid && !_isVerifying;

    return SizedBox(
      width: double.infinity,
      height: EcliniqTextStyles.getResponsiveButtonHeight(context, baseHeight: 52.0),
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
                ? const Color(0xFF0E4395) 
                : _isOtpValid
                ? const Color(0xFF2372EC) 
                : const Color(0xffF9F9F9), 
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
                        style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                          color: _isOtpValid
                              ? Colors.white
                              : const Color(0xffD6D6D6),
                        ),
                      ),
                      SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                      SvgPicture.asset(
                        EcliniqIcons.arrowRight.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                        height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
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
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verify Existing Account',
          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
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
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 18.0,
          vertical: 24.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For your security, please verify your existing account information.',
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: const Color(0xff424242),
              ),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.only(
                  top: EcliniqTextStyles.getResponsiveSpacing(context, 24.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(
                      width: EcliniqTextStyles.getResponsiveSize(context, 200.0),
                      height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                      ),
                    ),
                    SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
                    ShimmerLoading(
                      width: EcliniqTextStyles.getResponsiveSize(context, 150.0),
                      height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                      ),
                    ),
                  ],
                ),
              ),
            if (_contact != null) ...[
              Row(
                children: [
                  Text(
                    'OTP sent to ',
                    style:EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                      fontWeight: FontWeight.w400,
                    
                      color: const Color(0xff424242),
                    ),
                  ),
                  Text(
                    '+91 ${_contact!}',
                    style:EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                      fontWeight: FontWeight.w500,
                    
                      color: const Color(0xff424242),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(
                    top: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                      color: Colors.red,
                    ),
                  ),
                ),
              SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0)),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                autoFocus: true,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                textStyle:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                  
                  fontWeight: FontWeight.w400,
                  color: Color(0xff424242),
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 52,
                  fieldWidth: 45,
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
                  fieldOuterPadding: const EdgeInsets.symmetric(horizontal: 2),
                ),
                enableActiveFill: true,
                errorTextSpace: 12,
                onChanged: (value) {
                  if (mounted) {
                    setState(() {
                      
                      if (_errorMessage != null) {
                        _errorMessage = null;
                      }
                    });
                  }
                },
              ),
              SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
              Row(
                children: [
                  Text(
                    'Didn\'t receive the OTP',
                    style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                      color: const Color(0xff8E8E8E),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.clockCircle.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
                        height: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
                      ),
                      SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                      Text(
                        _formatTimer(_resendTimer),
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          color: const Color(0xff424242),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            
              GestureDetector(
                onTap: _canResend ? _resendOTP : null,
                child: Text(
                  'Resend',
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                    color: const Color(0xff2372EC),
                  ),
                ),
              ),
              const Spacer(),
              _buildVerifyButton(),
            ] else if (_errorMessage != null) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
                ),
                child: Container(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 12.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
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
                  onPressed: _sendOTPToExistingContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
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
