import 'dart:convert';
import 'dart:io';

import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/add_profile_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/delete_dependent_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/personal_details_card.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/widgets/physical_info_card.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../ecliniq_utils/responsive_helper.dart';

class EditDependentBottomSheet extends StatefulWidget {
  final DependentData dependentData;
  final VoidCallback? onDependentUpdated;
  final VoidCallback? onDependentDeleted;

  const EditDependentBottomSheet({
    super.key,
    required this.dependentData,
    this.onDependentUpdated,
    this.onDependentDeleted,
  });

  @override
  State<EditDependentBottomSheet> createState() =>
      _EditDependentBottomSheetState();
}

class _EditDependentBottomSheetState extends State<EditDependentBottomSheet> {
  bool _isExpanded = true;
  bool _isExpandedPhysicalInfo = true;
  bool _isDeleting = false;
  bool _isSaving = false;
  final PatientService _patientService = PatientService();
  DependentData? _latestDependentData;

  @override
  void initState() {
    super.initState();
    // Initialize with passed data immediately
    _latestDependentData = widget.dependentData;

    // Load profile photo after widget is built
    if (widget.dependentData.profilePhoto != null &&
        widget.dependentData.profilePhoto!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = Provider.of<AddDependentProvider>(
            context,
            listen: false,
          );
          _loadProfilePhoto(provider, widget.dependentData.profilePhoto!);
        }
      });
    }
  }

  Future<void> _fetchAndUpdateWithLatestData(
    AddDependentProvider provider,
  ) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) return;

      // Fetch all dependents to get the latest data
      final response = await _patientService.getDependents(
        authToken: authToken,
      );

      if (!mounted) return;

      if (response.success) {
        // Find the specific dependent from the response
        final allMembers = <DependentData>[];
        if (response.self != null) allMembers.add(response.self!);
        allMembers.addAll(response.dependents);

        final latestDependent = allMembers.firstWhere(
          (dep) => dep.id == widget.dependentData.id,
          orElse: () => widget.dependentData, // Fallback to passed data
        );

        // Update with latest data only if different
        if (latestDependent != widget.dependentData) {
          setState(() {
            _latestDependentData = latestDependent;
          });
          // Update provider with fresh data
          _populateProvider(provider, latestDependent);
        } else {
          _latestDependentData = latestDependent;
        }
      }
    } catch (e) {
      // Silently fail and keep using passed data
    }
  }

  /// Synchronously populate provider (used during provider creation)
  void _populateProviderSync(AddDependentProvider provider, DependentData dep) {
    provider.setFirstName(dep.firstName);
    provider.setLastName(dep.lastName);
    if (dep.gender.isNotEmpty) {
      provider.setGender(dep.gender);
      provider.selectGender(_uiGender(dep.gender));
    }
    if (dep.dob != null) {
      provider.setDateOfBirth(dep.dob!);
    }
    if (dep.relation.isNotEmpty) {
      provider.setRelation(dep.relation);
      provider.selectRelation(dep.formattedRelation);
    }
    if (dep.phone != null && dep.phone!.isNotEmpty) {
      provider.setContactNumber(dep.phone!);
    }
    if (dep.emailId != null && dep.emailId!.isNotEmpty) {
      provider.setEmail(dep.emailId!);
    }
    if (dep.bloodGroup != null && dep.bloodGroup!.isNotEmpty) {
      // Convert backend format (A_POSITIVE) to UI format (A+) for consistency
      final uiFormat = _uiBloodGroup(dep.bloodGroup);
      provider.setBloodGroup(uiFormat); // Store UI format
      provider.selectBloodGroup(uiFormat); // Display UI format
    }
    if (dep.height != null) {
      provider.setHeight(dep.height);
    }
    if (dep.weight != null) {
      provider.setWeight(dep.weight);
    }
  }

  /// Asynchronously populate provider with photo loading
  void _populateProvider(AddDependentProvider provider, DependentData dep) {
    _populateProviderSync(provider, dep);
    // Load profile photo if available
    if (dep.profilePhoto != null && dep.profilePhoto!.isNotEmpty) {
      _loadProfilePhoto(provider, dep.profilePhoto!);
    }
  }

  Future<void> _loadProfilePhoto(
    AddDependentProvider provider,
    String photoKey,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;
    if (authToken == null) return;

    final photoUrl = await _resolveImageUrl(photoKey, token: authToken);
    if (photoUrl != null && mounted) {
      provider.setPhotoUrl(photoUrl);
    }
  }

  Future<String?> _resolveImageUrl(String key, {required String token}) async {
    try {
      final publicUri = Uri.parse(
        '${Endpoints.storagePublicUrl}?key=${Uri.encodeComponent(key)}',
      );
      final resp = await EcliniqHttpClient.get(
        publicUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final url = body['data']?['publicUrl'];
        if (url is String && url.isNotEmpty) {
          return url;
        }
      }
    } catch (_) {}

    try {
      final downloadUri = Uri.parse(
        '${Endpoints.storageDownloadUrl}?key=${Uri.encodeComponent(key)}',
      );
      final resp = await EcliniqHttpClient.get(
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
          return url;
        }
      }
    } catch (_) {}

    return null;
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

  String? _apiBloodGroup(String? uiValue) {
    if (uiValue == null || uiValue.isEmpty) return null;
    const map = {
      'A+': 'A_POSITIVE',
      'A-': 'A_NEGATIVE',
      'B+': 'B_POSITIVE',
      'B-': 'B_NEGATIVE',
      'AB+': 'AB_POSITIVE',
      'AB-': 'AB_NEGATIVE',
      'O+': 'O_POSITIVE',
      'O-': 'O_NEGATIVE',
      'Others': 'OTHERS',
    };
    return map[uiValue] ?? uiValue;
  }

  String _uiGender(String? backendValue) {
    if (backendValue == null || backendValue.isEmpty) return '';
    // Convert backend format (MALE, male) to UI format (Male)
    switch (backendValue.toUpperCase()) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
      case 'OTHERS':
        return 'Others';
      default:
        // If already capitalized properly, return as is
        return backendValue;
    }
  }

  String _uiRelation(String? backendValue) {
    if (backendValue == null || backendValue.isEmpty) return '';
    // Convert backend format (FATHER, father, FATHER) to UI format (Father)
    // Special case for SELF
    if (backendValue.toUpperCase() == 'SELF') return 'Self';
    // Special case for AUNTY -> Aunt
    if (backendValue.toUpperCase() == 'AUNTY') return 'Aunt';
    
    // Capitalize first letter, lowercase rest
    return backendValue[0].toUpperCase() + backendValue.substring(1).toLowerCase();
  }

  void _uploadPhoto(AddDependentProvider provider) async {
    final bool hasPhoto = provider.selectedProfilePhoto != null ||
        (provider.photoUrl != null && provider.photoUrl!.isNotEmpty && !provider.photoDeleted);

    final String? action = await EcliniqBottomSheet.show<String>(
      context: context,
      child: ProfilePhotoSelector(hasPhoto: hasPhoto),
    );

    if (action == 'delete_photo') {
      provider.setSelectedProfilePhoto(null);
      provider.setPhotoUrl(null);
      provider.setPhotoDeleted(true);
      return;
    }

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
          provider.setPhotoDeleted(false);
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

  Future<void> _updateDependent(AddDependentProvider provider) async {
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

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dependentId = _latestDependentData?.id ?? widget.dependentData.id;

      // Upload profile photo if a new one is selected
      String? photoKey;
      if (provider.selectedProfilePhoto != null) {
        photoKey = await authProvider.uploadProfileImage(provider.selectedProfilePhoto!);
        if (photoKey == null) {
          setState(() {
            _isSaving = false;
          });
          throw Exception('Failed to upload profile photo');
        }
      }

      final success = await authProvider.updateDependentProfile(
        dependentId: dependentId,
        firstName: provider.firstName,
        lastName: provider.lastName,
        gender: provider.gender,
        relation: provider.selectedRelation, // Use selectedRelation (UI format) instead of relation (backend format)
        phone: provider.contactNumber.isEmpty ? null : provider.contactNumber,
        emailId: provider.email.isEmpty ? null : provider.email,
        bloodGroup: _apiBloodGroup(provider.bloodGroup), // Convert UI format (A+) to API format (A_POSITIVE)
        height: provider.height,
        weight: provider.weight,
        dob: provider.dateOfBirth != null
            ? '${provider.dateOfBirth!.year.toString().padLeft(4, '0')}-${provider.dateOfBirth!.month.toString().padLeft(2, '0')}-${provider.dateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,
        profilePhoto: photoKey,
      );

      if (success) {
        // Clear selected photo after successful update
        if (provider.selectedProfilePhoto != null) {
          provider.setSelectedProfilePhoto(null);
        }

        if (widget.onDependentUpdated != null) {
          widget.onDependentUpdated!();
        }

        CustomSuccessSnackBar.show(
          context: context,
          title: 'Dependent Updated',
          subtitle: 'Changes have been saved successfully',
          duration: const Duration(seconds: 3),
        );

        setState(() {
          _isSaving = false;
        });

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _isSaving = false;
        });
        CustomErrorSnackBar.show(
          context: context,
          title: 'Failed to Update',
          subtitle: authProvider.errorMessage ?? 'Please try again',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      CustomErrorSnackBar.show(
        context: context,
        title: 'Error',
        subtitle: 'An error occurred: $e',
        duration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final dependentName =
        _latestDependentData?.fullName ?? widget.dependentData.fullName;

    final confirmed = await EcliniqBottomSheet.show<bool>(
      context: context,
      child: DeleteDependentBottomSheet(dependentName: dependentName),
      horizontalPadding: 12,
      bottomPadding: 16,
      borderRadius: 20,
    );

    if (confirmed == true) {
      await _deleteDependent();
    }
  }

  Future<void> _deleteDependent() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken == null) {
        throw Exception('Authentication required');
      }

      final dependentId = _latestDependentData?.id ?? widget.dependentData.id;
      final dependentName =
          _latestDependentData?.fullName ?? widget.dependentData.fullName;

      final response = await _patientService.deleteDependent(
        authToken: authToken,
        dependentId: dependentId,
      );


      if (response.success) {
        if (widget.onDependentDeleted != null) {
          widget.onDependentDeleted!();
        }

        CustomSuccessSnackBar.show(
          context: context,
          title: 'Dependent Deleted',
          subtitle: '$dependentName has been removed',
          duration: const Duration(seconds: 3),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context, 'deleted');
        }
      } else {
        CustomErrorSnackBar.show(
          context: context,
          title: 'Delete Failed',
          subtitle: response.message,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      
      CustomErrorSnackBar.show(
        context: context,
        title: 'Error',
        subtitle: 'Failed to delete dependent: $e',
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);

    final horizontalPadding = screenSize.getResponsiveValue(
      mobile: 14.0,
      mobileSmall: 12.0,
      mobileMedium: 14.0,
      mobileLarge: 16.0,
    );

    final buttonHeight = screenSize.getResponsiveValue(
      mobile: 50.0,
      mobileSmall: 48.0,
      mobileMedium: 50.0,
      mobileLarge: 52.0,
    );

    return ChangeNotifierProvider(
      key: const ValueKey('EditDependentProvider'),
      create: (_) {
        final provider = AddDependentProvider();
        // Populate provider immediately with dependent data
        _populateProviderSync(provider, widget.dependentData);
        // Schedule background refresh
        Future.microtask(() => _fetchAndUpdateWithLatestData(provider));
        return provider;
      },
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
                  'Edit Dependent Details',
                  style: EcliniqTextStyles.responsiveHeadlineXLarge(context)
                      .copyWith(
                        color: Color(0xff424242),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                    minHeight: EcliniqTextStyles.getResponsiveHeight(context, 400.0),
                  ),
                  child: SingleChildScrollView(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                      context,
                      16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile photo section
                        Center(
                          child: GestureDetector(
                            onTap: () => _uploadPhoto(provider),
                            child: Stack(
                              children: [
                                Container(
                                  width: EcliniqTextStyles.getResponsiveWidth(
                                    context,
                                    100,
                                  ),
                                  height: EcliniqTextStyles.getResponsiveHeight(
                                    context,
                                    100,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xff96BFFF),
                                      width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                                    ),
                                    image: provider.selectedProfilePhoto != null
                                        ? DecorationImage(
                                            image: FileImage(
                                              provider.selectedProfilePhoto!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    color:
                                        provider.selectedProfilePhoto == null &&
                                            (provider.photoUrl == null || provider.photoDeleted)
                                        ? const Color(0xffFFF7ED)
                                        : null,
                                  ),
                                  child: provider.selectedProfilePhoto != null
                                      ? null
                                      : (provider.photoUrl != null &&
                                            provider.photoUrl!.isNotEmpty &&
                                            !provider.photoDeleted)
                                      ? ClipOval(
                                          child: Image.network(
                                            provider.photoUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  (_latestDependentData
                                                                  ?.firstName ??
                                                              widget
                                                                  .dependentData
                                                                  .firstName)
                                                          .isNotEmpty
                                                      ? (_latestDependentData
                                                                    ?.firstName ??
                                                                widget
                                                                    .dependentData
                                                                    .firstName)[0]
                                                            .toUpperCase()
                                                      : 'D',
                                                  style:
                                                      EcliniqTextStyles.responsiveHeadlineXLarge(
                                                        context,
                                                      ).copyWith(
                                                          color: const Color(
                                                            0xffEC7600,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          fontSize: EcliniqTextStyles.getResponsiveSize(context, 40),
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            (_latestDependentData?.firstName ??
                                                        widget
                                                            .dependentData
                                                            .firstName)
                                                    .isNotEmpty
                                                ? (_latestDependentData
                                                              ?.firstName ??
                                                          widget
                                                              .dependentData
                                                              .firstName)[0]
                                                      .toUpperCase()
                                                : 'D',
                                            style:
                                                EcliniqTextStyles.responsiveHeadlineXLarge(
                                                  context,
                                                  ).copyWith(
                                                    color: const Color(0xffEC7600),
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: EcliniqTextStyles.getResponsiveSize(context, 40),
                                                  ),
                                          ),
                                        ),
                                ),
                                // Edit icon
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: EcliniqTextStyles.getResponsiveWidth(
                                      context,
                                      32,
                                    ),
                                    height:
                                        EcliniqTextStyles.getResponsiveHeight(
                                          context,
                                          32,
                                        ),
                                    decoration: BoxDecoration(
                                      color: Primitives.brightBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: EcliniqTextStyles.getResponsiveSize(context, 2.0),
                                      ),
                                    ),
                                    child: SvgPicture.asset(
                                     'lib/ecliniq_icons/assets/Refresh.svg',
                                      width: EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        16,
                                      ),
                                      height: EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        16,
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
                            16,
                          ),
                        ),

                        // Personal Details Section
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
                                    style:
                                        EcliniqTextStyles.responsiveHeadlineMedium(
                                          context,
                                        ).copyWith(color: Color(0xff424242)),
                                  ),
                                  Text(
                                    '•',
                                    style:
                                        EcliniqTextStyles.responsiveHeadlineLarge(
                                          context,
                                        ).copyWith(color: Colors.red),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                width: EcliniqTextStyles.getResponsiveIconSize(
                                  context,
                                  24,
                                ),
                                height: EcliniqTextStyles.getResponsiveIconSize(
                                  context,
                                  24,
                                ),
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
                          height: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            24,
                          ),
                        ),

                        // Physical Info Section
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
                                    style:
                                        EcliniqTextStyles.responsiveHeadlineMedium(
                                          context,
                                        ).copyWith(color: Color(0xff424242)),
                                  ),
                                ],
                              ),
                              SvgPicture.asset(
                                width: EcliniqTextStyles.getResponsiveIconSize(
                                  context,
                                  24,
                                ),
                                height: EcliniqTextStyles.getResponsiveIconSize(
                                  context,
                                  24,
                                ),
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
                          height: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Action Buttons (Delete and Save)
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  left: 16,
                  right: 12,
                  top: 22,
                  bottom: 40,
                ),
                child: Row(
                  children: [
                    // Delete Button
                    GestureDetector(
                      onTap: _isDeleting ? null : _showDeleteConfirmation,
                      child: Container(
                        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                          context,
                          12.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                          ),
                        ),
                        child: Center(
                          child: _isDeleting
                              ? SizedBox(
                                  height: EcliniqTextStyles.getResponsiveHeight(
                                    context,
                                    32,
                                  ),
                                  width: EcliniqTextStyles.getResponsiveWidth(
                                    context,
                                    32,
                                  ),
                                  child: const EcliniqLoader(
                                    size: 24,
                                    color: Color(0xff424242),
                                  ),
                                )
                              : SvgPicture.asset(
                                  EcliniqIcons.delete.assetPath,
                                  width: EcliniqTextStyles.getResponsiveIconSize(
                                    context,
                                    32,
                                  ),
                                  height: EcliniqTextStyles.getResponsiveIconSize(
                                    context,
                                    32,
                                  ),
                                  colorFilter: ColorFilter.mode(
                                    _isDeleting
                                        ? const Color(0xffD6D6D6)
                                        : const Color(0xff424242),
                                    BlendMode.srcIn,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        12,
                      ),
                    ),

                    // Save Button
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: (_isSaving || _isDeleting)
                            ? null
                            : () {
                                _updateDependent(provider);
                              },
                        child: Container(
                          height: EcliniqTextStyles.getResponsiveButtonHeight(
                            context,
                            baseHeight: 52,
                          ),
                          decoration: BoxDecoration(
                            color: provider.isFormValid && !_isDeleting && !_isSaving
                                ? Color(0xFF2372EC)
                                : Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(
                              EcliniqTextStyles.getResponsiveBorderRadius(
                                context,
                                4,
                              ),
                            ),
                          ),
                          child: Center(
                            child: _isSaving
                                ? SizedBox(
                                    height:
                                        EcliniqTextStyles.getResponsiveHeight(
                                          context,
                                          20,
                                        ),
                                    width: EcliniqTextStyles.getResponsiveWidth(
                                      context,
                                      20,
                                    ),
                                    child: EcliniqLoader(
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                : Text(
                                    'Save',
                                    textAlign: TextAlign.center,
                                    style:
                                        EcliniqTextStyles.responsiveTitleXBLarge(
                                          context,
                                        ).copyWith(
                                          color:
                                              provider.isFormValid &&
                                                  !_isDeleting &&
                                                  !_isSaving
                                              ? Colors.white
                                              : Color(0xffD6D6D6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
