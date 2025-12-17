import 'dart:async';

import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/mpin/set_mpin.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

class ChangeMPINScreen extends StatefulWidget {
  const ChangeMPINScreen({super.key});

  @override
  State<ChangeMPINScreen> createState() => _ChangeMPINScreenState();
}

class _ChangeMPINScreenState extends State<ChangeMPINScreen> {
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSendingOTP = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _phoneNumber;
  String? _maskedPhone;
  
  Timer? _timer;
  int _resendTimer = 30; // 30 seconds
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumberAndSendOTP();
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
      // Get phone number from secure storage if not already loaded
      if (_phoneNumber == null) {
        final phone = await SecureStorageService.getPhoneNumber();
        
        if (phone == null || phone.isEmpty) {
          setState(() {
            _errorMessage = 'Phone number not found. Please try again.';
            _isLoading = false;
          });
          return;
        }

        // Remove country code if present
        String phoneNumber = phone.replaceAll(RegExp(r'^\+?91'), '').trim();
        
        if (phoneNumber.length != 10) {
          setState(() {
            _errorMessage = 'Invalid phone number format.';
            _isLoading = false;
          });
          return;
        }

        // Mask phone number for display (show last 4 digits)
        _maskedPhone = '******${phoneNumber.substring(phoneNumber.length - 4)}';
        _phoneNumber = phoneNumber;
      }

      // Send OTP using forget MPIN API (same backend flow as change MPIN)
      setState(() {
        _isSendingOTP = true;
      });

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgetMpinSendOtp(_phoneNumber!);

      if (!mounted) return;

      if (success) {
        // Update state to show OTP sent
        setState(() {
          _isLoading = false;
          _isSendingOTP = false;
        });
        
        _startTimer();
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Failed to send OTP';
          _isLoading = false;
          _isSendingOTP = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
        _isSendingOTP = false;
      });
    }
  }

  Future<void> _resendOTP() async {
     if (!_canResend) return;
     await _loadPhoneNumberAndSendOTP();
  }

  Future<void> _verifyAndProceed() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgetMpinVerifyOtp(_otpController.text);

      if (!mounted) return;

      if (success) {
          // Navigate to Set MPIN Screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
               builder: (context) => const MPINSet(isResetMode: true),
            ),
          );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Failed to verify OTP';
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isVerifying = false;
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
            'Change M-PIN',
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
              'For your security, please verify your mobile number to change your M-PIN.',
              style: EcliniqTextStyles.headlineXMedium.copyWith(
                color: Color(0xff424242),
              ),
            ),
            if (_isLoading || _isSendingOTP)
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
                    SizedBox(height: 8),
                    ShimmerLoading(
                      width: 150,
                      height: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              )
            else if (_maskedPhone != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'OTP sent to ',
                        style: EcliniqTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Color(0xff424242),
                        ),
                      ),
                      Text(
                        '+91 $_maskedPhone',
                        style: EcliniqTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
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
                    activeColor: Color(0xff2372EC),
                    selectedColor: Colors.blue,
                    inactiveColor: Colors.grey.shade500,
                    borderWidth: 1,
                    activeBorderWidth: 0.5,
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
                      'Didn’t receive the OTP',
                      style: EcliniqTextStyles.bodySmall.copyWith(
                        color: Color(0xff8E8E8E),
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
                        Text(
                          _formatTimer(_resendTimer),
                          style: EcliniqTextStyles.bodyMedium.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
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
                      color: _canResend ? Color(0xff2372EC) : Colors.grey,
                    ),
                  ),
                ),
                Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: GestureDetector(
                    onTap: _isVerifying ? null : _verifyAndProceed,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isVerifying
                            ? Color(0xFF0E4395)
                            : (_otpController.text.length == 6)
                            ? Colors.blue.shade800
                            : Color(0xffF9F9F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: _isVerifying
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: EcliniqLoader(
                                  color: Colors.white,
                                  size: 24,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Verify & Next',
                                    style: EcliniqTextStyles.headlineMedium.copyWith(
                                      color: (_otpController.text.length == 6)
                                          ? Color(0xffffffff)
                                          : Color(0xffD6D6D6),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  SvgPicture.asset(
                                    EcliniqIcons.arrowRight.assetPath,
                                    width: 24,
                                    height: 24,
                                    color: (_otpController.text.length == 6)
                                        ? Color(0xffffffff)
                                        : Color(0xff8E8E8E),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
            ] else if (_errorMessage != null) ...[
                // Error state (phone number load fail)
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
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
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
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _loadPhoneNumberAndSendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff0D47A1),
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
