import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/mpin/set_mpin.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/user_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/login.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _otpController.removeListener(_onOtpChanged);
    super.dispose();
    _otpController.dispose();
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

      // Use forget MPIN verify API if it's forget PIN flow, otherwise use normal verify
      final success = widget.isForgotPinFlow
          ? await authProvider.forgetMpinVerifyOtp(otp)
          : await authProvider.verifyOTP(otp);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSuccessSnackBar(
              title: 'OTP verified successfully!',
              subtitle: widget.isForgotPinFlow
                  ? 'You can now reset your MPIN'
                  : 'Your account has been verified successfully',
              context: context,
            ),
          );
          
          // Route based on flow type
          if (widget.isForgotPinFlow) {
            // Forgot PIN flow: OTP verified → Reset MPIN
            // Check if user is authenticated (change MPIN from settings) or not (forget PIN from login)
            final hasValidSession = await SessionService.hasValidSession();
            if (hasValidSession) {
              // User is authenticated - this is change MPIN from security settings
              // Use push instead of pushAndRemoveUntil to preserve navigation stack
              EcliniqRouter.push(
                const MPINSet(isResetMode: true),
              );
            } else {
              // User is not authenticated - this is forget PIN from login
              // Use pushAndRemoveUntil to clear navigation stack
              EcliniqRouter.pushAndRemoveUntil(
                const MPINSet(isResetMode: true),
                (route) => route.isFirst,
              );
            }
          } else {
            // Normal flow: Check if user needs to set MPIN
            final hasMPIN = await SecureStorageService.hasMPIN();
            
            if (!hasMPIN) {
              // New user: No MPIN set → Set MPIN → Biometric Setup → Onboarding
              EcliniqRouter.pushAndRemoveUntil(
                const MPINSet(),
                (route) => route.isFirst,
              );
            } else {
              // Returning user: MPIN exists → Navigate to Login Page (not VerifyMPINPage)
              // User can enter MPIN or use biometric on login page
              // This handles token expiration case - user already has MPIN, just needs to re-authenticate
              EcliniqRouter.pushAndRemoveUntil(
                const UserDetails (),
                (route) => route.isFirst,
              );
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
    setState(() {
      _isButtonPressed = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Use forget MPIN resend if it's forget PIN flow, otherwise use normal resend
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
    }
  }

  Widget _buildVerifyButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isButtonEnabled =
            _otpController.text.length == 6 && !authProvider.isLoading;

        return SizedBox(
          width: double.infinity,
          height: 46,
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Verify & Next',
                    style: EcliniqTextStyles.titleXLarge.copyWith(
                      color: _isButtonPressed
                          ? Colors.white
                          : isButtonEnabled
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: _isButtonPressed
                        ? Colors.white
                        : isButtonEnabled
                        ? Colors.white
                        : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return EcliniqScaffold(
          backgroundColor: EcliniqScaffold.primaryBlue,
          body: SizedBox.expand(
            child: Column(
              children: [
                SizedBox(height: 40),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        authProvider.clearSession();
                        EcliniqRouter.pop();
                      },
                      icon: Image.asset(
                        EcliniqIcons.arrowBack.assetPath,
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      label: const Text(
                        'Help',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Enter the 6-digit OTP sent to',
                                  style: EcliniqTextStyles.headlineMedium,
                                ),
                                Text(
                                  '+91 ${authProvider.phoneNumber ?? 'your phone'}',
                                  style: EcliniqTextStyles.headlineMedium,
                                ),
                                const SizedBox(height: 20),
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
                                    fieldHeight: 48,
                                    fieldWidth: 40,
                                    activeFillColor: Colors.white,
                                    selectedFillColor: Colors.white,
                                    inactiveFillColor: Colors.white,
                                    activeColor: Colors.blue,
                                    selectedColor: Colors.blue,
                                    inactiveColor: Colors.grey.shade300,
                                    borderWidth: 1,
                                    fieldOuterPadding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  enableActiveFill: true,
                                  errorTextSpace: 16,
                                  onChanged: (value) {},
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: authProvider.isLoading
                                      ? null
                                      : _resendOTP,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Didn\'t receive the OTP?',
                                        style: EcliniqTextStyles.bodySmall
                                            .copyWith(color: Colors.grey),
                                      ),
                                      Text(
                                        _isButtonPressed
                                            ? 'Resending...'
                                            : 'Resend',
                                        style: EcliniqTextStyles.bodyMedium
                                            .copyWith(color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(24),
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
