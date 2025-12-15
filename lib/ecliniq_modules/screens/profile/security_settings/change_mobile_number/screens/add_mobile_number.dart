import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_mobile_number/screens/verify_new_mobile_number.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ecliniq/ecliniq_api/auth_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

class AddMobileNumber extends StatefulWidget {
  final String verificationToken;

  const AddMobileNumber({
    super.key,
    required this.verificationToken,
  });

  @override
  State<AddMobileNumber> createState() => _AddMobileNumberState();
}

class _AddMobileNumberState extends State<AddMobileNumber> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _requestNewOTP() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 10) {
      setState(() {
        _errorMessage = 'Please enter a valid mobile number';
      });
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
        type: 'mobile',
        newContact: _phoneController.text,
        authToken: authToken,
      );

      if (result['success'] == true) {
        // Navigate to verify new mobile screen with new challengeId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyNewMobileNumber(
              newChallengeId: result['challengeId'],
              newMobileNumber: _phoneController.text,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to send OTP to new mobile';
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
            'Add Mobile Number',
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
              'Enter a new mobile number, and we will send an OTP for verification.',
              style: EcliniqTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Mobile Number',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage!,
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'By Continuing, you agree to our',
                  style: EcliniqTextStyles.bodySmall.copyWith(
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Terms & Conditions',
                      style: EcliniqTextStyles.headlineMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      ' and ',
                      style: EcliniqTextStyles.bodySmall.copyWith(
                        color: Colors.grey,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      'Privacy Policy',
                      style: EcliniqTextStyles.headlineMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Spacer(),
            if (_isLoading)
              Center(
                child: EcliniqLoader(),
              )
            else
              TextButton(
                onPressed: _requestNewOTP,

              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue.shade800),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                minimumSize: WidgetStateProperty.all(Size(double.infinity, 48)),
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
                        'Continue',
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
