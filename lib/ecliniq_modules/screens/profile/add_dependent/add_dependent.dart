import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/add_profile_photo.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/blood_group_selection.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/gender_selection.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/relation_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';

import '../../../../ecliniq_utils/responsive_helper.dart';
import '../../details/widgets/date_picker_sheet.dart';
import '../widgets/snack_bar.dart';


class AddDependentBottomSheet extends StatefulWidget {
  const AddDependentBottomSheet({super.key});

  @override
  State<AddDependentBottomSheet> createState() =>
      _AddDependentBottomSheetState();
}

class _AddDependentBottomSheetState extends State<AddDependentBottomSheet> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isExpanded = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showCustomSnackBar(String title, String message, bool isSuccess) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: EcliniqCustomSnackBar()
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = Provider.of<AddDependentProvider>(context, listen: false);
    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DatePickerBottomSheet(
        initialDate: provider.dateOfBirth ?? DateTime.now(),
      ),
    );
    if (picked != null) {
      provider.setDateOfBirth(picked);
    }
  }

  void _uploadPhoto() async{
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddProfilePhoto(),
    );
    final provider = Provider.of<AddDependentProvider>(context, listen: false);
    provider.setPhotoUrl('https://example.com/photo.jpg');
  }

  Future<void> _saveDependent() async {
    final provider = Provider.of<AddDependentProvider>(context, listen: false);
    final success = await provider.saveDependent();

    if (success) {
      _showCustomSnackBar(
        'Dependent Details Saved Successfully',
        'Your changes have been saved successfully',
        true,
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context);
      });
    } else {
      _showCustomSnackBar(
        'Failed to Add Dependent',
        provider.errorMessage ?? 'Please try again',
        false,
      );
    }
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
      create: (_) => AddDependentProvider(),
      child: Consumer<AddDependentProvider>(
        builder: (context, provider, child) {
          return Container(
            decoration: BoxDecoration(
              color: EcliniqColors.light.bgBaseOverlay,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EcliniqColors.light.strokeNeutralSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(titlePadding),
                  child: Text(
                    'Add Dependent',
                    style: EcliniqTextStyles.headlineLarge.copyWith(
                      color: EcliniqColors.light.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 24
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _uploadPhoto,
                          child: Container(
                            width: photoSize,
                            height: photoSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: EcliniqColors.light.bgLightblue,
                                width: 1,
                              ),
                              color: EcliniqColors.light.bgLightblue.withOpacity(0.1),
                            ),
                            child: provider.photoUrl == null
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: EcliniqColors.light.textBrand,
                                  size: iconSize,
                                ),
                                SizedBox(height: screenSize.getResponsiveValue(
                                  mobile: 4.0,
                                  mobileSmall: 3.0,
                                  mobileMedium: 4.0,
                                  mobileLarge: 5.0,
                                )),
                                Text(
                                  'Upload\nPhoto',
                                  textAlign: TextAlign.center,
                                  style: EcliniqTextStyles.bodyXSmall.copyWith(
                                    color: EcliniqColors.light.textBrand,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16
                                  ),
                                ),
                              ],
                            )
                                : ClipOval(
                              child: Image.network(
                                provider.photoUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: verticalSpacing),

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
                                    style: EcliniqTextStyles.titleXBLarge.copyWith(
                                      color: EcliniqColors.light.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    ' *',
                                    style: EcliniqTextStyles.titleXBLarge.copyWith(
                                      color: EcliniqColors.light.textDestructive,
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: EcliniqColors.light.textTertiary,
                              ),
                            ],
                          ),
                        ),

                        if (_isExpanded) ...[
                          Container(
                              margin: EdgeInsets.symmetric(
                                vertical: screenSize.getResponsiveValue(
                                  mobile: 8.0,
                                  mobileSmall: 6.0,
                                  mobileMedium: 8.0,
                                  mobileLarge: 10.0,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: EcliniqColors.light.bgContainerNonInteractiveNeutralExtraSubtle,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(screenSize.getResponsiveValue(
                                  mobile: 8.0,
                                  mobileSmall: 6.0,
                                  mobileMedium: 8.0,
                                  mobileLarge: 10.0,
                                )),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: screenSize.getResponsiveValue(
                                          mobile: 8.0,
                                          mobileSmall: 6.0,
                                          mobileMedium: 8.0,
                                          mobileLarge: 10.0,
                                        ),
                                      ),
                                      height: screenSize.getResponsiveValue(
                                        mobile: 30.0,
                                        mobileSmall: 28.0,
                                        mobileMedium: 30.0,
                                        mobileLarge: 32.0,
                                      ),
                                      child: _buildTextField(
                                        label: 'First Name',
                                        isRequired: true,
                                        hint: 'Enter First Name',
                                        controller: _firstNameController,
                                        onChanged: provider.setFirstName,
                                      ),
                                    ),
                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,
                                    ),

                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: screenSize.getResponsiveValue(
                                          mobile: 8.0,
                                          mobileSmall: 6.0,
                                          mobileMedium: 8.0,
                                          mobileLarge: 10.0,
                                        ),
                                      ),
                                      height: screenSize.getResponsiveValue(
                                        mobile: 30.0,
                                        mobileSmall: 28.0,
                                        mobileMedium: 30.0,
                                        mobileLarge: 32.0,
                                      ),
                                      child: _buildTextField(
                                        label: 'Last Name',
                                        isRequired: true,
                                        hint: 'Enter Last Name',
                                        controller: _lastNameController,
                                        onChanged: provider.setLastName,
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,
                                    ),

                                    // Gender
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: screenSize.getResponsiveValue(
                                          mobile: 8.0,
                                          mobileSmall: 6.0,
                                          mobileMedium: 8.0,
                                          mobileLarge: 10.0,
                                        ),
                                      ),
                                      height: screenSize.getResponsiveValue(
                                        mobile: 30.0,
                                        mobileSmall: 28.0,
                                        mobileMedium: 30.0,
                                        mobileLarge: 32.0,
                                      ),
                                      child:  _buildSelectField(
                                        label: 'Gender',
                                        isRequired: true,
                                        hint: 'Select Gender',
                                        value: provider.gender,
                                        onTap: () async {
                                          final selected = await showModalBottomSheet<String>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => const GenderSelectionSheet(),
                                          );
                                          if (selected != null) {
                                            provider.setGender(selected);
                                          }
                                        },
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,
                                    ),

                                    // Date of Birth
                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: screenSize.getResponsiveValue(
                                          mobile: 8.0,
                                          mobileSmall: 6.0,
                                          mobileMedium: 8.0,
                                          mobileLarge: 10.0,
                                        ),
                                      ),
                                      height: screenSize.getResponsiveValue(
                                        mobile: 30.0,
                                        mobileSmall: 28.0,
                                        mobileMedium: 30.0,
                                        mobileLarge: 32.0,
                                      ),
                                      child: _buildSelectField(
                                        label: 'Date of Birth',
                                        isRequired: true,
                                        hint: 'Select Date',
                                        value: provider.dateOfBirth != null
                                            ? DateFormat('dd MMM yyyy').format(provider.dateOfBirth!)
                                            : null,
                                        onTap: () => _selectDate(context),
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,
                                    ),

                                    Container(
                                        margin: EdgeInsets.symmetric(
                                          vertical: screenSize.getResponsiveValue(
                                            mobile: 8.0,
                                            mobileSmall: 6.0,
                                            mobileMedium: 8.0,
                                            mobileLarge: 10.0,
                                          ),
                                        ),
                                        height: screenSize.getResponsiveValue(
                                          mobile: 30.0,
                                          mobileSmall: 28.0,
                                          mobileMedium: 30.0,
                                          mobileLarge: 32.0,
                                        ),
                                        child: _buildSelectField(
                                          label: 'Relation',
                                          isRequired: true,
                                          hint: 'Select Relation',
                                          value: provider.relation,
                                          onTap: () async {
                                            final selected = await showModalBottomSheet<String>(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor: Colors.transparent,
                                              builder: (_) => const RelationSelectionSheet(),
                                            );
                                            if (selected != null) {
                                              provider.setRelation(selected);
                                            }
                                          },
                                        )
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,
                                    ),

                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: screenSize.getResponsiveValue(
                                          mobile: 8.0,
                                          mobileSmall: 6.0,
                                          mobileMedium: 8.0,
                                          mobileLarge: 10.0,
                                        ),
                                      ),
                                      height: screenSize.getResponsiveValue(
                                        mobile: 30.0,
                                        mobileSmall: 28.0,
                                        mobileMedium: 30.0,
                                        mobileLarge: 32.0,
                                      ),
                                      child: _buildTextField(
                                        label: 'Contact Number',
                                        isRequired: true,
                                        hint: 'Enter Phone Number',
                                        controller: _contactController,
                                        keyboardType: TextInputType.phone,
                                        onChanged: provider.setContactNumber,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,
                                    ),

                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: screenSize.getResponsiveValue(
                                          mobile: 8.0,
                                          mobileSmall: 6.0,
                                          mobileMedium: 8.0,
                                          mobileLarge: 10.0,
                                        ),
                                      ),
                                      height: screenSize.getResponsiveValue(
                                        mobile: 30.0,
                                        mobileSmall: 28.0,
                                        mobileMedium: 30.0,
                                        mobileLarge: 32.0,
                                      ),
                                      child: _buildTextField(
                                        label: 'Email',
                                        isRequired: false,
                                        hint: 'Enter Email',
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        onChanged: provider.setEmail,
                                      ),
                                    ),

                                    Divider(
                                      color: EcliniqColors.light.strokeNeutralExtraSubtle,
                                      thickness: 1,
                                      height: 0,
                                    ),

                                    Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: screenSize.getResponsiveValue(
                                          mobile: 8.0,
                                          mobileSmall: 6.0,
                                          mobileMedium: 8.0,
                                          mobileLarge: 10.0,
                                        ),
                                      ),
                                      height: screenSize.getResponsiveValue(
                                        mobile: 30.0,
                                        mobileSmall: 28.0,
                                        mobileMedium: 30.0,
                                        mobileLarge: 32.0,
                                      ),
                                      child: _buildSelectField(
                                        label: 'Blood Group',
                                        isRequired: false,
                                        hint: 'Select Blood Group',
                                        value: provider.bloodGroup,
                                        onTap: () async {
                                          final selected = await showModalBottomSheet<String>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (_) => const BloodGroupSelectionSheet(),
                                          );
                                          if (selected != null) {
                                            provider.setBloodGroup(selected);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: screenSize.getResponsiveValue(
                      mobile: 20.0,
                      mobileSmall: 16.0,
                      mobileMedium: 20.0,
                      mobileLarge: 24.0,
                    ),
                    vertical: screenSize.getResponsiveValue(
                      mobile: 18.0,
                      mobileSmall: 16.0,
                      mobileMedium: 18.0,
                      mobileLarge: 20.0,
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: (!provider.isFormValid || provider.isLoading)
                          ? null
                          : _saveDependent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.isFormValid
                            ? EcliniqColors.light.bgContainerInteractiveBrand
                            : EcliniqColors.light.strokeNeutralSubtle.withOpacity(0.5),
                        disabledBackgroundColor: EcliniqColors.light.strokeNeutralSubtle.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: provider.isLoading
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: EcliniqColors.light.textFixedLight,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Save',
                        style: EcliniqTextStyles.titleXBLarge.copyWith(
                          color: provider.isFormValid
                              ? EcliniqColors.light.textFixedLight
                              : EcliniqColors.light.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    required Function(String) onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Text(
                label,
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: EcliniqColors.light.textSecondary,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: EcliniqTextStyles.headlineXMedium.copyWith(
                    color: EcliniqColors.light.textDestructive,
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          flex: 1,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            textAlign: TextAlign.right,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: EcliniqTextStyles.headlineXMedium.copyWith(
                color: EcliniqColors.light.textPlaceholder,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: EcliniqTextStyles.headlineXMedium.copyWith(
              color: EcliniqColors.light.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectField({
    required String label,
    required bool isRequired,
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Text(
                  label,
                  style: EcliniqTextStyles.headlineXMedium.copyWith(
                    color: EcliniqColors.light.textSecondary,
                  ),
                ),
                if (isRequired)
                  Text(
                    ' *',
                    style: EcliniqTextStyles.headlineXMedium.copyWith(
                      color: EcliniqColors.light.textDestructive,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value ?? hint,
                textAlign: TextAlign.right,
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: value != null ? EcliniqColors.light.textSecondary : EcliniqColors.light.textPlaceholder,
                  fontWeight: value != null ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomSnackBar extends StatefulWidget {
  final String title;
  final String message;
  final bool isSuccess;

  const _CustomSnackBar({
    required this.title,
    required this.message,
    required this.isSuccess,
  });

  @override
  State<_CustomSnackBar> createState() => _CustomSnackBarState();
}

class _CustomSnackBarState extends State<_CustomSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isSuccess
                ? const Color(0xFF10B981)
                : EcliniqColors.light.bgContainerInteractiveDestructive,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isSuccess ? Icons.check : Icons.error_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: EcliniqTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message,
                      style: EcliniqTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}