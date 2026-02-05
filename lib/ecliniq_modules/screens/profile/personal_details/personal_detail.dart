import 'dart:convert';
import 'dart:io';

import 'package:ecliniq/ecliniq_api/models/patient.dart' as patient_models;
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/add_profile_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/personal_details/provider/personal_details_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/action_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../add_dependent/provider/dependent_provider.dart';
import '../add_dependent/widgets/blood_group_selection.dart';

class PersonalDetails extends StatefulWidget {
  const PersonalDetails({super.key});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  final PatientService _patientService = PatientService();
  bool _isLoading = true;
  String? _errorMessage;
  patient_models.PatientDetailsData? _data;

  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _dob;

  
  String? _profilePhotoKey; 
  String? _profilePhotoUrl; 
  File? _selectedProfilePhoto;

  @override
  void initState() {
    super.initState();
    _fetchPatientDetails();
  }

  String _monthName(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (m < 1 || m > 12) return '';
    return months[m - 1];
  }

  Widget _buildTextField({
    required String label,
    required bool isRequired,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Text(
                label,
                style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                  color: Color(0xff626060),
                ),
              ),
              if (isRequired)
                Text('•', style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(color: Colors.red, ),),
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
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                color: Color(0xffB8B8B8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
              color: Color(0xff424242),
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
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                    color: Color(0xff626060),
                  ),
                ),
                if (isRequired)
                  Text('•', style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(color: Colors.red)),
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
                style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                  color: value != null ? Color(0xff626060) : Color(0xffB8B8B8),
                  fontWeight: value != null ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  String _uiBloodGroup(String? backendValue) {
    if (backendValue == null) return '';
    const map = {
      'A_POSITIVE': 'A+',
      'A_NEGATIVE': 'A-',
      'B_POSITIVE': 'B+',
      'B_NEGATIVE': 'B-',
      'AB_POSITIVE': 'AB+',
      'AB_NEGATIVE': 'AB-',
      'O_POSITIVE': 'O+',
      'O_NEGATIVE': 'O-',
      'OTHERS': 'Others',
    };
    return map[backendValue] ?? backendValue;
  }

