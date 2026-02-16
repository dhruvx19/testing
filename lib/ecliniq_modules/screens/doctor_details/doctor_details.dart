import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/easy_to_book.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/branches/branches.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/about_doctor.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/address_doctor.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/common_widget.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_location_change_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/basic_info.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
import 'package:ecliniq/ecliniq_utils/horizontal_divider.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;

  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen>
    with SingleTickerProviderStateMixin {
  final DoctorService _doctorService = DoctorService();
  final PatientService _patientService = PatientService();
  DoctorDetails? _doctorDetails;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavourite = false;
  bool _isFavLoading = false;
  DoctorLocationOption? _selectedLocation;
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _fetchDoctorDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctorDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get auth token from SessionService for reliability
      final authToken = await SessionService.getAuthToken();

      final response = await _doctorService.getDoctorDetailsById(
        doctorId: widget.doctorId,
        authToken: authToken,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _doctorDetails = response.data;
          _isFavourite = _doctorDetails!.isFavourite;
          _initializeSelectedLocation();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load doctor details: $e';
      });
    }
  }

  Future<void> _toggleFavourite() async {
    if (_isFavLoading || _doctorDetails == null) return;

    setState(() {
      _isFavLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to update favourites'),
            dismissDirection: DismissDirection.horizontal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        _isFavLoading = false;
      });
      return;
    }

    try {
      if (_isFavourite) {
        final response = await _patientService.removeFavouriteDoctor(
          authToken: authToken,
          doctorId: widget.doctorId,
        );
        setState(() {
          _isFavourite = false;
        });
        if (mounted) {
          final message =
              response['message'] as String? ??
              'Favourite doctor removed successfully';

          CustomSuccessSnackBar.show(
            context: context,
            title: 'Success',
            subtitle: message,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        final response = await _patientService.addFavouriteDoctor(
          authToken: authToken,
          doctorId: widget.doctorId,
        );
        setState(() {
          _isFavourite = true;
        });
        if (mounted) {
          final message =
              response['message'] as String? ??
              'Favourite doctor added successfully';

          CustomSuccessSnackBar.show(
            context: context,
            title: 'Success',
            subtitle: message,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favourite status'),
            dismissDirection: DismissDirection.horizontal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFavLoading = false;
        });
      }
    }
  }

  String _getImageUrl(String? imageKey) {
    if (imageKey == null || imageKey.isEmpty) {
      return 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&q=80';
    }

    return '${Endpoints.localhost}/$imageKey';
  }

  void _initializeSelectedLocation() {
    if (_doctorDetails?.clinicDetails != null) {
      final clinic = _doctorDetails!.clinicDetails!;
      _selectedLocation = DoctorLocationOption(
        id: clinic.id,
        name: clinic.name,
        address: '${clinic.city}, ${clinic.state}',
        type: 'Clinic',
      );
    } else if (_doctorDetails?.doctorHospitals != null &&
        _doctorDetails!.doctorHospitals!.isNotEmpty) {
      final hospital = _doctorDetails!.doctorHospitals!.first;
      if (hospital is Map) {
        _selectedLocation = DoctorLocationOption(
          id: hospital['id'] ?? '',
          name: hospital['name'] ?? '',
          address: '${hospital['city'] ?? ''}, ${hospital['state'] ?? ''}',
          type: 'Hospital',
          distance: hospital['distance']?.toString(),
        );
      }
    }
  }

  List<DoctorLocationOption> _getDoctorLocations() {
    final List<DoctorLocationOption> options = [];

    if (_doctorDetails?.clinicDetails != null) {
      final clinic = _doctorDetails!.clinicDetails!;
      options.add(
        DoctorLocationOption(
          id: clinic.id,
          name: clinic.name,
          address: '${clinic.city}, ${clinic.state}',
          type: 'Clinic',
        ),
      );
    }

    if (_doctorDetails?.doctorHospitals != null) {
      for (var hospital in _doctorDetails!.doctorHospitals!) {
        if (hospital is Map) {
          options.add(
            DoctorLocationOption(
              id: hospital['id'] ?? '',
              name: hospital['name'] ?? '',
              address: '${hospital['city'] ?? ''}, ${hospital['state'] ?? ''}',
              type: 'Hospital',
              distance: hospital['distance']?.toString(),
            ),
          );
        }
      }
    }
    return options;
  }

  void _openLocationChangeBottomSheet() async {
    final locations = _getDoctorLocations();

    if (locations.isEmpty) return;

    final selected = await EcliniqBottomSheet.show(
      context: context,
      child: DoctorLocationChangeSheet(
        doctorName: _doctorDetails?.name ?? 'Doctor',
        locations: locations,
        selectedLocationId: _selectedLocation?.id,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedLocation = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _doctorDetails == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
          titleSpacing: 0,
          toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              EcliniqIcons.backArrow.assetPath,
              width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            ),
            onPressed: () => EcliniqRouter.pop(),
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
        body: _buildShimmerLoading(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
          titleSpacing: 0,
          toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              EcliniqIcons.backArrow.assetPath,
              width: EcliniqTextStyles.getResponsiveSize(context, 32.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
            ),
            onPressed: () => EcliniqRouter.pop(),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
                color: Colors.red,
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              Text(
                _errorMessage!,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0),
              ),
              ElevatedButton(
                onPressed: _fetchDoctorDetails,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final doctor = _doctorDetails!;
    final clinic = doctor.clinicDetails;
    final specialization = doctor.specializations?.isNotEmpty == true
        ? doctor.specializations!.first
        : 'Doctor';
    final education = doctor.educationalInformation?.isNotEmpty == true
        ? doctor.educationalInformation!.map((e) => e.degree).join(', ')
        : '';
    final location = _selectedLocation != null
        ? _selectedLocation!.address
        : (clinic != null
              ? '${clinic.city}, ${clinic.state}'
              : 'Location not available');
    final initial = doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : 'D';

    return WillPopScope(
      onWillPop: () async {
        // If not on Details tab, switch to Details tab first
        if (_currentTabIndex != 0) {
          _tabController.index = 0;
          setState(() {
            _currentTabIndex = 0;
          });
          return false; // Prevent navigation - stay on page
        }
        // If already on Details tab, allow normal back navigation
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            IndexedStack(
              index: _currentTabIndex,
              children: [
                // Details Tab
                RefreshIndicator(
                  onRefresh: _fetchDoctorDetails,
                  child: SingleChildScrollView(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderImage(clinic?.image),

                            _buildDoctorInfo(
                              doctor.name,
                              specialization,
                              education,
                              location,
                            ),

                            _buildStatsCards(
                              doctor.patientsServed ?? 0,
                              doctor.workExperience ?? 0,
                              doctor.rating ?? 0.0,
                            ),
                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                8.0,
                              ),
                            ),
                            HorizontalDivider(),
                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                30.0,
                              ),
                            ),
                            AppointmentTimingWidget(),
                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                30.0,
                              ),
                            ),

                            if (clinic != null) AddressWidget(clinic: clinic),
                            if (clinic != null)
                              SizedBox(
                                height: EcliniqTextStyles.getResponsiveSpacing(
                                  context,
                                  16.0,
                                ),
                              ),

                            if (doctor.about != null)
                              AboutHospital(about: doctor.about!),
                            if (doctor.about != null)
                              SizedBox(
                                height: EcliniqTextStyles.getResponsiveSpacing(
                                  context,
                                  16.0,
                                ),
                              ),

                            if (doctor.professionalInformation != null &&
                                doctor.clinicDetails != null)
                              ClinicalDetailsWidget(
                                clinicDetails: doctor.clinicDetails!,
                              ),
                            if (doctor.professionalInformation != null &&
                                doctor.clinicDetails != null)
                              SizedBox(
                                height: EcliniqTextStyles.getResponsiveSpacing(
                                  context,
                                  16.0,
                                ),
                              ),

                            if (doctor.professionalInformation != null)
                              ProfessionalInformationWidget(
                                professionalInfo:
                                    doctor.professionalInformation!,
                              ),
                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                16.0,
                              ),
                            ),
                            if (doctor.contactDetails != null)
                              DoctorContactDetailsWidget(
                                contactDetails: doctor.contactDetails!,
                              ),

                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                16.0,
                              ),
                            ),
                            if (doctor.educationalInformation != null &&
                                doctor.educationalInformation!.isNotEmpty)
                              EducationalInformationWidget(
                                educationList: doctor.educationalInformation!,
                              ),

                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                16.0,
                              ),
                            ),
                            if (doctor.certificatesAndAccreditations != null &&
                                doctor
                                    .certificatesAndAccreditations!
                                    .isNotEmpty)
                              DoctorCertificatesWidget(
                                certificates:
                                    doctor.certificatesAndAccreditations!,
                              ),
                            if (doctor.certificatesAndAccreditations != null &&
                                doctor
                                    .certificatesAndAccreditations!
                                    .isNotEmpty)
                              SizedBox(
                                height: EcliniqTextStyles.getResponsiveSpacing(
                                  context,
                                  16.0,
                                ),
                              ),
                            if (clinic?.photos != null &&
                                clinic!.photos!.isNotEmpty)
                              ClinicPhotosWidget(photos: clinic.photos!),
                            if (clinic?.photos != null &&
                                clinic!.photos!.isNotEmpty)
                              SizedBox(
                                height: EcliniqTextStyles.getResponsiveSpacing(
                                  context,
                                  16.0,
                                ),
                              ),
                            EasyWayToBookWidget(),

                            SizedBox(
                              height: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                100.0,
                              ),
                            ),
                          ],
                        ),

                        Builder(
                          builder: (context) {
                            final headerHeight =
                                EcliniqTextStyles.getResponsiveHeight(
                                  context,
                                  210.0,
                                );
                            final circleSize =
                                EcliniqTextStyles.getResponsiveSize(
                                  context,
                                  80.0,
                                );
                            final circleRadius = circleSize / 2;
                            final topPosition = headerHeight - circleRadius;

                            return Positioned(
                              top: topPosition,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: circleSize,
                                  height: circleSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xff96BFFF),
                                      width:
                                          EcliniqTextStyles.getResponsiveSize(
                                            context,
                                            0.5,
                                          ),
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child:
                                            doctor.profilePhoto != null &&
                                                doctor.profilePhoto!.isNotEmpty
                                            ? ClipOval(
                                                child: Image.network(
                                                  _getImageUrl(
                                                    doctor.profilePhoto,
                                                  ),
                                                  width:
                                                      EcliniqTextStyles.getResponsiveWidth(
                                                        context,
                                                        94.0,
                                                      ),
                                                  height:
                                                      EcliniqTextStyles.getResponsiveHeight(
                                                        context,
                                                        94.0,
                                                      ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          Icons.local_hospital,
                                                          size:
                                                              EcliniqTextStyles.getResponsiveIconSize(
                                                                context,
                                                                60.0,
                                                              ),
                                                          color: Colors
                                                              .orange[700],
                                                        );
                                                      },
                                                ),
                                              )
                                            : Icon(
                                                Icons.local_hospital,
                                                size:
                                                    EcliniqTextStyles.getResponsiveIconSize(
                                                      context,
                                                      60.0,
                                                    ),
                                                color: Colors.orange[700],
                                              ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: SvgPicture.asset(
                                          EcliniqIcons.verified.assetPath,
                                          width:
                                              EcliniqTextStyles.getResponsiveIconSize(
                                                context,
                                                24.0,
                                              ),
                                          height:
                                              EcliniqTextStyles.getResponsiveIconSize(
                                                context,
                                                24.0,
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
                      ],
                    ),
                  ),
                ),
                // Branches Tab
                Branches(
                  aboutDescription:
                      _doctorDetails?.about ??
                      _doctorDetails?.clinicDetails?.about,
                ),
              ],
            ),

            // Floating tab section - only show on Details tab
            if (_currentTabIndex == 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: EcliniqTextStyles.getResponsiveHeight(context, 120.0),
                child: _buildFloatingTabSection(),
              ),

            // Bottom button - only show on Details tab
            if (_currentTabIndex == 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomSection(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(String? imageUrl) {
    final String? imageUrlToUse = imageUrl != null && imageUrl.isNotEmpty
        ? _getImageUrl(imageUrl)
        : null;

    return Container(
      height: EcliniqTextStyles.getResponsiveHeight(context, 210.0),
      color: Colors.grey[200],
      child: Stack(
        children: [
          Positioned.fill(
            child: imageUrlToUse != null
                ? Image.network(
                    imageUrlToUse,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: SvgPicture.asset(
                            EcliniqIcons.doctorDefault.assetPath,
                            width: EcliniqTextStyles.getResponsiveWidth(
                              context,
                              100.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveHeight(
                              context,
                              100.0,
                            ),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: EcliniqLoader(
                            size: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              24.0,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: SvgPicture.asset(
                        EcliniqIcons.doctorDefault.assetPath,
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          100.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          100.0,
                        ),
                      ),
                    ),
                  ),
          ),

          Positioned(
            top: EcliniqTextStyles.getResponsiveSize(context, 50.0),
            left: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            right: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(EcliniqIcons.arrowLeft, () {
                  // If not on Details tab, switch to Details first
                  if (_currentTabIndex != 0) {
                    _tabController.index = 0;
                    setState(() {
                      _currentTabIndex = 0;
                    });
                  } else {
                    // If on Details tab, navigate back
                    EcliniqRouter.pop();
                  }
                }),
                Row(
                  children: [
                    _buildCircleButton(
                      _isFavourite
                          ? EcliniqIcons.heart
                          : EcliniqIcons.heartUnfilled,
                      _toggleFavourite,
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        8.0,
                      ),
                    ),
                    _buildCircleButton(EcliniqIcons.share, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(EcliniqIcons icon, VoidCallback onTap) {
    return Container(
      width: EcliniqTextStyles.getResponsiveSize(context, 40.0),
      height: EcliniqTextStyles.getResponsiveSize(context, 40.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: SvgPicture.asset(
            icon.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfo(
    String name,
    String specialization,
    String education,
    String location,
  ) {
    return Container(
      color: Colors.white,
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        top: 60.0,
        left: 16.0,
        right: 16.0,
        bottom: 24.0,
      ),
      child: Column(
        children: [
          Text(
            name,
            style: EcliniqTextStyles.responsiveHeadlineXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: Color(0xff424242)),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                specialization,
                style: EcliniqTextStyles.responsiveTitleXLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w400,
                      color: Color(0xff424242),
                    ),
              ),
            ],
          ),
          if (education.isNotEmpty) ...[
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
            ),
            Text(
              education,
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff424242)),
            ),
          ],
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.hospitalBuilding.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
              ),
              Text(
                _selectedLocation?.name ?? 'Sunrise Family Clinic',
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Color(0xff626060)),
                textAlign: TextAlign.center,
              ),
              if (_getDoctorLocations().length > 1) ...[
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                Container(
                  width: EcliniqTextStyles.getResponsiveSize(context, 1.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                  color: Colors.grey,
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                GestureDetector(
                  onTap: _openLocationChangeBottomSheet,
                  child: Text(
                    'Change',
                    style: EcliniqTextStyles.responsiveBodySmall(context)
                        .copyWith(
                          color: Color(0xFF2372EC),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
                ),
                SvgPicture.asset(
                  EcliniqIcons.shuffle.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
                  height: EcliniqTextStyles.getResponsiveIconSize(
                    context,
                    16.0,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.mapPointBlue.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 6.0),
              ),
              Text(
                location,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Colors.grey[800]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(int patientsServed, int experience, double rating) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatCard(
              EcliniqIcons.usersGroupRounded,
              'Patients Served',
              patientsServed > 0 ? _formatNumber(patientsServed) : 'N/A',
            ),
            DashedVerticalDivider(
              height: EcliniqTextStyles.getResponsiveHeight(context, 100.0),
            ),
            _buildStatCard(
              EcliniqIcons.caseDoctor,
              'Experience',
              experience > 0 ? '$experience Yrs' : 'N/A',
            ),
            DashedVerticalDivider(
              height: EcliniqTextStyles.getResponsiveHeight(context, 100.0),
            ),
            _buildStatCard(
              EcliniqIcons.tagPrice,
              'Fees',
              experience > 0 ? '$experience Yrs' : 'N/A',
            ),
            DashedVerticalDivider(
              height: EcliniqTextStyles.getResponsiveHeight(context, 100.0),
            ),
            _buildStatCard(
              EcliniqIcons.stars,
              'Rating',
              rating > 0 ? '${rating.toStringAsFixed(1)} Star' : 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildStatCard(final EcliniqIcons icon, String label, String value) {
    return SizedBox(
      width: EcliniqTextStyles.getResponsiveWidth(context, 140.0),
      child: Column(
        children: [
          SvgPicture.asset(
            icon.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
          ),
          Text(
            label,
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff626060)),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 6.0),
          ),
          Text(
            value,
            style: EcliniqTextStyles.responsiveHeadlineXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: Color(0xff2372EC)),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTabSection() {
    return Center(
      child: Container(
        margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 16.0,
          vertical: 0,
        ),
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          vertical: 8.0,
          horizontal: 12.0,
        ),
        decoration: BoxDecoration(
          color: const Color(0x80000000),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 30.0),
          ),
        ),
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                child: _buildTab('Details', _currentTabIndex == 0),
                onTap: () {
                  _tabController.animateTo(0);
                },
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
              ),
              GestureDetector(
                child: _buildTab('Branches', _currentTabIndex == 1),
                onTap: () {
                  _tabController.animateTo(1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 5.0,
        vertical: 3.0,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 23.0),
        ),
        border: Border.all(
          color: isActive ? Color(0xFF96BFFF) : Colors.transparent,
          width: EcliniqTextStyles.getResponsiveSize(context, 1.0),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
            color: isActive ? Color(0xff2372EC) : Colors.white,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      color: Colors.white,
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0x332372EC),
                  offset: const Offset(7, 4),
                  blurRadius: 5.3,
                  spreadRadius: 0,
                ),
              ],
            ),
            height: EcliniqTextStyles.getResponsiveButtonHeight(
              context,
              baseHeight: 52.0,
            ),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_doctorDetails == null || _selectedLocation == null) return;

                final clinicId = _selectedLocation!.type == 'Clinic'
                    ? _selectedLocation!.id
                    : null;
                final hospitalId = _selectedLocation!.type == 'Hospital'
                    ? _selectedLocation!.id
                    : null;

                EcliniqRouter.push(
                  ClinicVisitSlotScreen(
                    doctorId: _doctorDetails!.userId,
                    clinicId: clinicId,
                    hospitalId: hospitalId,
                    doctorName: _doctorDetails!.name,
                    doctorSpecialization:
                        _doctorDetails!.specializations?.firstOrNull,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff2372EC),
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
              child: Text(
                'Book Appointment',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoading(
                height: EcliniqTextStyles.getResponsiveHeight(context, 280.0),
                borderRadius: BorderRadius.zero,
              ),

              Container(
                color: Colors.white,
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  top: 60.0,
                  left: 16.0,
                  right: 16.0,
                  bottom: 24.0,
                ),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          24.0,
                        ),
                      ),

                      ShimmerLoading(
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          200.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          24.0,
                        ),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            4.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          12.0,
                        ),
                      ),

                      ShimmerLoading(
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          150.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          16.0,
                        ),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            4.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          8.0,
                        ),
                      ),

                      ShimmerLoading(
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          180.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          16.0,
                        ),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            4.0,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          16.0,
                        ),
                      ),

                      ShimmerLoading(
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          120.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          16.0,
                        ),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            4.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),

              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCardShimmer(),
                      Container(
                        width: EcliniqTextStyles.getResponsiveSize(
                          context,
                          1.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          80.0,
                        ),
                        margin:
                            EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                              context,
                              horizontal: 20.0,
                              vertical: 0,
                            ),
                        color: Colors.grey[200],
                      ),
                      _buildStatCardShimmer(),
                      Container(
                        width: EcliniqTextStyles.getResponsiveSize(
                          context,
                          1.0,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          80.0,
                        ),
                        margin:
                            EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                              context,
                              horizontal: 20.0,
                              vertical: 0,
                            ),
                        color: Colors.grey[200],
                      ),
                      _buildStatCardShimmer(),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),

              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 16.0,
                  vertical: 0,
                ),
                child: ShimmerLoading(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 150.0),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),

              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 16.0,
                  vertical: 0,
                ),
                child: ShimmerLoading(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 120.0),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),

              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 16.0,
                  vertical: 0,
                ),
                child: ShimmerLoading(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 100.0),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),

              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 16.0,
                  vertical: 0,
                ),
                child: ShimmerLoading(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 200.0),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 16.0,
                  vertical: 0,
                ),
                child: ShimmerLoading(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 150.0),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 100.0),
              ),
            ],
          ),

          Builder(
            builder: (context) {
              final headerHeight = EcliniqTextStyles.getResponsiveHeight(
                context,
                280.0,
              );
              final circleSize = EcliniqTextStyles.getResponsiveSize(
                context,
                100.0,
              );
              final circleRadius = circleSize / 2;
              final topPosition = headerHeight - circleRadius;

              return Positioned(
                top: topPosition,
                left: 0,
                right: 0,
                child: Center(
                  child: ShimmerLoading(
                    width: circleSize,
                    height: circleSize,
                    borderRadius: BorderRadius.circular(circleRadius),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardShimmer() {
    return SizedBox(
      width: EcliniqTextStyles.getResponsiveWidth(context, 120.0),
      child: Column(
        children: [
          ShimmerLoading(
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
            ),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
          ),
          ShimmerLoading(
            width: EcliniqTextStyles.getResponsiveWidth(context, 80.0),
            height: EcliniqTextStyles.getResponsiveHeight(context, 12.0),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
            ),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 6.0),
          ),
          ShimmerLoading(
            width: EcliniqTextStyles.getResponsiveWidth(context, 60.0),
            height: EcliniqTextStyles.getResponsiveHeight(context, 20.0),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentTimingWidget extends StatefulWidget {
  const AppointmentTimingWidget({super.key});

  @override
  State<AppointmentTimingWidget> createState() =>
      _AppointmentTimingWidgetState();
}

class _AppointmentTimingWidgetState extends State<AppointmentTimingWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
                height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
                decoration: BoxDecoration(
                  color: Color(0xFF96BFFF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                    ),
                    bottomRight: Radius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointment & OPD Timing',
                      style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            color: Color(0xff424242),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              top: 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          2.0,
                        ),
                      ),
                      Text(
                        'Monday to Saturday',
                        style: EcliniqTextStyles.responsiveBodySmall(context)
                            .copyWith(
                              fontWeight: FontWeight.w400,
                              color: Color(0xff626060),
                            ),
                      ),
                      SizedBox(
                        height: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          4.0,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            EcliniqIcons.calendar.assetPath,
                            width: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              26.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              26.0,
                            ),
                          ),
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              2.0,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '10:30 AM - 4:00 PM',
                              style:
                                  EcliniqTextStyles.responsiveHeadlineBMedium(
                                    context,
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff424242),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: Container(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 6.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffF2F7FF),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          4.0,
                        ),
                      ),
                      border: Border.all(
                        color: Color(0xff96BFFF),
                        width: EcliniqTextStyles.getResponsiveSize(
                          context,
                          0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.phoneBlue.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            24.0,
                          ),
                          height: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            24.0,
                          ),
                        ),
                        SizedBox(
                          width: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            4.0,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'Inquire Now',
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff2372EC),
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
