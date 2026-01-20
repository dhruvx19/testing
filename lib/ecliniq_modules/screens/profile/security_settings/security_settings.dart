import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_email_id/verify_existing_email.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_mpin/change_mpin_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../../ecliniq_api/auth_service.dart';
import '../../../../ecliniq_api/models/patient.dart';
import '../../../../ecliniq_api/patient_service.dart';
import '../../../../ecliniq_core/auth/jwt_decoder.dart';
import '../../../../ecliniq_core/auth/secure_storage.dart';
import '../../../../ecliniq_core/auth/session_service.dart';
import '../../../../ecliniq_core/router/route.dart';
import '../../../../ecliniq_icons/icons.dart';
import '../../../../ecliniq_modules/screens/auth/provider/auth_provider.dart';
import '../../../../ecliniq_modules/screens/login/login.dart';
import 'change_mobile_number/screens/verify_existing_account.dart';

class SecuritySettingsOptions extends StatefulWidget {
  final PatientDetailsData? patientData;

  const SecuritySettingsOptions({super.key, this.patientData});

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
  final PatientService _patientService = PatientService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Priority 1: Use passed patient data
      if (widget.patientData != null) {
        if (widget.patientData!.user?.phone != null) {
          _existingPhone = widget.patientData!.user!.phone;
        }
        if (widget.patientData!.user?.emailId != null) {
          _existingEmail = widget.patientData!.user!.emailId;
        }
      }

      // Priority 2: If values are still null, try storage/token
      if (_existingPhone == null) {
        final phone = await SecureStorageService.getPhoneNumber();
        if (phone != null) {
          _existingPhone = phone;
        }
      }

      if (_existingEmail == null) {
        final authToken = await SessionService.getAuthToken();
        if (authToken != null) {
          final payload = JwtDecoder.decodePayload(authToken);
          if (payload != null && payload['email'] != null) {
            _existingEmail = payload['email'].toString();
          }
        }
      }

      if (mounted) {
        setState(() {});
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

  /// Refresh user info from API after phone/email change
  Future<void> _refreshUserInfo() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        return;
      }

      final response = await _patientService.getPatientDetails(
        authToken: authToken,
      );

