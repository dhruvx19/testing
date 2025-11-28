import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';

import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';

import 'add_mobile_number.dart';

class VerifyExistingAccount extends StatefulWidget {
  final String? challengeId;
  final String? maskedContact;
  final String? existingPhone;

  const VerifyExistingAccount({
    super.key,
    this.challengeId,
    this.maskedContact,
    this.existingPhone,
  });

  @override
  State<VerifyExistingAccount> createState() => _VerifyExistingAccountState();
}

class _VerifyExistingAccountState extends State<VerifyExistingAccount> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isButtonPressed = false;
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
    // Use provided data or fetch if not available
    if (widget.challengeId != null && widget.maskedContact != null) {
      _challengeId = widget.challengeId;
      _maskedContact = widget.maskedContact;
    } else {
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
      _isLoading = true;
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
          _maskedContact = result['contact']; // Use 'contact' field from new API
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to send OTP';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
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

    setState(() {
      _isButtonPressed = true;
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
        // Navigate to add mobile number screen with verificationToken
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMobileNumber(
              verificationToken: result['verificationToken'],
            ),
          ),
        ).then((_) {
          if (mounted) {
            setState(() {
              _isButtonPressed = false;
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to verify OTP';
          _isButtonPressed = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isButtonPressed = false;
      });
    }
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
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Verify Existing Account',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For your security, please verify your existing account information.',
              style: EcliniqTextStyles.headlineXMedium.copyWith(
            
              ),
            ),
            if (_isLoading && _maskedContact == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(
                    width: 200,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 8),
                  ShimmerLoading(
                    width: 150,
                    height: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              )
            else if (_maskedContact != null)
              Row(
                children: [
                  Text(
                    'OTP sent to ',
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _maskedContact!,
                    style: EcliniqTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
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
            SizedBox(height: 24),
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
                activeColor: Colors.blue,
                selectedColor: Colors.blue,
                inactiveColor: Colors.grey.shade500,
                borderWidth: 1,
                activeBorderWidth: 1,
                selectedBorderWidth: 1,
                inactiveBorderWidth: 1,
                fieldOuterPadding: EdgeInsets.symmetric(horizontal: 4),
              ),
              enableActiveFill: true,
              errorTextSpace: 16,
              onChanged: (value) {
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Didn\'t receive OTP?',
                  style: EcliniqTextStyles.bodyMedium.copyWith(color: Colors.grey.shade500),
                ),
                Spacer(),
                Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.clockCircle.assetPath,
                      width: 16,
                      height: 16,
                    ),
                    SizedBox(width: 4),
                    Text(_formatTimer(_resendTimer), style: EcliniqTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _canResend ? _resendOTP : null,
              child: Text(
                'Resend',
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: _canResend ? Colors.blue.shade800 : Colors.grey,
                ),
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: GestureDetector(
                onTap: _isButtonPressed ? null : _verifyAndProceed,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isButtonPressed
                        ? Color(0xFF0E4395)
                        : (_otpController.text.length == 6)
                        ? Colors.blue.shade800
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Verify & Next',
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
