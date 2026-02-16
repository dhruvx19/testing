import 'dart:async';

import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/mpin/set_mpin.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/user_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login_trouble.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

class OtpInputScreen extends StatefulWidget {
  final bool isForgotPinFlow;

  const OtpInputScreen({super.key, this.isForgotPinFlow = false});

  @override
  State<OtpInputScreen> createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends State<OtpInputScreen>
    with WidgetsBindingObserver {
  final TextEditingController _otpController = TextEditingController();
  bool _isButtonPressed = false;
  int _resendTimer = 150; 
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _otpController.removeListener(_onOtpChanged);
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _resendTimer = 150; 

    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResend = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isButtonPressed) {
      setState(() {
        _isButtonPressed = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isButtonPressed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isButtonPressed = false;
          });
        }
      });
    }
  }

  void _onOtpChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _verifyOTP() async {
    final rawOtp = _otpController.text;
    final otp = rawOtp.replaceAll(RegExp(r'[^0-9]'), '').trim();

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() {
      _isButtonPressed = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number is missing. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isButtonPressed = false;
        });
        return;
      }

      
      final success = widget.isForgotPinFlow
          ? await authProvider.forgetMpinVerifyOtp(otp)
          : await authProvider.verifyOTP(otp);

      if (mounted) {
        if (success) {
   
            CustomSuccessSnackBar.show(
              title: 'OTP verified successfully!',
              subtitle: widget.isForgotPinFlow
                  ? 'You can now reset your MPIN'
                  : 'Your account has been verified successfully',
              context: context,
         
          );

          
          if (widget.isForgotPinFlow) {
            
            
            final hasValidSession = await SessionService.hasValidSession();
            if (hasValidSession) {
              
              
              await SessionService.saveFlowState('mpin_reset');
              EcliniqRouter.push(const MPINSet(isResetMode: true));
            } else {
              
              
              await SessionService.saveFlowState('mpin_reset');
              EcliniqRouter.pushAndRemoveUntil(
                const MPINSet(isResetMode: true),
                (route) => route.isFirst,
              );
            }
          } else {
            
            final redirectTo = authProvider.redirectTo;
            final userStatus = authProvider.userStatus;

            
            
            final isNewUser =
                userStatus == 'new' || redirectTo == 'profile_setup';

            if (isNewUser) {
              
              
              await SecureStorageService.deleteMPIN();

              
              await SessionService.saveFlowState('mpin_setup');
              EcliniqRouter.pushAndRemoveUntil(
                const MPINSet(),
                (route) => route.isFirst,
              );
            } else {
              
              final hasMPIN = await SecureStorageService.hasMPIN();

              if (!hasMPIN) {
                
                await SessionService.saveFlowState('mpin_setup');
                EcliniqRouter.pushAndRemoveUntil(
                  const MPINSet(),
                  (route) => route.isFirst,
                );
              } else {
                
                
                await SessionService.clearFlowState(); 
                EcliniqRouter.pushAndRemoveUntil(
                  LoginPage(
                    phoneNumber: authProvider.phoneNumber,
                    showSelectionMode: true,
                  ),
                  (route) => route.isFirst,
                );
              }
            }
          }
        } else {
          setState(() {
            _isButtonPressed = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                authProvider.errorMessage ?? 'OTP verification failed',
              ),
              backgroundColor: Colors.red,
            ),
          );
          _otpController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isButtonPressed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resendOTP() async {
    if (!_canResend) return; 

    setState(() {
      _isButtonPressed = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    
    if (widget.isForgotPinFlow) {
      final phoneNumber = authProvider.phoneNumber;
      if (phoneNumber != null) {
        await authProvider.forgetMpinSendOtp(phoneNumber);
      }
    } else {
      await authProvider.resendOTP();
    }

    if (mounted) {
      setState(() {
        _isButtonPressed = false;
      });
      _startTimer(); 
      _otpController.clear(); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has been resent'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildVerifyButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isButtonEnabled =
            _otpController.text.length == 6 && !authProvider.isLoading;

        return SizedBox(
          width: double.infinity,
          height: EcliniqTextStyles.getResponsiveButtonHeight(
            context,
            baseHeight: 52.0,
          ),
          child: GestureDetector(
            onTap: isButtonEnabled ? _verifyOTP : null,
            child: Container(
              decoration: BoxDecoration(
                color: _isButtonPressed
                    ? Color(0xFF0E4395)
                    : isButtonEnabled
                    ? EcliniqButtonType.brandPrimary.backgroundColor(context)
                    : EcliniqButtonType.brandPrimary.disabledBackgroundColor(
                        context,
                      ),
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verify & Next',
                    style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                      color: _isButtonPressed
                          ? Colors.white
                          : isButtonEnabled
                          ? Colors.white
                          : Color(0xffD6D6D6),
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  SvgPicture.asset(
                    EcliniqIcons.arrowRightWhite.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                    color: _isButtonPressed
                        ? Colors.white
                        : isButtonEnabled
                        ? Colors.white
                        : Color(0xff8E8E8E),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimer(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return EcliniqScaffold(
          backgroundColor: EcliniqScaffold.primaryBlue,
          resizeToAvoidBottomInset: true,
          body: SizedBox.expand(
            child: Column(
              children: [
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 52),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: SvgPicture.asset(
                        EcliniqIcons.reply.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                        height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => EcliniqRouter.push(LoginTroublePage()),
                      child: FadeTransition(
                        opacity: AlwaysStoppedAnimation(1.0),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              EcliniqIcons.questionCircleWhite.assetPath,
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Help',
                              style: EcliniqTextStyles.responsiveHeadlineXLMedium(context)
                                  .copyWith(
                                    color: Colors.white,

                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                              context,
                              top: 24,
                              left: 18,
                              right: 18,
                              bottom: 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enter the 6-digit OTP sent to',
                                  style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                                      .copyWith(
                                        color: Color(0xff424242),
                                        fontWeight: FontWeight.w400,
                                      ),
                                ),
                                SizedBox(
                                  height: EcliniqTextStyles.getResponsiveSpacing(context, 2),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '+91 ${authProvider.phoneNumber ?? 'your phone'}',
                                      style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                                          .copyWith(color: Color(0xff424242)),
                                    ),
                                    SizedBox(
                                      width: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                                    ),
                                    GestureDetector(
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Text(
                                        'Change Number',
                                        style: EcliniqTextStyles.responsiveBodySmall(context)
                                            .copyWith(color: Color(0xff2372EC)),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(
                                  height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
                                ),
                                PinCodeTextField(
                                  appContext: context,
                                  length: 6,
                                  controller: _otpController,
                                  autoFocus: true,
                                  keyboardType: TextInputType.number,
                                  animationType: AnimationType.fade,
                                  textStyle: EcliniqTextStyles.responsiveHeadlineZMedium(context)
                                      .copyWith(
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
                                    fieldWidth: EcliniqTextStyles.getResponsiveWidth(context, 45),
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
                                    fieldOuterPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                  ),

                                  animationDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  enableActiveFill: true,
                                  errorTextSpace: 0,
                                  onChanged: (value) {},
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Text(
                                      'Didn\'t receive the OTP?',
                                      style: EcliniqTextStyles.responsiveBodySmall(context)
                                          .copyWith(
                                            color: const Color(0xff8E8E8E),
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
                                            _formatTimer(_resendTimer),
                                            style: EcliniqTextStyles.responsiveBodySmall(context)
                                                .copyWith(
                                                  color: const Color(
                                                    0xff424242,
                                                  ),
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
                                    style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                                        .copyWith(
                                          color: const Color(0xff2372EC),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            right: 18,
                            left: 18,
                            bottom: 24,
                          ),
                          child: _buildVerifyButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
