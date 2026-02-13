import 'dart:async';

import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/security_settings.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyNewMobileNumber extends StatefulWidget {
  final String newChallengeId;
  final String newMobileNumber;

  const VerifyNewMobileNumber({
    super.key,
    required this.newChallengeId,
    required this.newMobileNumber,
  });

  @override
  State<VerifyNewMobileNumber> createState() => _VerifyNewMobileNumberState();
}

class _VerifyNewMobileNumberState extends State<VerifyNewMobileNumber> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isButtonPressed = false;
  String? _errorMessage;
  Timer? _timer;
  int _resendTimer = 150;
  bool _canResend = false;
  String _currentChallengeId = '';

  @override
  void initState() {
    super.initState();
    _currentChallengeId = widget.newChallengeId;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOTP() async {
    if (!_canResend || !mounted) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      final authToken = await SessionService.getAuthToken();
      
      final result = await _authService.sendNewContactOtp(
        type: 'mobile',
        newContact: widget.newMobileNumber,
        authToken: authToken,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _currentChallengeId = result['challengeId'];
          _canResend = false;
          _resendTimer = 150;
          _otpController.clear();
        });
        _startTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP has been resent'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to resend OTP';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _verifyAndComplete() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authToken = await SessionService.getAuthToken();
      
      final result = await _authService.verifyNewContact(
        challengeId: _currentChallengeId,
        otp: _otpController.text,
        authToken: authToken,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isLoading = false;
        });

        
        
        
        Navigator.pop(context, {'success': true, 'type': 'phone'});
      } else {
        setState(() {
          _errorMessage =
              result['message'] ?? 'Failed to verify new mobile number';
          _isLoading = false;
          _otpController.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
        _otpController.clear();
      });
    }
  }

  bool get _isOtpValid => _otpController.text.length == 6;

  Widget _buildVerifyButton() {
    final isButtonEnabled = _isOtpValid && !_isLoading;

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
                _verifyAndComplete();
              }
            : null,
        onTapCancel: isButtonEnabled
            ? () => setState(() => _isButtonPressed = false)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isLoading
                ? const Color(0xFF2372EC)
                : _isButtonPressed
                ? const Color(0xFF0E4395) 
                : _isOtpValid
                ? const Color(0xFF2372EC) 
                : const Color(0xffF9F9F9), 
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: EcliniqLoader(color: Colors.white, size: 24),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify & Update',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leadingWidth: 58,
        titleSpacing: 0,
        toolbarHeight: 38,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Verify Existing Account',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
          child: Container(
            color: Color(0xFFB8B8B8),
            height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
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
              'Please Verify your new  account information.',
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: Color(0xff424242),
              ),
            ),
            Row(
              children: [
                Text(
                  'OTP sent to ',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                  
                    color: Color(0xff424242),
                  ),
                ),
                Text(
                  '+91 ${widget.newMobileNumber}',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                  
                    color: Color(0xff424242),
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
              textStyle: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: const Color(0xff424242),
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
                selectedBorderWidth: 1,
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
                Spacer(),
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
                        color: Color(0xff424242),
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
                  color: _canResend ? const Color(0xff2372EC) : Colors.grey,
                ),
              ),
            ),
            Spacer(),
            _buildVerifyButton(),
          ],
        ),
      ),
    );
  }
}
