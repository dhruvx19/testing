import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/main_flow/otp_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class ChangeMPINScreen extends StatefulWidget {
  const ChangeMPINScreen({super.key});

  @override
  State<ChangeMPINScreen> createState() => _ChangeMPINScreenState();
}

class _ChangeMPINScreenState extends State<ChangeMPINScreen> {
  bool _isLoading = false;
  bool _isSendingOTP = false;
  String? _errorMessage;
  String? _phoneNumber;
  String? _maskedPhone;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumberAndSendOTP();
  }

  Future<void> _loadPhoneNumberAndSendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get phone number from secure storage
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

      // Send OTP using forget MPIN API (same backend flow as change MPIN)
      setState(() {
        _isSendingOTP = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.forgetMpinSendOtp(phoneNumber);

      if (!mounted) return;

      if (success) {
        // Navigate to OTP screen and pop this screen
        // The OTP screen will handle navigation to MPIN set screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OtpInputScreen(isForgotPinFlow: true),
            ),
          );
        }
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
            else if (_maskedPhone != null)
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
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
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
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
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
              ),
          ],
        ),
      ),
    );
  }
}

