import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/security_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';

import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

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
  String? _errorMessage;
  Timer? _timer;
  int _resendTimer = 150;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
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
        setState(() {
          _resendTimer--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
      // Step 4: Verify new contact OTP (type is stored in Redis from step 3)
      final result = await _authService.verifyNewContact(
        challengeId: widget.newChallengeId,
        otp: _otpController.text,
        authToken: authToken,
      );

      if (result['success'] == true) {
        // Show success message and navigate back to security settings
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Mobile number changed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => SecuritySettingsOptions()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to verify new mobile number';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
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
              'Please Verify your new  account information.',
              style: EcliniqTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
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
                  widget.newMobileNumber,
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
              onChanged: (value) {},
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Didn\'t receive OTP?',
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade500
                  ),
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
              onTap: _canResend ? () {
                // Resend functionality can be added here if needed
                setState(() {
                  _canResend = false;
                  _resendTimer = 150;
                });
                _startTimer();
              } : null,
              child: Text(
                'Resend',
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: _canResend ? Colors.blue.shade800 : Colors.grey,
                ),
              ),
            ),
            Spacer(),
            if (_isLoading)
              Center(
                child: EcliniqLoader(),
              )
            else
              TextButton(
                onPressed: _verifyAndComplete,

              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  Colors.blue.shade800,
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                minimumSize: MaterialStateProperty.all(
                  Size(double.infinity, 48),
                ),
              ),
              child: Container(
                height: 26,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify & Update',
                        style: EcliniqTextStyles.headlineXMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SvgPicture.asset(
                        EcliniqIcons.arrowRightWhite.assetPath,
                        width: 24,
                        height: 24,
                      ),
                    ],
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
