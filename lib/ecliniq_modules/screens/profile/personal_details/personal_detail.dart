import 'dart:convert';
import 'dart:io';

import 'package:ecliniq/ecliniq_api/models/patient.dart' as patient_models;
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/auth/secure_storage.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/add_profile_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/date_picker_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/personal_details/provider/personal_details_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/security_settings/security_settings.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';

import '../add_dependent/provider/dependent_provider.dart';
import '../add_dependent/widgets/blood_group_selection.dart';
import '../add_dependent/widgets/gender_selection.dart';
import '../add_dependent/widgets/relation_selection.dart';

class PersonalDetails extends StatefulWidget {
  final bool isSelf;
  final String? dependentId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? gender;
  final DateTime? dob;
  final String? relation;
  final String? bloodGroup;
  final int? height;
  final int? weight;
  final String? profilePhoto;

  const PersonalDetails({
    super.key,
    this.isSelf = true,
    this.dependentId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.gender,
    this.dob,
    this.relation,
    this.bloodGroup,
    this.height,
    this.weight,
    this.profilePhoto,
  });

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  final PatientService _patientService = PatientService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  patient_models.PatientDetailsData? _data;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DateTime? _dob;

  String? _profilePhotoKey;
  String? _profilePhotoUrl;
  File? _selectedProfilePhoto;

  // Section expansion states
  bool _isPersonalDetailsExpanded = true;
  bool _isPhysicalInfoExpanded = true;