  String? _backendBloodGroup(String? uiValue) {
    if (uiValue == null || uiValue.isEmpty) return null;
    final v = uiValue.toUpperCase();
    const map = {
      'A+': 'A_POSITIVE',
      'A-': 'A_NEGATIVE',
      'B+': 'B_POSITIVE',
      'B-': 'B_NEGATIVE',
      'AB+': 'AB_POSITIVE',
      'AB-': 'AB_NEGATIVE',
      'O+': 'O_POSITIVE',
      'O-': 'O_NEGATIVE',
      'OTHERS': 'OTHERS',
    };
    return map[v] ?? v;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _fetchPatientDetails() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resp = await _patientService.getPatientDetails(authToken: token);
      if (!mounted) return;
      if (resp.success && resp.data != null) {
        final d = resp.data!;
        _data = d;
        _firstNameController.text = d.user?.firstName ?? '';
        _lastNameController.text = d.user?.lastName ?? '';
        _bloodGroupController.text = _uiBloodGroup(d.bloodGroup);
        _heightController.text = d.height != null ? d.height.toString() : '';
        _weightController.text = d.weight != null ? d.weight.toString() : '';
        _dob = d.dob;

        
        final firstName = d.user?.firstName ?? '';
        final lastName = d.user?.lastName ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          await SecureStorageService.storeUserName(fullName);
        }

        
        try {
          final rawResp = await http.get(
            Uri.parse(Endpoints.getPatientDetails),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'x-access-token': token,
            },
          );
          if (rawResp.statusCode == 200) {
            final body = jsonDecode(rawResp.body) as Map<String, dynamic>;
            final data = body['data'] as Map<String, dynamic>?;
            final key =
                data?['profilePhoto'] ?? (data?['user']?['profilePhoto']);
            if (key is String && key.isNotEmpty) {
              _profilePhotoKey = key;
              await _resolveImageUrl(key, token: token);
            }
          }
        } catch (_) {}

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = resp.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load details: $e';
      });
    }
  }

  Future<void> _resolveImageUrl(String key, {required String token}) async {
    
    try {
      final publicUri = Uri.parse(
        '${Endpoints.storagePublicUrl}?key=${Uri.encodeComponent(key)}',
      );
      final resp = await http.get(
        publicUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = body['data']?['publicUrl'];
        if (url is String && url.isNotEmpty) {
          _profilePhotoUrl = url;
          return;
        }
      }
    } catch (_) {}

    
    try {
      final downloadUri = Uri.parse(
        '${Endpoints.storageDownloadUrl}?key=${Uri.encodeComponent(key)}',
      );
      final resp = await http.get(
        downloadUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'x-access-token': token,
        },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = body['data']?['downloadUrl'];
        if (url is String && url.isNotEmpty) {
          _profilePhotoUrl = url;
        }
      }
    } catch (_) {}
  }

  Future<void> _selectProfilePhoto() async {
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
        if (!mounted) return;
        if (pickedFile != null) {
          setState(() {
            _selectedProfilePhoto = File(pickedFile!.path);
            _profilePhotoUrl = null; 
          });
        }
      } catch (e) {
        if (mounted) {
          CustomErrorSnackBar.show(
            context: context,
            title: 'Error',
            subtitle: 'Error picking image: $e',
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null || token.isEmpty) {
      CustomErrorSnackBar.show(
        context: context,
        title: 'Authentication Required',
        subtitle: 'Authentication required',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoKey = _profilePhotoKey;
      if (_selectedProfilePhoto != null) {
        final key = await auth.uploadProfileImage(_selectedProfilePhoto!);
        if (key == null) throw Exception('Failed to upload profile photo');
        photoKey = key;
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      
      final success = await auth.updatePatientProfile(
        firstName: firstName,
        lastName: lastName,
        bloodGroup: _backendBloodGroup(
          _bloodGroupController.text.trim().isEmpty
              ? null
              : _bloodGroupController.text.trim(),
        ),
        height: int.tryParse(_heightController.text.trim()),
        weight: int.tryParse(_weightController.text.trim()),
        dob: _dob != null
            ? '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
            : null,
        profilePhoto: photoKey,
      );

      if (success) {
        
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          await SecureStorageService.storeUserName(fullName);
        }
        
        if (!mounted) return;
        CustomSuccessSnackBar.show(
          context: context,
          title: 'Success',
          subtitle: 'Profile updated',
          duration: const Duration(seconds: 3),
        );
        _selectedProfilePhoto = null;
        await _fetchPatientDetails();
      } else {
        final msg = auth.errorMessage ?? 'Failed to update';
        throw Exception(msg);
      }
    } catch (e) {
      if (mounted) {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Error',
          subtitle: 'Error: $e',
          duration: const Duration(seconds: 3),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PersonalDetailsProvider()),
        ChangeNotifierProvider(create: (_) => AddDependentProvider()),
      ],
      child: Consumer<PersonalDetailsProvider>(
        builder: (context, provider, child) {
          return Scaffold(
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
                onPressed: () => Navigator.pop(context),
              ),
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Edit Profile Details',
                  style: EcliniqTextStyles.responsiveHeadlineMedium(
                    context,
                  ).copyWith(color: Color(0xff424242)),
                ),
              ),
              actions: [
                Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.questionCircleFilled.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                    ),
                    Text(
                      ' Help',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(context)
                              .copyWith(
                                color: EcliniqColors.light.textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 20),
                    ),
                  ],
                ),
              ],
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
            body: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                left: 16,
                right: 16,
                bottom: 24,
                top: 0,
              ),
              child: SizedBox(
                height: double.infinity,
                width: double.infinity,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: EcliniqTextStyles.getResponsiveSpacing(context, 26),
                          ),

                          Stack(
                            children: [
                              Container(
                                height: EcliniqTextStyles.getResponsiveHeight(context, 150),
                                width: EcliniqTextStyles.getResponsiveWidth(context, 150),
                                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
                                child: Container(
                                  width: EcliniqTextStyles.getResponsiveWidth(context, 50),
                                  height: EcliniqTextStyles.getResponsiveHeight(context, 50),
                                  decoration: BoxDecoration(
                                    color: Color(0xffF2F7FF),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xff96BFFF),
                                      width: 1.5,
                                    ),
                                    image: () {
                                      if (_selectedProfilePhoto != null) {
                                        return DecorationImage(
                                          fit: BoxFit.cover,
                                          image: FileImage(
                                            _selectedProfilePhoto!,
                                          ),
                                        );
                                      }
                                      if (_profilePhotoUrl != null &&
                                          _profilePhotoUrl!.isNotEmpty) {
                                        return DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(
                                            _profilePhotoUrl!,
                                          ),
                                        );
                                      }
                                      return null;
                                    }(),
                                  ),
                                  child:
                                      (_selectedProfilePhoto == null &&
                                          (_profilePhotoUrl == null ||
                                              _profilePhotoUrl!.isEmpty))
                                      ? ClipOval(
                                          child: SvgPicture.asset(
                                            'lib/ecliniq_icons/assets/Group.svg',
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 25,
                                right: -2,
                                child: GestureDetector(
                                  onTap: _selectProfilePhoto,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(0xff2372EC),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: SvgPicture.asset(
                                        'lib/ecliniq_icons/assets/Refresh.svg',
                                        width: 32,
                                        height: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  'Personal Details',
                                  style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                                      .copyWith(color: Color(0xff424242)),
                                ),
                                Text('•', style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(color: Color(0xffD92D20)))
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            label: 'First Name',
                            isRequired: true,
                            hint: 'Enter First Name',
                            controller: _firstNameController,
                            onChanged: (_) {},
                          ),
                          Divider(
                            color: EcliniqColors.light.strokeNeutralExtraSubtle,
                            thickness: 1,
                            height: 16,
                          ),
                          _buildTextField(
                            label: 'Last Name',
                            isRequired: true,
                            hint: 'Enter Last Name',
                            controller: _lastNameController,
                            onChanged: (_) {},
                          ),
                          Divider(
                            color: EcliniqColors.light.strokeNeutralExtraSubtle,
                            thickness: 1,
                            height: 16,
                          ),
                          _buildSelectField(
                            label: 'Date of Birth',
                            isRequired: true,
                            hint: 'Select Date',
                            value: _dob != null
                                ? '${_dob!.day.toString().padLeft(2, '0')} ${_monthName(_dob!.month)} ${_dob!.year}'
                                : null,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _dob ??
                                    DateTime.now().subtract(
                                      const Duration(days: 365 * 25),
                                    ),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null)
                                setState(() {
                                  _dob = picked;
                                });
                            },
                          ),

                          const SizedBox(height: 24),
                          
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Health Info',
                              style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                                color: Color(0xff424242),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSelectField(
                            label: 'Blood Group',
                            isRequired: false,
                            hint: 'Select Blood Group',
                            value: _bloodGroupController.text.isNotEmpty
                                ? _bloodGroupController.text
                                : null,
                            onTap: () async {
                              final selected =
                                  await EcliniqBottomSheet.show<String>(
                                    context: context,
                                    child: const BloodGroupSelectionSheet(),
                                  );
                              if (selected != null && mounted) {
                                setState(() {
                                  _bloodGroupController.text = selected;
                                });
                              }
                            },
                          ),
                          Divider(
                            color: EcliniqColors.light.strokeNeutralExtraSubtle,
                            thickness: 1,
                            height: 16,
                          ),
                          _buildTextField(
                            label: 'Height (cm)',
                            isRequired: false,
                            hint: 'Enter height',
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) {},
                          ),
                          Divider(
                            color: EcliniqColors.light.strokeNeutralExtraSubtle,
                            thickness: 1,
                            height: 16,
                          ),
                          _buildTextField(
                            label: 'Weight (kg)',
                            isRequired: false,
                            hint: 'Enter weight',
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) {},
                          ),
                          SizedBox(height: 80),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 52,
                        color: Colors.white,
                        alignment: Alignment.bottomCenter,
                        child: Consumer<AddDependentProvider>(
                          builder: (context, provider, child) {
                            return Container(
                        
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.white),
                              child: SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xff2372EC),
                                    disabledBackgroundColor: EcliniqColors
                                        .light
                                        .strokeNeutralSubtle
                                        .withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: Text(
                                    'Save',
                                    style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                                        .copyWith(
                                          color: EcliniqColors
                                              .light
                                              .textFixedLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
