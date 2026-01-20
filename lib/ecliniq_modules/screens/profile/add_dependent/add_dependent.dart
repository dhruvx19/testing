import 'dart:convert';
import 'dart:io';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/add_profile_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/personal_details_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/physical_info_card.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/action_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../ecliniq_utils/responsive_helper.dart';

class AddDependentBottomSheet extends StatefulWidget {
  final VoidCallback? onDependentAdded;

  const AddDependentBottomSheet({super.key, this.onDependentAdded});

  @override
  State<AddDependentBottomSheet> createState() =>
      _AddDependentBottomSheetState();
}

class _AddDependentBottomSheetState extends State<AddDependentBottomSheet> {
  bool _isExpanded = true;
  bool _isExpandedPhysicalInfo = true;

  void _uploadPhoto(AddDependentProvider provider) async {
    final String? action = await EcliniqBottomSheet.show<String>(
      context: context,
      child: const ProfilePhotoSelector(),
    );

    if (action != null) {
      final ImagePicker picker = ImagePicker();
      XFile? pickedFile;

      try {
        if (action == 'take_photo') {
          pickedFile = await picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            maxWidth: 1024,
            maxHeight: 1024,
          );
        } else if (action == 'upload_photo') {
          pickedFile = await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1024,
            maxHeight: 1024,
          );
        }

        if (pickedFile != null && mounted) {
          provider.setSelectedProfilePhoto(File(pickedFile.path));
        }
      } catch (e) {
        if (mounted) {
          CustomErrorSnackBar.show(
            context: context,
            title: 'Image Error',
            subtitle: 'Error picking image: $e',
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  Future<void> _saveDependent(AddDependentProvider provider) async {
    if (!provider.isFormValid) {
      final errorMessage = provider.getValidationErrorMessage();

      CustomErrorSnackBar.show(
        context: context,
        title: 'Validation Failed',
        subtitle: errorMessage,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    try {
      final success = await provider.saveDependent(context);

      if (success) {
        if (widget.onDependentAdded != null) {
          widget.onDependentAdded!();
        }

        CustomSuccessSnackBar.show(
          context: context,
          title: 'Dependent Saved',
          subtitle: 'Your changes have been saved successfully',
          duration: const Duration(seconds: 3),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        String errorTitle = 'Failed to Add Dependent';
        String errorSubtitle = provider.errorMessage ?? 'Please try again';

        if (provider.errorMessage != null) {
          final apiErrors = _parseApiErrors(provider.errorMessage!);
          if (apiErrors.isNotEmpty) {
            errorTitle = 'Action Required';
            errorSubtitle = apiErrors.join('\n');

            CustomActionSnackBar.show(
              context: context,
              title: errorTitle,
              subtitle: errorSubtitle,
              duration: const Duration(seconds: 6),
            );
            return;
          }
        }

        CustomErrorSnackBar.show(
          context: context,
          title: errorTitle,
          subtitle: errorSubtitle,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      CustomErrorSnackBar.show(
        context: context,
        title: 'Error',
        subtitle: 'An error occurred: $e',
        duration: const Duration(seconds: 4),
      );
    }
  }

  List<String> _parseApiErrors(String errorMessage) {
    try {
      final decoded = json.decode(errorMessage);
      if (decoded is Map && decoded.containsKey('errors')) {
        final errors = decoded['errors'];
        if (errors is List) {
          return errors.map((error) {
            if (error is Map && error.containsKey('message')) {
              return error['message'].toString();
            }
            return error.toString();
          }).toList();
        }
      }
    } catch (e) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);

    // Responsive values for different mobile sizes
    final horizontalPadding = screenSize.getResponsiveValue(
      mobile: 14.0,
      mobileSmall: 12.0,
      mobileMedium: 14.0,
      mobileLarge: 16.0,
    );

    final photoSize = screenSize.getResponsiveValue(
      mobile: 100.0,
      mobileSmall: 90.0,
      mobileMedium: 100.0,
      mobileLarge: 110.0,
    );

    final iconSize = screenSize.getResponsiveValue(
      mobile: 32.0,
      mobileSmall: 28.0,
      mobileMedium: 32.0,
      mobileLarge: 36.0,
    );

    final titlePadding = screenSize.getResponsiveValue(
      mobile: 20.0,
      mobileSmall: 16.0,
      mobileMedium: 20.0,
      mobileLarge: 24.0,
    );

    final verticalSpacing = screenSize.getResponsiveValue(
      mobile: 24.0,
      mobileSmall: 20.0,
      mobileMedium: 24.0,
      mobileLarge: 28.0,
    );

    final buttonHeight = screenSize.getResponsiveValue(
      mobile: 50.0,
      mobileSmall: 48.0,
      mobileMedium: 50.0,
      mobileLarge: 52.0,
    );

    return ChangeNotifierProvider(
      key: const ValueKey('AddDependentProvider'),
      create: (_) => AddDependentProvider(),
      child: Consumer<AddDependentProvider>(
        builder: (context, provider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  'Add Dependent',
                  style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                    color: Color(0xff424242),
                    fontWeight: FontWeight.w500,
         
                  ),
                ),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                    minHeight: 400,
                  ),
                  child: SingleChildScrollView(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Updated profile photo section matching UserDetails style
                        Center(
                          child: GestureDetector(
                            onTap: () => _uploadPhoto(provider),
                            child: Stack(
                              children: [
                                Container(
                                  width: EcliniqTextStyles.getResponsiveWidth(context, 100),
                                  height: EcliniqTextStyles.getResponsiveHeight(context, 100),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xff96BFFF),
                                      width: 0.5,
                                    ),
                                    image: provider.selectedProfilePhoto != null
                                        ? DecorationImage(
                                            image: FileImage(
                                              provider.selectedProfilePhoto!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color: provider.selectedProfilePhoto == null
                                        ? Primitives.lightBackground
                                        : null,
                                  ),
                                  child: provider.selectedProfilePhoto == null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              EcliniqIcons.add.assetPath,
                                              width: EcliniqTextStyles.getResponsiveIconSize(context, 44),
                                              height: EcliniqTextStyles.getResponsiveIconSize(context, 44),
                                              colorFilter: ColorFilter.mode(
                                                Color(0xff2372EC),
                                                BlendMode.srcIn,
                                              ),
                                            ),

                                            EcliniqText(
                                              'Upload \nPhoto',
                                              textAlign: TextAlign.center,
                                              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                                                    color: Color(0xff2372EC),
                                                    
                                                  ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),

                                // Edit icon overlay when photo is selected
                                if (provider.selectedProfilePhoto != null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: EcliniqTextStyles.getResponsiveWidth(context, 32),
                                      height: EcliniqTextStyles.getResponsiveHeight(context, 32),
                                      decoration: BoxDecoration(
                                        color: Primitives.brightBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                        ),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Personal Details',
                                    style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                                        .copyWith(color: Color(0xff424242)),
                                  ),
                                  Text(
                                    '•',
                                    style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                                      color: Colors.red,
                                 
                                    ),
                                  ),
                                ],
                              ),

                              SvgPicture.asset(
                                width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                _isExpanded
                                    ? EcliniqIcons.arrowUp.assetPath
                                    : EcliniqIcons.arrowDown.assetPath,
                                color: Color(0xff8E8E8E),
                              ),
                            ],
                          ),
                        ),

                        if (_isExpanded) ...[PersonalDetailsWidget()],
                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isExpandedPhysicalInfo =
                                  !_isExpandedPhysicalInfo;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Physical Info',
                                    style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                                        .copyWith(color: Color(0xff424242)),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                _isExpandedPhysicalInfo
                                    ? EcliniqIcons.arrowUp.assetPath
                                    : EcliniqIcons.arrowDown.assetPath,
                                color: Color(0xff8E8E8E),
                              ),
                            ],
                          ),
                        ),
                        if (_isExpandedPhysicalInfo) ...[PhysicalInfoCard()],
                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveSpacing(context, 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 22,
                  bottom: 40,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: EcliniqTextStyles.getResponsiveButtonHeight(
                    context,
                    baseHeight: buttonHeight,
                  ),
                  child: GestureDetector(
                    onTap: provider.isLoading
                        ? null
                        : () {
                            _saveDependent(provider);
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: provider.isFormValid
                            ? Color(0xFF2372EC)
                            : Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                        ),
                      ),
                      child: Center(
                        child: provider.isLoading
                            ? SizedBox(
                                height: EcliniqTextStyles.getResponsiveHeight(context, 20),
                                width: EcliniqTextStyles.getResponsiveWidth(context, 20),
                                child: EcliniqLoader(
                                  color: Colors.white,
                                  size: 20,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Save',
                                    style: EcliniqTextStyles.responsiveTitleXBLarge(context)
                                        .copyWith(
                                          color: provider.isFormValid
                                              ? Colors.white
                                              : Color(0xffD6D6D6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  SizedBox(
                                    width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
