import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_email_id/verify_existing_email.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_mpin/change_mpin_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
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
  bool _isInitialLoading = true;
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
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> onPressedChangeMobileNumber() async {
    // Show loader while navigating
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(child: EcliniqLoader()),
    );

    // Navigate immediately, API call happens in background on next page
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyExistingAccount(
            challengeId: null, // Will trigger API call on next page
            maskedContact: null,
            existingPhone: _existingPhone,
          ),
        ),
      );

      // Dismiss loader when navigation completes
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> onPressedChangeEmail() async {
    // Show loader while navigating
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(child: EcliniqLoader()),
    );

    // Navigate immediately, API call happens in background on next page
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyExistingEmail(
            challengeId: null, // Will trigger API call on next page
            maskedContact: null,
            existingEmail: _existingEmail,
          ),
        ),
      );

      // Dismiss loader when navigation completes
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
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

    Future<void> onPressedChangeMPin() async {
      // Preload phone number before navigating
      String? phoneNumber;
      String? maskedPhone;

      try {
        final phone = await SecureStorageService.getPhoneNumber();
        if (phone != null && phone.isNotEmpty) {
          String processedPhone = phone
              .replaceAll(RegExp(r'^\+?91'), '')
              .trim();
          if (processedPhone.length == 10) {
            phoneNumber = processedPhone;
            maskedPhone =
                '******${processedPhone.substring(processedPhone.length - 4)}';
          }
        }
      } catch (e) {
        print('Error loading phone number: $e');
      }

      // Navigate to change MPIN screen with preloaded phone number
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeMPINScreen(
              preloadedPhoneNumber: phoneNumber,
              preloadedMaskedPhone: maskedPhone,
            ),
          ),
        );
      }
    }

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
      body: _isInitialLoading
          ? Center(child: EcliniqLoader(size: 20))
          : Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildTile(
                    EcliniqIcons.smartphone.assetPath,
                    'Change Mobile Number',
                    onPressedChangeMobileNumber,
                    _isExpanded,
                  ),
                  Container(
                    color: Color(0xffD6D6D6),
                    width: double.infinity,
                    height: 0.5,
                  ),
                  _buildTile(
                    EcliniqIcons.mail.assetPath,
                    'Change Email ID',
                    onPressedChangeEmail,
                    _isExpanded,
                  ),
                  Container(
                    color: Color(0xffD6D6D6),
                    width: double.infinity,
                    height: 0.5,
                  ),
                  _buildTile(
                    EcliniqIcons.password.assetPath,
                    'Change M-PIN',
                    onPressedChangeMPin,
                    _isExpanded,
                  ),
                  Container(
                    color: Color(0xffD6D6D6),
                    width: double.infinity,
                    height: 0.5,
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
                          border: Border.all(
                            color: Color(0xffEB8B85),
                            width: 0.5,
                          ),
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
                    if (subtitle != null) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: EcliniqTextStyles.bodySmall.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
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
                      colorFilter: ColorFilter.mode(
                        Color(0xff424242),
                        BlendMode.srcIn,
                      ),
                    )
                  : (!isExpanded)
                  ? SvgPicture.asset(
                      EcliniqIcons.angleRight.assetPath,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Color(0xff424242),
                        BlendMode.srcIn,
                      ),
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
