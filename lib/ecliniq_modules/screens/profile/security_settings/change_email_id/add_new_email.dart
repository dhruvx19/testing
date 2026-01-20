import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_email_id/verify_new_email.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddEmailAddress extends StatefulWidget {
  final String verificationToken;

  const AddEmailAddress({super.key, required this.verificationToken});

  @override
  State<AddEmailAddress> createState() => _AddEmailAddressState();
}

class _AddEmailAddressState extends State<AddEmailAddress> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isButtonPressed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestNewOTP() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      // Show validation error as snackbar
      
  CustomErrorSnackBar.show(
          title: 'Invalid email address',
          subtitle: 'Please enter a valid email address',
          context: context,
        
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authToken = await SessionService.getAuthToken();
      // Step 3: Send OTP to new contact (verificationToken is checked automatically by backend)
      final result = await _authService.sendNewContactOtp(
        type: 'email',
        newContact: _emailController.text,
        authToken: authToken,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isLoading = false;
        });

        // Navigate to verify new email screen with new challengeId
        final verifyResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyNewEmailAddress(
              newChallengeId: result['challengeId'],
              newEmail: _emailController.text,
            ),
          ),
        );

        // Pass result back to previous screen
        if (verifyResult != null && mounted) {
          Navigator.pop(context, verifyResult);
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        // Show error snackbar instead of inline error
        if (mounted) {
 
   CustomErrorSnackBar.show(
              title: 'Failed to send OTP',
              subtitle: result['message'] ?? 'Failed to send OTP to new email',
              context: context,
      
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Show error snackbar for exceptions
      if (mounted) {
CustomErrorSnackBar.show(
            title: 'Error',
            subtitle: 'An error occurred: $e',
            context: context,
   
        );
      }
    }
  }

  bool get _isEmailValid =>
      _emailController.text.isNotEmpty && _emailController.text.contains('@');

  Widget _buildContinueButton() {
    final isButtonEnabled = _isEmailValid && !_isLoading;

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
                _requestNewOTP();
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
                ? const Color(0xFF0E4395) // Pressed color
                : _isEmailValid
                ? const Color(0xFF2372EC) // Enabled color
                : const Color(0xffF9F9F9), // Disabled color
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
                        'Continue',
                        style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                          color: _isEmailValid
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
                          _isEmailValid
                              ? Colors.white
                              : const Color(0xff8E8E8E),
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
          'Add Email Address',
          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
            color: Color(0xff424242),
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new Email Address, and we will send an OTP for verification.',
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: Color(0xff424242),
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xff626060), width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          autofocus: true,
                          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff424242),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter Email',
                            contentPadding: EdgeInsets.zero,
                            hintStyle: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                                .copyWith(
                                  color: Color(0xffD6D6D6),

                                  fontWeight: FontWeight.w400,
                                ),
                          ),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
            SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'By Continuing, you agree to our',
                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                    color: Color(0xff8E8E8E),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: Color(0xff424242),
                      ),
                    ),
                    Text(
                      ' and ',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: Color(0xff8E8E8E),
                      ),
                    ),
                    Text(
                      'Privacy Policy',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: Color(0xff424242),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }
}