      if (response.success && response.data != null) {
        final user = response.data!.user;

        if (mounted) {
          // Update phone number
          if (user?.phone != null) {
            _existingPhone = user!.phone;
            // Also update secure storage if phone is stored there
            await SecureStorageService.storePhoneNumber(user.phone!);
          }

          // Update email
          if (user?.emailId != null) {
            _existingEmail = user!.emailId;
          }

          setState(() {});
        }
      }
    } catch (e) {
      print('Error refreshing user info: $e');
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
            preloadedPhone: _existingPhone,
            preloadedMaskedPhone:
                _existingPhone != null && _existingPhone!.length >= 10
                ? '******${_existingPhone!.substring(_existingPhone!.length - 4)}'
                : null,
          ),
        ),
      );

      // Dismiss loader when navigation completes
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show success snackbar if phone was changed successfully
      if (result != null &&
          result is Map &&
          result['success'] == true &&
          result['type'] == 'phone') {
        // Refresh user info from API to get updated phone number
        await _refreshUserInfo();

        if (mounted) {
    
            CustomSuccessSnackBar.show(
              title: 'Mobile number changed successfully!',
              subtitle: 'Your mobile number has been updated',
              context: context,
    
          );
        }
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
            preloadedEmail: _existingEmail,
            preloadedMaskedEmail:
                _existingEmail != null && _existingEmail!.contains('@')
                ? _maskEmail(_existingEmail!)
                : null,
          ),
        ),
      );

      // Dismiss loader when navigation completes
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Show success snackbar if email was changed successfully
      if (result != null &&
          result is Map &&
          result['success'] == true &&
          result['type'] == 'email') {
        // Refresh user info from API to get updated email
        await _refreshUserInfo();

        if (mounted) {
            CustomSuccessSnackBar.show(
              title: 'Email changed successfully!',
              subtitle: 'Your email address has been updated',
              context: context,
            
          );
        }
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
      // Navigate to change MPIN screen with preloaded phone number
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeMPINScreen(
              preloadedPhoneNumber: _existingPhone,
              preloadedMaskedPhone:
                  _existingPhone != null && _existingPhone!.length >= 10
                  ? '******${_existingPhone!.substring(_existingPhone!.length - 4)}'
                  : null,
            ),
          ),
        );

        // Show success snackbar if MPIN was changed successfully
        if (result == true) {
          if (mounted) {
            // Wait a bit to ensure navigation is complete and widget is stable
            await Future.delayed(const Duration(milliseconds: 100));
            if (mounted && context.mounted) {
              // Use postFrameCallback to ensure the page is fully built before showing snackbar
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
     
           
                    CustomSuccessSnackBar.show(
                      title: 'M-PIN changed successfully!',
                      subtitle: 'Your M-PIN has been updated',
                      context: context,
                 
                  );
                }
              });
            }
          }
        }
      }
    }

    Future<void> onPressedLogout() async {
      if (!mounted) return;

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Clear session
        final success = await authProvider.logout();

        if (success && mounted) {
          // Navigate to login page and clear navigation stack
          EcliniqRouter.pushAndRemoveUntil(const LoginPage(), (route) => false);
        } else if (mounted) {
          // If logout failed, still navigate to login for security
          EcliniqRouter.pushAndRemoveUntil(const LoginPage(), (route) => false);
        }
      } catch (e) {
        // Even if there's an error, navigate to login for security
        if (mounted) {
          EcliniqRouter.pushAndRemoveUntil(const LoginPage(), (route) => false);
        }
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
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
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
                     context:   context,
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
                     context:   context,
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
                     context:   context,
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
                     context:   context,
                    EcliniqIcons.faceScanSquare.assetPath,
                    'Change Biometric Permissions',
                    onPressedChangeBiometricPermissions,
                    _isExpanded,
                  ),
                  if (_isExpanded) ...[
                    _buildDropDown( context:   context,isOn, handleBiometricPermission),
                  ],

                  // Container(
                  //   color: Color(0xffD6D6D6),
                  //   width: double.infinity,
                  //   height: 0.5,
                  // ),
                  // _buildTile(
                  //   EcliniqIcons.logout.assetPath,
                  //   'Logout',
                  //   onPressedLogout,
                  //   _isExpanded,
                  // ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: GestureDetector(
                      onTap: () {
                          CustomSuccessSnackBar.show(
                            title: 'OTP verified successfully!',
                            subtitle: 'You can now reset your MPIN',
                            context: context,
                      
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: EcliniqTextStyles.getResponsiveButtonHeight(
                          context,
                          baseHeight: 52.0,
                        ),
                        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                          context,
                          horizontal: 0,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF8F8),
                          border: Border.all(
                            color: Color(0xffEB8B85),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              EcliniqIcons.delete.assetPath,
                              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                            ),
                            SizedBox(
                              width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                            ),
                            Text(
                              'Delete Account',
                              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                                color: Color(0xffF04248),

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

  String _maskEmail(String email) {
    if (email.isEmpty) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }
    return '${username.substring(0, 2)}***@$domain';
  }
}

Widget _buildTile(
  String icon,
  String title,
  VoidCallback? onPressed,
  bool isExpanded, {
  String? subtitle,
  required BuildContext context,
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
              SvgPicture.asset(
                icon,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: Color(0xff424242),
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                          color: Colors.grey.shade600,
             
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

Widget _buildDropDown(bool isOn, VoidCallback onPressed,
    {required BuildContext context}) {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Lock Permission',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Color(0xff424242),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep it turn ON to unlock app quickly without inputting m-pin.',
                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Color(0xff8E8E8E),
          
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
      Divider(color: Color(0xffD6D6D6), thickness: 0.5),
    ],
  );
}
