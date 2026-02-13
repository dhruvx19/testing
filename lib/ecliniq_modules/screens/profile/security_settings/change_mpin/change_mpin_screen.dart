import 'dart:async';

import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/mpin/set_mpin.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
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
    
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      if (widget.preloadedPhoneNumber != null &&
          widget.preloadedMaskedPhone != null) {
        _phoneNumber = widget.preloadedPhoneNumber;
        _maskedPhone = widget.preloadedMaskedPhone;
        
        _sendOTP();
      } else {
        
        _loadPhoneNumberAndSendOTP();
      }
    });
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_phoneNumber == null) {
        final phone = await SecureStorageService.getPhoneNumber();

        if (!mounted) return;
        if (phone == null || phone.isEmpty) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Phone number not found. Please try again.';
            _isLoading = false;
          });
          return;
        }

        String phoneNumber = phone.replaceAll(RegExp(r'^\+?91'), '').trim();

        if (!mounted) return;
        if (phoneNumber.length != 10) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Invalid phone number format.';
            _isLoading = false;
          });
          return;
        }

        _maskedPhone = '******${phoneNumber.substring(phoneNumber.length - 4)}';
        _phoneNumber = phoneNumber;
      }

      
      if (!mounted) return;
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
    if (!mounted) return;

    if (_phoneNumber == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Phone number is required';
      });
      return;
    }

    if (!mounted) return;
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
        if (!mounted) return;
        setState(() {
          _isSendingOTP = false;
        });
        if (mounted) {
          _startTimer();
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isSendingOTP = false;
        });

        
        if (mounted && context.mounted) {
    CustomErrorSnackBar.show(
              title: 'Failed to send OTP',
              subtitle: authProvider.errorMessage ?? 'Failed to send OTP',
              context: context,
            
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOTP = false;
      });

      
      if (mounted && context.mounted) {

  CustomErrorSnackBar.show(
            title: 'Error',
            subtitle: 'An error occurred: ${e.toString()}',
            context: context,
          
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    await _sendOTP();
  }

  Future<void> _verifyAndProceed() async {
    if (!mounted) return;

    
    try {
      if (_otpController.text.length != 6) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Please enter a valid 6-digit OTP';
        });
        return;
      }
    } catch (e) {
      
      return;
    }

    
    if (_isVerifying) return;

    if (!mounted) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      String otpText;
      try {
        otpText = _otpController.text;
      } catch (e) {
        
        return;
      }

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgetMpinVerifyOtp(otpText);

      if (!mounted) return;

      if (success) {
        
        setState(() {
          _isVerifying = false;
        });

        
        
        if (!mounted) return;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MPINSet(isResetMode: true),
          ),
        );

        
        
        if (!mounted) return;
        if (result == true) {
          
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted || !context.mounted) return;
          
          Navigator.pop(context, true);
        } else {
          
          if (mounted && context.mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
        });
        if (mounted) {
          try {
            _otpController.clear(); 
          } catch (e) {
            
          }
        }

        
        if (mounted && context.mounted) {
         CustomErrorSnackBar.show(
        
              title: 'Failed to verify OTP',
              subtitle: authProvider.errorMessage ?? 'Failed to verify OTP',
              context: context,
        
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });
      if (mounted) {
        try {
          _otpController.clear(); 
        } catch (e) {
          
        }
      }

      
      if (mounted && context.mounted) {
 
CustomErrorSnackBar.show(
            title: 'Error',
            subtitle: 'An error occurred: $e',
            context: context,
       
        );
      }
    }
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _isOtpValid {
    try {
      return _otpController.text.length == 6;
    } catch (e) {
      return false;
    }
  }

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
            'Change M-PIN',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: const Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
          child: Container(
            color: const Color(0xFFB8B8B8),
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
            if (_maskedPhone != null) ...[
              Row(
                children: [
                  Text(
                    'OTP sent to ',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                      fontWeight: FontWeight.w400,

                      color: const Color(0xff424242),
                    ),
                  ),
                  Text(
                    '+91 $_phoneNumber',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
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
                textStyle: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                  color: const Color(0xff424242),
                ),
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
                  if (!mounted) return;
                  try {
                    if (_otpController.text.isNotEmpty) {
                      setState(() {
                        
                        if (_errorMessage != null) {
                          _errorMessage = null;
                        }
                      });
                    }
                  } catch (e) {
                    
                  }
                },
                onCompleted: (value) {
                  
                  
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
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
                      ),
                      SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
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
              SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
              SizedBox(
                width: double.infinity,
                height: EcliniqTextStyles.getResponsiveButtonHeight(context, baseHeight: 46.0),
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
