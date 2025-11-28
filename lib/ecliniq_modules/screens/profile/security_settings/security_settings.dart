import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_email_id/verify_existing_email.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../ecliniq_icons/icons.dart';
import '../../../../ecliniq_api/auth_service.dart';
import '../../../../ecliniq_core/auth/session_service.dart';
import '../../../../ecliniq_core/auth/secure_storage.dart';
import '../../../../ecliniq_core/auth/jwt_decoder.dart';
import 'change_mobile_number/screens/verify_existing_account.dart';

class SecuritySettingsOptions extends StatefulWidget {
  const SecuritySettingsOptions({super.key});

  @override
  State<SecuritySettingsOptions> createState() =>
      _SecuritySettingsOptionsState();
}

class _SecuritySettingsOptionsState extends State<SecuritySettingsOptions> {
  bool isOn = false;
  bool _isExpanded = false;
  bool _isLoadingMobile = false;
  bool _isLoadingEmail = false;
  String? _existingPhone;
  String? _existingEmail;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Get phone from secure storage
      final phone = await SecureStorageService.getPhoneNumber();
      if (phone != null && mounted) {
        setState(() {
          _existingPhone = phone;
        });
      }

      // Try to get email from JWT token
      final authToken = await SessionService.getAuthToken();
      if (authToken != null) {
        final payload = JwtDecoder.decodePayload(authToken);
        if (payload != null && payload['email'] != null && mounted) {
          setState(() {
            _existingEmail = payload['email'].toString();
          });
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> onPressedChangeMobileNumber() async {
    setState(() {
      _isLoadingMobile = true;
    });

    try {
      final authToken = await SessionService.getAuthToken();
      final result = await _authService.sendExistingContactOTP(
        type: 'mobile',
        authToken: authToken,
      );

      if (mounted) {
        setState(() {
          _isLoadingMobile = false;
        });

        if (result['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyExistingAccount(
                challengeId: result['challengeId'],
                maskedContact: result['contact'], // Use 'contact' field from new API
                existingPhone: _existingPhone,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMobile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> onPressedChangeEmail() async {
    setState(() {
      _isLoadingEmail = true;
    });

    try {
      final authToken = await SessionService.getAuthToken();
      final result = await _authService.sendExistingContactOTP(
        type: 'email',
        authToken: authToken,
      );

      if (mounted) {
        setState(() {
          _isLoadingEmail = false;
        });

        if (result['success'] == true) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyExistingEmail(
                challengeId: result['challengeId'],
                maskedContact: result['contact'], // Use 'contact' field from new API
                existingEmail: _existingEmail,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to send OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEmail = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    void handleBiometricPermission() {
      setState(() {
        isOn = !isOn;
      });
    }

    void onPressedChangeBiometricPermissions() {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }

    void onPressedChangeMPin() {}

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
            'Security Settings',
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
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildTile(
              EcliniqIcons.smartphone.assetPath,
              'Change Mobile Number',
              _isLoadingMobile ? null : onPressedChangeMobileNumber,
              _isExpanded,
              isLoading: _isLoadingMobile,
            ),
            Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              height: 1,
            ),
            _buildTile(
              EcliniqIcons.mail.assetPath,
              'Change Email ID',
              _isLoadingEmail ? null : onPressedChangeEmail,
              _isExpanded,
              isLoading: _isLoadingEmail,
            ),
            Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              height: 1,
            ),
            _buildTile(
              EcliniqIcons.password.assetPath,
              'Change M-PIN',
              onPressedChangeMPin,
              _isExpanded,
            ),
            Container(
              color: Colors.grey.shade300,
              width: double.infinity,
              height: 1,
            ),
            _buildTile(
              EcliniqIcons.faceScanSquare.assetPath,
              'Change Biometric Permissions',
              onPressedChangeBiometricPermissions,
              _isExpanded,
            ),
            if (_isExpanded) ...[
              _buildDropDown(isOn, handleBiometricPermission),
            ],

            Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  height: 52,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFF8F8),
                    border: Border.all(color: Color(0xffEB8B85), width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.delete.assetPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Color(0xffF04248),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
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

Widget _buildTile(
  String icon,
  String title,
  VoidCallback? onPressed,
  bool isExpanded, {
  String? subtitle,
  bool isLoading = false,
}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      splashFactory: InkSplash.splashFactory,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      backgroundColor: Colors.white,
    ),
    child: SizedBox(
      height: subtitle != null ? 64 : 48,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(icon, width: 24, height: 24),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EcliniqTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Color(0xff424242),
                        fontSize: 18,
                      ),
                    ),
                    if (subtitle != null && !isLoading) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: EcliniqTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (isLoading) ...[
                      SizedBox(height: 4),
                      ShimmerLoading(
                        width: 120,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ],
                ),
              ),
              (title != 'Change Biometric Permissions')
                  ? SvgPicture.asset(
                      EcliniqIcons.angleRight.assetPath,
                      width: 24,
                      height: 24,
                    )
                  : (!isExpanded)
                  ? SvgPicture.asset(
                      EcliniqIcons.angleRight.assetPath,
                      width: 24,
                      height: 24,
                    )
                  : SvgPicture.asset(
                      EcliniqIcons.angleDown.assetPath,
                      width: 24,
                      height: 24,
                    ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildDropDown(bool isOn, VoidCallback onPressed) {
  return Column(
    children: [
      Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Face Lock Permission',
                style: EcliniqTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Color(0xff424242),
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              FittedBox(
                child: Text(
                  'Keep it turn ON to unlock app quickly without \ninputting m-pin. ',
                  overflow: TextOverflow.visible,
                  style: EcliniqTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Color(0xff8E8E8E),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          SizedBox(
            width: 40,
            height: 23,
            child: GestureDetector(
              onTap: onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 60,
                height: 30,
                decoration: BoxDecoration(
                  color: isOn ? Color(0xff0D47A1) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment: isOn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  curve: Curves.easeInOut,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      Divider(),
    ],
  );
}
