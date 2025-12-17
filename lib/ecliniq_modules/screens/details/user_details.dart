import 'dart:io';

import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/add_profile_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/date_picker_sheet.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/home_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
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

        final success = await authProvider.savePatientDetails(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          dob: formattedDob,
          gender: _selectedGender,
        );

        if (success && mounted) {
          // Mark onboarding as complete
          await SessionService.setOnboardingComplete(true);

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
          height: 46,
          child: GestureDetector(
            onTap: isButtonEnabled
                ? () => _handleSaveAndContinue(authProvider)
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: _isButtonPressed
                    ? Color(0xFF0E4395)
                    : isButtonEnabled
                    ? EcliniqButtonType.brandPrimary.backgroundColor(context)
                    : EcliniqButtonType.brandPrimary.disabledBackgroundColor(
                        context,
                      ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: authProvider.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save & Continue',
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: _isButtonPressed
                                ? Colors.white
                                : isButtonEnabled
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: isButtonEnabled ? Colors.white : Colors.grey,
                          size: 20,
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
            backgroundColor: EcliniqScaffold.primaryBlue,
            title: Text(
              'Clinic Visit Slot',
              style: EcliniqTextStyles.headlineMedium.copyWith(
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
                      EcliniqIcons.questionMark.assetPath,
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Help',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
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
                            padding: const EdgeInsets.all(24),
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
                                          width: 150,
                                          height: 150,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Primitives.lightBlue,
                                              width: 2,
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
                                                ? Primitives.lightBackground
                                                : null,
                                          ),
                                          child: _selectedProfilePhoto == null
                                              ? Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add,
                                                      size: 34,
                                                      color:
                                                          Primitives.brightBlue,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    EcliniqText(
                                                      'Upload Photo',
                                                      style: EcliniqTextStyles
                                                          .headlineXMedium
                                                          .copyWith(
                                                            color: Primitives
                                                                .brightBlue,
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
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Primitives.brightBlue,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

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

                                const SizedBox(height: 20),

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

                                const SizedBox(height: 20),

                                _buildDateField(),

                                const SizedBox(height: 20),

                                _buildGenderField(),
                              ],
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.all(24),
                          child: _buildSaveButton(),
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
            style: EcliniqTextStyles.headlineXMedium.copyWith(
              color: Colors.black87,
            ),
            children: isRequired
                ? [
                    const TextSpan(
                      text: ' •',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
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
            style: EcliniqTextStyles.headlineXMedium.copyWith(
              color: Colors.black87,
              fontSize: 16,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
            hintStyle: TextStyle(color: Colors.grey.shade500),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
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
            style: EcliniqTextStyles.headlineXMedium.copyWith(
              color: Colors.black87,
              fontSize: 16,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildGenderOption('male', Icons.male)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderOption('Female', Icons.female)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderOption('Other', Icons.person)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.black87,
              size: 24,
            ),
            const SizedBox(width: 2),
            EcliniqText(
              gender,
              style: EcliniqTextStyles.headlineMedium.copyWith(
                color: isSelected ? Primitives.brightBlue : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