  @override
  void initState() {
    super.initState();
    if (widget.isSelf) {
      _fetchPatientDetails();
    } else {
      // For dependents, always fetch fresh data from server
      _fetchDependentDetails();
    }
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
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Text(
                  label,
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                      .copyWith(
                        color: Color(0xff626060),
                        fontWeight: FontWeight.w400,
                      ),
                ),
                if (isRequired)
                  Text(
                    ' •',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(
                      context,
                    ).copyWith(color: Colors.red),
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
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(
                  context,
                ).copyWith(color: Color(0xffB8B8B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: EcliniqTextStyles.responsiveHeadlineXMedium(
                context,
              ).copyWith(color: Color(0xff424242)),
            ),
          ),
        ],
      ),
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
      child: Container(
        color: Color(0xFFFAFAFA),
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 8,
          vertical: 8,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Text(
                    label,
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                        .copyWith(
                          color: Color(0xff626060),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  if (isRequired)
                    Text(
                      ' •',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(
                        context,
                      ).copyWith(color: Colors.red),
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
                  style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                      .copyWith(
                        color: value != null
                            ? Color(0xff424242)
                            : Color(0xffB8B8B8),
                        fontWeight: value != null
                            ? FontWeight.w400
                            : FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
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

  String _formatGenderForDisplay(String? gender) {
    if (gender == null || gender.isEmpty) return '';
    // Gender is already formatted by displayGender getter (Male, Female, Other)
    return gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _relationController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
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
        _emailController.text = d.user?.emailId ?? '';
        _contactNumberController.text = d.user?.phone ?? '';
        _genderController.text = _formatGenderForDisplay(d.displayGender);
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

  Future<void> _fetchDependentDetails() async {
    if (widget.dependentId == null) return;
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
      final resp = await _patientService.getDependents(authToken: token);
      if (!mounted) return;

      if (resp.success) {
        final allMembers = <patient_models.DependentData>[];
        if (resp.self != null) allMembers.add(resp.self!);
        allMembers.addAll(resp.dependents);

        final dep = allMembers.where((d) => d.id == widget.dependentId).firstOrNull;
        if (dep != null) {
          _firstNameController.text = dep.firstName;
          _lastNameController.text = dep.lastName;
          _emailController.text = dep.emailId ?? '';
          _contactNumberController.text = dep.phone ?? '';
          _genderController.text = dep.gender;
          _relationController.text = dep.formattedRelation;
          _bloodGroupController.text = _uiBloodGroup(dep.bloodGroup);
          _heightController.text = dep.height?.toString() ?? '';
          _weightController.text = dep.weight?.toString() ?? '';
          _dob = dep.dob;
          _profilePhotoKey = dep.profilePhoto;
          _profilePhotoUrl = null;
          _selectedProfilePhoto = null;
          if (dep.profilePhoto != null && dep.profilePhoto!.isNotEmpty) {
            await _resolveImageUrl(dep.profilePhoto!, token: token);
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Dependent not found';
          });
        }
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
        _errorMessage = 'Failed to load dependent details: $e';
      });
    }
  }

  Future<void> _resolveDependentProfilePhoto(String key) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null) return;
    await _resolveImageUrl(key, token: token);
    if (mounted) setState(() {});
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

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16,
        vertical: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile photo shimmer
          Center(
            child: ShimmerLoading(
              width: EcliniqTextStyles.getResponsiveWidth(context, 150),
              height: EcliniqTextStyles.getResponsiveHeight(context, 150),
              borderRadius: BorderRadius.circular(75),
            ),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveHeight(context, 24)),

          // Personal Details Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: ShimmerLoading(
              width: EcliniqTextStyles.getResponsiveWidth(context, 150),
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          // Form fields shimmer (8 fields)
          ...List.generate(8, (index) {
            return Column(
              children: [
                ShimmerLoading(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 56),
                  borderRadius: BorderRadius.circular(8),
                ),
                if (index < 7) const SizedBox(height: 8),
              ],
            );
          }),

          SizedBox(height: EcliniqTextStyles.getResponsiveHeight(context, 24)),

          // Physical Info Section Title
          Align(
            alignment: Alignment.centerLeft,
            child: ShimmerLoading(
              width: EcliniqTextStyles.getResponsiveWidth(context, 120),
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          // Physical info fields shimmer (2 fields)
          ...List.generate(2, (index) {
            return Column(
              children: [
                ShimmerLoading(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 56),
                  borderRadius: BorderRadius.circular(8),
                ),
                if (index < 1) const SizedBox(height: 8),
              ],
            );
          }),

          SizedBox(height: EcliniqTextStyles.getResponsiveHeight(context, 24)),

          // Save button shimmer
          ShimmerLoading(
            height: EcliniqTextStyles.getResponsiveSize(context, 52),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
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
      _isSaving = true;
    });

    try {
      String? photoKey;
      if (_selectedProfilePhoto != null) {
        final key = await auth.uploadProfileImage(_selectedProfilePhoto!);
        if (key == null) throw Exception('Failed to upload profile photo');
        photoKey = key;
      }

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final formattedDob = _dob != null
          ? '${_dob!.year.toString().padLeft(4, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
          : null;
      final bloodGroup = _backendBloodGroup(
        _bloodGroupController.text.trim().isEmpty
            ? null
            : _bloodGroupController.text.trim(),
      );

      bool success;

      if (widget.isSelf) {
        success = await auth.updatePatientProfile(
          firstName: firstName,
          lastName: lastName,
          gender: _genderController.text.trim().isNotEmpty
              ? _genderController.text.trim().toLowerCase()
              : null,
          bloodGroup: bloodGroup,
          height: int.tryParse(_heightController.text.trim()),
          weight: int.tryParse(_weightController.text.trim()),
          dob: formattedDob,
          profilePhoto: photoKey,
        );
      } else {
        if (widget.dependentId == null) {
          throw Exception('Dependent ID is missing');
        }
        success = await auth.updateDependentProfile(
          dependentId: widget.dependentId!,
          firstName: firstName,
          lastName: lastName,
          gender: _genderController.text.trim().isNotEmpty
              ? _genderController.text.trim().toLowerCase()
              : null,
          relation: _relationController.text.trim().isNotEmpty
              ? _relationController.text.trim().toLowerCase()
              : null,
          phone: _contactNumberController.text.trim().isNotEmpty
              ? _contactNumberController.text.trim()
              : null,
          emailId: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          bloodGroup: bloodGroup,
          height: int.tryParse(_heightController.text.trim()),
          weight: int.tryParse(_weightController.text.trim()),
          dob: formattedDob,
          profilePhoto: photoKey,
        );
      }

      if (success) {
        if (widget.isSelf) {
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            await SecureStorageService.storeUserName(fullName);
          }
        }

        if (!mounted) return;
        CustomSuccessSnackBar.show(
          context: context,
          title: 'Success',
          subtitle: widget.isSelf ? 'Profile updated' : 'Dependent updated',
          duration: const Duration(seconds: 3),
        );
        setState(() {
          _selectedProfilePhoto = null;
          _isSaving = false;
        });
        
        // Refresh data after successful update
        if (widget.isSelf) {
          await _fetchPatientDetails();
        } else {
          await _fetchDependentDetails();
        }
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
          _isSaving = false;
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
              backgroundColor: Colors.white,
              leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
              titleSpacing: 0,
              toolbarHeight: EcliniqTextStyles.getResponsiveHeight(
                context,
                46.0,
              ),
              leading: IconButton(
                icon: SvgPicture.asset(
                  EcliniqIcons.arrowLeft.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                ),
                onPressed: () => Navigator.pop(context, true), // Return true to indicate data may have changed
              ),
              title: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.isSelf ? 'Edit Profile Details' : 'Dependent Details',
                  style: EcliniqTextStyles.responsiveHeadlineMedium(
                    context,
                  ).copyWith(color: Color(0xff424242)),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.2),
                child: Container(color: Color(0xFFB8B8B8), height: 1.0),
              ),
              actions: [
                Row(
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.questionCircleFilled.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        24,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        24,
                      ),
                    ),
                    Text(
                      ' Help',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            color: EcliniqColors.light.textPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveWidth(context, 20),
                    ),
                  ],
                ),
              ],
            ),
            body: _isLoading
                ? _buildShimmerLoading()
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: widget.isSelf ? _fetchPatientDetails : _fetchDependentDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xff2372EC),
                                ),
                                child: Text(
                                  'Retry',
                                  style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
              children: [
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: EcliniqTextStyles.getResponsiveHeight(
                                    context,
                                    150,
                                  ),
                                  width: EcliniqTextStyles.getResponsiveWidth(
                                    context,
                                    150,
                                  ),
                                  padding:
                                      EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                                        context,
                                        16,
                                      ),
                                  child: Container(
                                    width: EcliniqTextStyles.getResponsiveWidth(
                                      context,
                                      50,
                                    ),
                                    height:
                                        EcliniqTextStyles.getResponsiveHeight(
                                          context,
                                          50,
                                        ),
                                    decoration: BoxDecoration(
                                      color: Color(0xffF2F7FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Color(0xff96BFFF),
                                        width: 1.5,
                                      ),
                                      image: _selectedProfilePhoto != null
                                          ? DecorationImage(
                                              fit: BoxFit.cover,
                                              image: FileImage(
                                                _selectedProfilePhoto!,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: _selectedProfilePhoto != null
                                        ? null
                                        : (_profilePhotoUrl != null &&
                                              _profilePhotoUrl!.isNotEmpty)
                                        ? ClipOval(
                                            child: Image.network(
                                              _profilePhotoUrl!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return SvgPicture.asset(
                                                      'lib/ecliniq_icons/assets/Group.svg',
                                                      fit: BoxFit.contain,
                                                    );
                                                  },
                                            ),
                                          )
                                        : ClipOval(
                                            child: SvgPicture.asset(
                                              'lib/ecliniq_icons/assets/Group.svg',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 25,
                                  right: -2,
                                  child: GestureDetector(
                                    onTap: _selectProfilePhoto,
                                    child: Container(
                                      width:
                                          EcliniqTextStyles.getResponsiveIconSize(
                                            context,
                                            48,
                                          ),
                                      height:
                                          EcliniqTextStyles.getResponsiveIconSize(
                                            context,
                                            48,
                                          ),
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
                                          width:
                                              EcliniqTextStyles.getResponsiveIconSize(
                                                context,
                                                32,
                                              ),
                                          height:
                                              EcliniqTextStyles.getResponsiveIconSize(
                                                context,
                                                32,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveHeight(
                                context,
                                24,
                              ),
                            ),
                          ],
                        ),

                        // Personal Details Section
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPersonalDetailsExpanded =
                                  !_isPersonalDetailsExpanded;
                            });
                          },
                          child: Container(
                            color: Colors.white,
                            padding:
                                EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                  context,
                                  vertical: 0,
                                  horizontal: 6,
                                ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Personal Details',
                                      style:
                                          EcliniqTextStyles.responsiveHeadlineMedium(
                                            context,
                                          ).copyWith(color: Color(0xff424242)),
                                    ),
                                    Text(
                                      ' •',
                                      style:
                                          EcliniqTextStyles.responsiveHeadlineLarge(
                                            context,
                                          ).copyWith(color: Color(0xffD92D20)),
                                    ),
                                  ],
                                ),
                                Icon(
                                  _isPersonalDetailsExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Color(0xff626060),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_isPersonalDetailsExpanded) ...[
                          _buildTextField(
                            label: 'First Name',
                            isRequired: true,
                            hint: 'Enter First Name',
                            controller: _firstNameController,
                            onChanged: (_) {},
                          ),
                          Divider(
                            color: Color(0xffD6D6D6),
                            thickness: 1,
                            height: 0.5,
                          ),
                          _buildTextField(
                            label: 'Last Name',
                            isRequired: true,
                            hint: 'Enter Last Name',
                            controller: _lastNameController,
                            onChanged: (_) {},
                          ),
                          Divider(
                            color: Color(0xffD6D6D6),
                            thickness: 1,
                            height: 0.5,
                          ),
                          _buildSelectField(
                            label: 'Gender',
                            isRequired: true,
                            hint: 'Select Gender',
                            value: _genderController.text.isNotEmpty
                                ? _genderController.text
                                : null,
                            onTap: () async {
                              final selected = await EcliniqBottomSheet.show<String>(
                                context: context,
                                child: const GenderSelectionSheet(),
                              );
                              if (selected != null && mounted) {
                                setState(() {
                                  _genderController.text = selected;
                                });
                              }
                            },
                          ),
                          Divider(
                            color: Color(0xffD6D6D6),
                            thickness: 1,
                            height: 0.5,
                          ),
                          _buildSelectField(
                            label: 'Date of Birth',
                            isRequired: true,
                            hint: 'Select Date',
                            value: _dob != null
                                ? '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}'
                                : null,
                            onTap: () async {
                              final picked =
                                  await EcliniqDatePicker.showDatePicker(
                                    context: context,
                                    initialDateTime:
                                        _dob ??
                                        DateTime.now().subtract(
                                          const Duration(days: 365 * 25),
                                        ),
                                    minimumDateTime: DateTime(1900),
                                    maximumDateTime: DateTime.now(),
                                  );
                              if (picked != null) {
                                setState(() {
                                  _dob = picked;
                                });
                              }
                            },
                          ),
                          Divider(
                            color: Color(0xffD6D6D6),
                            thickness: 1,
                            height: 0.5,
                          ),
                          if (!widget.isSelf) ...[
                            _buildSelectField(
                              label: 'Relation',
                              isRequired: true,
                              hint: 'Select Relation',
                              value: _relationController.text.isNotEmpty
                                  ? _relationController.text
                                  : null,
                              onTap: () async {
                                final selected = await EcliniqBottomSheet.show<String>(
                                  context: context,
                                  child: const RelationSelectionSheet(),
                                );
                                if (selected != null && mounted) {
                                  setState(() {
                                    _relationController.text = selected;
                                  });
                                }
                              },
                            ),
                            Divider(
                              color: Color(0xffD6D6D6),
                              thickness: 1,
                              height: 0.5,
                            ),
                          ],
                          if (widget.isSelf)
                            _buildSelectField(
                              label: 'Contact Number',
                              isRequired: true,
                              hint: 'Enter Contact Number',
                              value: _contactNumberController.text.isNotEmpty
                                  ? _contactNumberController.text
                                  : null,
                              onTap: () async {
                                // Navigate to security settings and wait for result
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SecuritySettingsOptions(
                                          patientData: _data,
                                        ),
                                  ),
                                );
                                
                                // Reload data if user potentially changed phone/email
                                if (result == true && mounted) {
                                  await _fetchPatientDetails();
                                }
                              },
                            )
                          else
                            _buildTextField(
                              label: 'Contact Number',
                              isRequired: true,
                              hint: 'Enter Contact Number',
                              controller: _contactNumberController,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) {},
                            ),
                          Divider(
                            color: Color(0xffD6D6D6),
                            thickness: 1,
                            height: 0.5,
                          ),
                          if (widget.isSelf)
                            _buildSelectField(
                              label: 'Email',
                              isRequired: false,
                              hint: 'Enter Email',
                              value: _emailController.text.isNotEmpty
                                  ? _emailController.text
                                  : null,
                              onTap: () async {
                                // Navigate to security settings and wait for result
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SecuritySettingsOptions(
                                          patientData: _data,
                                        ),
                                  ),
                                );
                                
                                // Reload data if user potentially changed phone/email
                                if (result == true && mounted) {
                                  await _fetchPatientDetails();
                                }
                              },
                            )
                          else
                            _buildTextField(
                              label: 'Email',
                              isRequired: false,
                              hint: 'Enter Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) {},
                            ),
                          Divider(
                            color: Color(0xffD6D6D6),
                            thickness: 1,
                            height: 0.5,
                          ),
                          _buildSelectField(
                            label: 'Blood Group',
                            isRequired: true,
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
                        ],

                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveHeight(
                            context,
                            24,
                          ),
                        ),

                        // Physical Info Section
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPhysicalInfoExpanded =
                                  !_isPhysicalInfoExpanded;
                            });
                          },
                          child: Container(
                            color: Colors.white,
                            padding:
                                EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                  context,
                                  vertical: 0,
                                  horizontal: 6,
                                ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Physical Info',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineMedium(
                                        context,
                                      ).copyWith(color: Color(0xff424242)),
                                ),
                                Icon(
                                  _isPhysicalInfoExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Color(0xff626060),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_isPhysicalInfoExpanded) ...[
                          _buildTextField(
                            label: 'Height (cm)',
                            isRequired: false,
                            hint: 'Enter height',
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) {},
                          ),
                          Divider(
                            color: Color(0xffD6D6D6),
                            thickness: 1,
                            height: 0.5,
                          ),
                          _buildTextField(
                            label: 'Weight (Kg)',
                            isRequired: false,
                            hint: 'Enter weight',
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) {},
                          ),
                        ],

                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Fixed Save Button at bottom
                Container(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                    context,
                    horizontal: 16,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: EcliniqTextStyles.getResponsiveSize(context, 52),
                    child: ElevatedButton(
                      onPressed: (_isLoading || _isSaving) ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff2372EC),
                        disabledBackgroundColor: _isSaving
                            ? Color(0xff2372EC)
                            : EcliniqColors
                                .light
                                .strokeNeutralSubtle
                                .withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              4,
                            ),
                          ),
                        ),
                      ),
                      child: Center(
                        child: _isSaving
                            ? EcliniqLoader(
                                size: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                                color: Colors.white,
                              )
                            : Text(
                                'Save',
                                textAlign: TextAlign.center,
                                style:
                                    EcliniqTextStyles.responsiveHeadlineMedium(
                                      context,
                                    ).copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
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
}
