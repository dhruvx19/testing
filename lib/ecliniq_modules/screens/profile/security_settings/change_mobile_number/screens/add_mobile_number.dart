import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_mobile_number/screens/verify_new_mobile_number.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddMobileNumber extends StatefulWidget {
  final String verificationToken;

  const AddMobileNumber({super.key, required this.verificationToken});

  @override
  State<AddMobileNumber> createState() => _AddMobileNumberState();
}

class _AddMobileNumberState extends State<AddMobileNumber> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isButtonPressed = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestNewOTP() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      
    
CustomErrorSnackBar.show(
          title: 'Invalid mobile number',
          subtitle: 'Please enter a valid 10-digit mobile number',
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
      
      final result = await _authService.sendNewContactOtp(
        type: 'mobile',
        newContact: _phoneController.text,
        authToken: authToken,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _isLoading = false;
        });

        
        final verifyResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyNewMobileNumber(
              newChallengeId: result['challengeId'],
              newMobileNumber: _phoneController.text,
            ),
          ),
        );

        
        if (verifyResult != null && mounted) {
          Navigator.pop(context, verifyResult);
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        
        if (mounted) {
     CustomErrorSnackBar.show(
  
              title: 'Failed to send OTP',
              subtitle: result['message'] ?? 'Failed to send OTP to new mobile',
              context: context,
       
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      
      if (mounted) {
        
  CustomErrorSnackBar.show(
            title: 'Error',
            subtitle: 'An error occurred: $e',
            context: context,
          
        );
      }
    }
  }

  bool get _isPhoneValid => _phoneController.text.length == 10;

  Widget _buildContinueButton() {
    final isButtonEnabled = _isPhoneValid && !_isLoading;

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
                ? const Color(0xFF0E4395) 
                : _isPhoneValid
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
                        'Continue',
                        style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                          color: _isPhoneValid
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
                          _isPhoneValid
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
            'Add Mobile Number',
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new mobile number, and we will send an OTP for verification.',
              style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: Color(0xff424242),
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_phoneFocusNode);
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xff626060), width: 0.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 12,
                        top: 12,
                        bottom: 12,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '+91',
                            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                              fontWeight: FontWeight.w400,
                              color: Color(0xff424242),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SvgPicture.asset(
                            EcliniqIcons.arrowDown.assetPath,
                            width: 16,
                            height: 16,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32, color: Color(0xffD6D6D6)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          autofocus: true,
                          maxLength: 10,
                          style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff424242),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mobile Number',
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            hintStyle: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                                .copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xffD6D6D6),
                                ),
                          ),
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
                        color: Color(0xff8E8E8E),
                        fontWeight: FontWeight.w400,
                  
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
