import 'dart:io';

import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/home_screen.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/add_profile_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/date_picker_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UserDetails extends StatefulWidget {
  const UserDetails({super.key});

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  String _selectedGender = '';
  DateTime? _selectedDate;
  bool _isButtonPressed = false;
  File? _selectedProfilePhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isButtonPressed) {
      setState(() {
        _isButtonPressed = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isButtonPressed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isButtonPressed = false;
          });
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final initialDate =
        _selectedDate ??
        DateTime.now().subtract(const Duration(days: 365 * 25));

    final DateTime? picked = await EcliniqBottomSheet.show<DateTime>(
      context: context,
      child: DatePickerBottomSheet(initialDate: initialDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _handleSaveAndContinue(AuthProvider authProvider) async {
    if (_formKey.currentState!.validate() && _selectedGender.isNotEmpty) {
      setState(() {
        _isButtonPressed = true;
      });

      try {
        String? profilePhotoKey;

        if (_selectedProfilePhoto != null && authProvider.authToken != null) {
          profilePhotoKey = await authProvider.uploadProfileImage(
            _selectedProfilePhoto!,
          );

          if (profilePhotoKey == null) {
            throw Exception('Failed to upload profile photo');
          }
        }

        final dobParts = _dobController.text.split('/');
        final formattedDob = '${dobParts[2]}-${dobParts[1]}-${dobParts[0]}';

        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        
        final success = await authProvider.savePatientDetails(
          firstName: firstName,
          lastName: lastName,
          dob: formattedDob,
          gender: _selectedGender.toLowerCase(),
        );

        if (success && mounted) {
          // Store user name in secure storage
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            await SecureStorageService.storeUserName(fullName);
          }
          
          // Mark onboarding as complete
          await SessionService.setOnboardingComplete(true);

          // Profile setup complete - navigate to home
          // Flow: OTP → MPIN → User Details → Home
          await SessionService.clearFlowState(); // Clear flow state as onboarding is complete
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          throw Exception('Failed to save patient details');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isButtonPressed = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred: ${e.toString()}')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  void _selectProfilePhoto() async {
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

        if (pickedFile != null) {
          setState(() {
            _selectedProfilePhoto = File(pickedFile!.path);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
        }
      }
    }
  }

  Widget _buildSaveButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isFormValid =
            _firstNameController.text.trim().isNotEmpty &&
            _lastNameController.text.trim().isNotEmpty &&
            _dobController.text.isNotEmpty &&
            _selectedGender.isNotEmpty;

        final isButtonEnabled = isFormValid && !authProvider.isLoading;

        return SizedBox(
          width: double.infinity,
          height: EcliniqTextStyles.getResponsiveButtonHeight(
            context,
            baseHeight: 52.0,
          ),
          child: GestureDetector(
            onTapDown: isButtonEnabled
                ? (_) => setState(() => _isButtonPressed = true)
                : null,
            onTapUp: isButtonEnabled
                ? (_) {
                    setState(() => _isButtonPressed = false);
                    _handleSaveAndContinue(authProvider);
                  }
                : null,
            onTapCancel: isButtonEnabled
                ? () => setState(() => _isButtonPressed = false)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                color: authProvider.isLoading
                    ? const Color(0xFF2372EC)
                    : _isButtonPressed
                    ? const Color(0xFF0E4395) // Pressed color
                    : isButtonEnabled
                    ? const Color(0xFF2372EC) // Enabled color
                    : const Color(0xFFF9F9F9), // Disabled color
                borderRadius: BorderRadius.circular(4),
              ),
              child: authProvider.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: EcliniqLoader(size: 20, color: Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save & Continue',
                          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                            color: isButtonEnabled
                                ? Colors.white
                                : const Color(0xffD6D6D6),
                          ),
                        ),
                        SizedBox(
                          width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                        ),
                        SvgPicture.asset(
                          EcliniqIcons.arrowRightWhite.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                          height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                          colorFilter: ColorFilter.mode(
                            isButtonEnabled
                                ? Colors.white
                                : const Color(0xFF8E8E8E),
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: EcliniqScaffold.primaryBlue,
            centerTitle: true,
            title: Text(
              'Profile Details',
              style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                color: Colors.white,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  EcliniqRouter.push(ProfileHelpPage());
                },
                child: Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.questionCircleWhite.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
                    ),
                    Text(
                      'Help',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0),
                    ),
                  ],
                ),
              ),
            ],
          ),

          body: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                              context,
                              20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      _selectProfilePhoto();
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: EcliniqTextStyles.getResponsiveSize(
                                            context,
                                            150.0,
                                            minSize: 120.0,
                                            maxSize: 180.0,
                                          ),
                                          height: EcliniqTextStyles.getResponsiveSize(
                                            context,
                                            150.0,
                                            minSize: 120.0,
                                            maxSize: 180.0,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Color(0xff96BFFF),
                                              width: 0.5,
                                            ),
                                            image: _selectedProfilePhoto != null
                                                ? DecorationImage(
                                                    image: FileImage(
                                                      _selectedProfilePhoto!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                            color: _selectedProfilePhoto == null
                                                ? Color(0xffF8FAFF)
                                                : null,
                                          ),
                                          child: _selectedProfilePhoto == null
                                              ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    SvgPicture.asset(
                                                      EcliniqIcons
                                                          .add
                                                          .assetPath,
                                                      width: EcliniqTextStyles.getResponsiveIconSize(
                                                        context,
                                                        48.0,
                                                      ),
                                                      height: EcliniqTextStyles.getResponsiveIconSize(
                                                        context,
                                                        48.0,
                                                      ),
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                            Color(0xff2372EC),
                                                            BlendMode.srcIn,
                                                          ),
                                                    ),

                                                    EcliniqText(
                                                      'Upload Photo',
                                                      style: EcliniqTextStyles
                                                          .headlineXMedium
                                                          .copyWith(
                                                            color: Color(
                                                              0xff2372EC,
                                                            ),
                                                          ),
                                                    ),
                                                  ],
                                                )
                                              : null,
                                        ),

                                        if (_selectedProfilePhoto != null)
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: EcliniqTextStyles.getResponsiveSize(
                                                context,
                                                40.0,
                                                minSize: 36.0,
                                                maxSize: 44.0,
                                              ),
                                              height: EcliniqTextStyles.getResponsiveSize(
                                                context,
                                                40.0,
                                                minSize: 36.0,
                                                maxSize: 44.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Primitives.brightBlue,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: EcliniqTextStyles.getResponsiveIconSize(
                                                  context,
                                                  20.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    22.0,
                                  ),
                                ),

                                _buildFormField(
                                  label: 'First Name',
                                  controller: _firstNameController,
                                  hintText: 'Enter First Name',
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'First name is required';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(
                                  height: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    22.0,
                                  ),
                                ),

                                _buildFormField(
                                  label: 'Last Name',
                                  controller: _lastNameController,
                                  hintText: 'Enter Last Name',
                                  isRequired: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Last name is required';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(
                                  height: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    22.0,
                                  ),
                                ),

                                _buildDateField(),

                                SizedBox(
                                  height: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    22.0,
                                  ),
                                ),

                                _buildGenderField(),
                              ],
                            ),
                          ),
                        ),

                        Container(
                          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                            context,
                            18.0,
                          ),
                          child: _buildSaveButton(),
                        ),
                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isRequired = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
              color: Color(0xff626060),
            ),
            children: isRequired
                ? [
                     TextSpan(
                      text: '•',

                      style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith( color: Color(0xffD92D20)),
                    ),
                  ]
                : null,
          ),
        ),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              color: Color(0xffD6D6D6),
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide(color: Color(0xff626060), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide(color: Color(0xff626060), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide(color: Color(0xff626060), width: 0.5),
            ),
            contentPadding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 12.0,
              vertical: 12.0,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Date Of Birth',
            style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
              color: Color(0xff626060),
            ),
            children:  [
              TextSpan(
                text: '•',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith( color: Color(0xffD92D20)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
        ),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: _selectDate,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Date of birth is required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'DD/MM/YYYY',
            hintStyle: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              color: Color(0xffD6D6D6),
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 8.0),
              child: SvgPicture.asset(
                EcliniqIcons.calendarDate.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
              ),
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: EcliniqTextStyles.getResponsiveSize(context, 48.0),
              minHeight: EcliniqTextStyles.getResponsiveSize(context, 48.0),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide(color: Color(0xff626060), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide(color: Color(0xff626060), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide(color: Color(0xff626060), width: 0.5),
            ),
            contentPadding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 12.0,
              vertical: 12.0,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Gender',
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              color: Colors.black87,
          
            ),
            children:  [
              TextSpan(
                text: '•',

                style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith( color: Color(0xffD92D20)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
        ),
        Row(
          children: [
            Expanded(child: _buildGenderOption('Male', EcliniqIcons.men)),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
            ),
            Expanded(child: _buildGenderOption('Female', EcliniqIcons.women)),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
            ),
            Expanded(
              child: _buildGenderOption('Other', EcliniqIcons.genderTrans),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, EcliniqIcons icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          vertical: 12.0,
          horizontal: 8.0,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xff96BFFF) : Color(0xff8E8E8E),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
          ),
          color: isSelected ? Color(0xffF2F7FF) : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 20.0),
              colorFilter: isSelected
                  ? ColorFilter.mode(Color(0xff2372EC), BlendMode.srcIn)
                  : null,
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
            ),
            Flexible(
              child: EcliniqText(
                gender,
                style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                  color: isSelected ? Color(0xff2372EC) : Color(0xff424242),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
