import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_email_id/verify_existing_email.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/change_mpin/change_mpin_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/widgets/delete_account_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
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
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _hasDataChanged = false; // Track if email or phone was changed
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final isAvailable = await BiometricService.isAvailable();
      final isEnabled = await SecureStorageService.isBiometricEnabled();
      
      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          isOn = isEnabled;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      
      if (widget.patientData != null) {
        if (widget.patientData!.user?.phone != null) {
          _existingPhone = widget.patientData!.user!.phone;
        }
        if (widget.patientData!.user?.emailId != null) {
          _existingEmail = widget.patientData!.user!.emailId;
        }
      }

      
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
      
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  
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
          
          if (user?.phone != null) {
            _existingPhone = user!.phone;
            
            await SecureStorageService.storePhoneNumber(user.phone!);
          }

          
          if (user?.emailId != null) {
            _existingEmail = user!.emailId;
          }

          setState(() {});
        }
      }
    } catch (e) {
      
    }
  }

  Future<void> onPressedChangeMobileNumber() async {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(child: EcliniqLoader()),
    );

    
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyExistingAccount(
            challengeId: null, 
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

      
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      
      if (result != null &&
          result is Map &&
          result['success'] == true &&
          result['type'] == 'phone') {
        
        await _refreshUserInfo();

        if (mounted) {
    
            CustomSuccessSnackBar.show(
              title: 'Mobile number changed successfully!',
              subtitle: 'Your mobile number has been updated',
              context: context,
    
          );
        }
        
        // Return true to indicate data has changed
        _hasDataChanged = true;
      }
    }
  }

  Future<void> onPressedChangeEmail() async {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(child: EcliniqLoader()),
    );

    
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyExistingEmail(
            challengeId: null, 
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

      
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      
      if (result != null &&
          result is Map &&
          result['success'] == true &&
          result['type'] == 'email') {
        
        await _refreshUserInfo();

        if (mounted) {
            CustomSuccessSnackBar.show(
              title: 'Email changed successfully!',
              subtitle: 'Your email address has been updated',
              context: context,
            
          );
        }
        
        // Return true to indicate data has changed
        _hasDataChanged = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> handleBiometricPermission() async {
      if (!_isBiometricAvailable) {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Biometric Unavailable',
          subtitle: 'Biometric authentication is not available on this device',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      if (!isOn) {
        // Enable biometric
        final mpin = await SecureStorageService.getMPIN();
        if (mpin == null || mpin.isEmpty) {
          CustomErrorSnackBar.show(
            context: context,
            title: 'M-PIN Required',
            subtitle: 'Please set up M-PIN first to enable biometric authentication',
            duration: const Duration(seconds: 3),
          );
          return;
        }

        try {
          final success = await SecureStorageService.storeMPINWithBiometric(mpin);
          if (success) {
            setState(() {
              isOn = true;
              _isBiometricEnabled = true;
            });
            CustomSuccessSnackBar.show(
              context: context,
              title: 'Biometric Enabled',
              subtitle: 'You can now use biometric authentication',
              duration: const Duration(seconds: 3),
            );
          } else {
            CustomErrorSnackBar.show(
              context: context,
              title: 'Failed',
              subtitle: 'Failed to enable biometric authentication',
              duration: const Duration(seconds: 3),
            );
          }
        } catch (e) {
          CustomErrorSnackBar.show(
            context: context,
            title: 'Error',
            subtitle: 'An error occurred while enabling biometric',
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        // Disable biometric
        try {
          await SecureStorageService.setBiometricEnabled(false);
          await SecureStorageService.deleteBiometricValue('mpin');
          setState(() {
            isOn = false;
            _isBiometricEnabled = false;
          });
          CustomSuccessSnackBar.show(
            context: context,
            title: 'Biometric Disabled',
            subtitle: 'Biometric authentication has been disabled',
            duration: const Duration(seconds: 3),
          );
        } catch (e) {
          CustomErrorSnackBar.show(
            context: context,
            title: 'Error',
            subtitle: 'An error occurred while disabling biometric',
            duration: const Duration(seconds: 3),
          );
        }
      }
    }

    void onPressedChangeBiometricPermissions() {
      if (!_isBiometricAvailable) {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Biometric Unavailable',
          subtitle: 'Biometric authentication is not available on this device',
          duration: const Duration(seconds: 3),
        );
        return;
      }
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }

    Future<void> onPressedChangeMPin() async {
      
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

        
        if (result == true) {
          if (mounted) {
            
            await Future.delayed(const Duration(milliseconds: 100));
            if (mounted && context.mounted) {
              
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

        
        final success = await authProvider.logout();

        if (success && mounted) {
          
          EcliniqRouter.pushAndRemoveUntil(const LoginPage(), (route) => false);
        } else if (mounted) {
          
          EcliniqRouter.pushAndRemoveUntil(const LoginPage(), (route) => false);
        }
      } catch (e) {
        
        if (mounted) {
          EcliniqRouter.pushAndRemoveUntil(const LoginPage(), (route) => false);
        }
      }
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasDataChanged);
        return false;
      },
      child: Scaffold(
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
          onPressed: () => Navigator.pop(context, _hasDataChanged),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Security Settings',
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
      body: _isInitialLoading
          ? Center(child: EcliniqLoader(size: 20))
          : Container(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 20.0,
                vertical: 0.0,
              ),
              child: Column(
                children: [
                  _buildTile(
                    EcliniqIcons.smartphone.assetPath,
                    'Change Mobile Number',
                    onPressedChangeMobileNumber,
                    _isExpanded,
                    context: context,
                  ),
                  Container(
                    color: Color(0xffD6D6D6),
                    width: double.infinity,
                    height: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                  ),
                  _buildTile(
                    EcliniqIcons.mail.assetPath,
                    'Change Email ID',
                    onPressedChangeEmail,
                    _isExpanded,
                    context: context,
                  ),
                  Container(
                    color: Color(0xffD6D6D6),
                    width: double.infinity,
                    height: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                  ),
                  _buildTile(
                    EcliniqIcons.password.assetPath,
                    'Change M-PIN',
                    onPressedChangeMPin,
                    _isExpanded,
                    context: context,
                  ),
                  Container(
                    color: Color(0xffD6D6D6),
                    width: double.infinity,
                    height: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                  ),
                  _buildTile(
                    EcliniqIcons.faceScanSquare.assetPath,
                    _isBiometricEnabled 
                        ? 'Change Biometric Permissions' 
                        : 'Enable Biometric Authentication',
                    onPressedChangeBiometricPermissions,
                    _isExpanded,
                    context: context,
                    subtitle: !_isBiometricAvailable 
                        ? 'Not available on this device' 
                        : (_isBiometricEnabled 
                            ? 'Biometric is currently enabled' 
                            : 'Enable biometric for quick access'),
                  ),
                  if (_isExpanded) ...[
                    _buildDropDown(isOn, handleBiometricPermission, context: context),
                  ],

                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  
                  Spacer(),
                  Padding(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 0.0,
                      vertical: 30.0,
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final result = await EcliniqBottomSheet.show(
                          context: context,
                          child: const DeleteAccountBottomSheet(),
                        );

                        if (result == true && mounted) {
                          // User confirmed account deletion
                          try {
                            // Show loading dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black.withOpacity(0.3),
                              builder: (context) => Center(child: EcliniqLoader()),
                            );

                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final authToken = authProvider.authToken;

                            // Call delete account API
                            final deleteResponse = await _authService.deleteAccount(authToken: authToken);

                            // Close loading dialog
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                            }

                            if (deleteResponse['success'] == true) {
                              // Clear local data
                              await authProvider.logout();

                              // Navigate to login page
                              if (mounted) {
                                EcliniqRouter.pushAndRemoveUntil(const LoginPage(), (route) => false);
                                
                                // Show success message on login page
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(deleteResponse['message'] ?? 'Account deleted successfully'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            } else {
                              // Show error message
                              if (mounted) {
                                CustomErrorSnackBar.show(
                                  context: context,
                                  title: 'Failed to delete account',
                                  subtitle: deleteResponse['message'] ?? 'Please try again',
                                  duration: const Duration(seconds: 3),
                                );
                              }
                            }
                          } catch (e) {
                            // Close loading dialog if open
                            if (mounted) {
                              Navigator.of(context, rootNavigator: true).pop();
                              
                              CustomErrorSnackBar.show(
                                context: context,
                                title: 'Error',
                                subtitle: 'An error occurred: $e',
                                duration: const Duration(seconds: 3),
                              );
                            }
                          }
                        }
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                              child: Center(
                                child: SvgPicture.asset(
                                  EcliniqIcons.delete.assetPath,
                                  width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                  height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                            ),
                            Text(
                              'Delete Account',
                              style: EcliniqTextStyles
                                  .responsiveHeadlineBMedium(context)
                                  .copyWith(
                                    color: Color(0xffF04248),
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
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
                      SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
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
              (title != 'Change Biometric Permissions' && title != 'Enable Biometric Authentication')
                  ? SvgPicture.asset(
                      EcliniqIcons.angleRight.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                      colorFilter: ColorFilter.mode(
                        Color(0xff424242),
                        BlendMode.srcIn,
                      ),
                    )
                  : (!isExpanded)
                  ? SvgPicture.asset(
                      EcliniqIcons.angleRight.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                      colorFilter: ColorFilter.mode(
                        Color(0xff424242),
                        BlendMode.srcIn,
                      ),
                    )
                  : SvgPicture.asset(
                      EcliniqIcons.angleDown.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                    ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildDropDown(bool isOn, Future<void> Function() onPressed,
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
                  '${BiometricService.getBiometricTypeName()} Authentication',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Color(0xff424242),
                  ),
                ),
                SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                Text(
                  isOn 
                      ? 'Biometric authentication is enabled. Toggle to disable.' 
                      : 'Enable to unlock app quickly without entering M-PIN.',
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
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
          SizedBox(
            width: EcliniqTextStyles.getResponsiveSize(context, 40.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 23.0),
            child: GestureDetector(
              onTap: () async => await onPressed(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: EcliniqTextStyles.getResponsiveSize(context, 60.0),
                height: EcliniqTextStyles.getResponsiveSize(context, 30.0),
                decoration: BoxDecoration(
                  color: isOn ? Color(0xff0D47A1) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment: isOn
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  curve: Curves.easeInOut,
                  child: Container(
                    margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 2.0),
                    width: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                    height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 3.0),
                      ),
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
