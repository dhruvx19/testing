import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/branches/branches.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/about_doctor.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/address_doctor.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/common_widget.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_hospital_select_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_location_change_sheet.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/easy_to_book.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/widgets/basic_info.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
import 'package:ecliniq/widgets/horizontal_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;

  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final DoctorService _doctorService = DoctorService();
  final PatientService _patientService = PatientService();
  DoctorDetails? _doctorDetails;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavourite = false;
  bool _isFavLoading = false;
  DoctorLocationOption? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

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
        // Remove
        await _patientService.removeFavouriteDoctor(
          authToken: authToken,
          doctorId: widget.doctorId,
        );
        setState(() {
          _isFavourite = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favourite doctor removed successfully'),
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Add
        await _patientService.addFavouriteDoctor(
          authToken: authToken,
          doctorId: widget.doctorId,
        );
        setState(() {
          _isFavourite = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Favourite doctor added successfully'),
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
            ),
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
    // Construct full URL from image key
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

    // Add Clinic
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

    // Add Hospitals
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
    // Only show if there are locations
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
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              EcliniqIcons.arrowLeft.assetPath,
              width: 24,
              height: 24,
            ),
            onPressed: () => EcliniqRouter.pop(),
          ),
        ),
        body: _buildShimmerLoading(),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => EcliniqRouter.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
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

                    HorizontalDivider(),
                    const SizedBox(height: 16),
                    AppointmentTimingWidget(),
                    const SizedBox(height: 20),

                    if (clinic != null) AddressWidget(clinic: clinic),
                    const SizedBox(height: 16),

                    if (doctor.about != null)
                      AboutHospital(about: doctor.about!),
                    const SizedBox(height: 16),

                    if (doctor.professionalInformation != null &&
                        doctor.clinicDetails != null)
                      ClinicalDetailsWidget(
                        clinicDetails: doctor.clinicDetails!,
                      ),
                    const SizedBox(height: 16),

                    if (doctor.professionalInformation != null)
                      ProfessionalInformationWidget(
                        professionalInfo: doctor.professionalInformation!,
                      ),
                    const SizedBox(height: 16),
                    if (doctor.contactDetails != null)
                      DoctorContactDetailsWidget(
                        contactDetails: doctor.contactDetails!,
                      ),

                    const SizedBox(height: 16),
                    if (doctor.educationalInformation != null &&
                        doctor.educationalInformation!.isNotEmpty)
                      EducationalInformationWidget(
                        educationList: doctor.educationalInformation!,
                      ),

                    const SizedBox(height: 16),
                    if (doctor.certificatesAndAccreditations != null &&
                        doctor.certificatesAndAccreditations!.isNotEmpty)
                      DoctorCertificatesWidget(
                        certificates: doctor.certificatesAndAccreditations!,
                      ),
                    const SizedBox(height: 16),
                    if (clinic?.photos != null && clinic!.photos!.isNotEmpty)
                      ClinicPhotosWidget(photos: clinic.photos!),
                    const SizedBox(height: 16),
                    EasyWayToBookWidget(),

                    const SizedBox(height: 100),
                  ],
                ),

                Positioned(
                  top: 230,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 3),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child:
                                doctor.profilePhoto != null &&
                                    doctor.profilePhoto!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _getImageUrl(doctor.profilePhoto),
                                      width: 94,
                                      height: 94,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.local_hospital,
                                              size: 60,
                                              color: Colors.orange[700],
                                            );
                                          },
                                    ),
                                  )
                                : Icon(
                                    Icons.local_hospital,
                                    size: 60,
                                    color: Colors.orange[700],
                                  ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: SvgPicture.asset(
                              EcliniqIcons.verified.assetPath,
                              width: 24,
                              height: 24,
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

          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: _buildFloatingTabSection(),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(String? imageUrl) {
    final String? imageUrlToUse = imageUrl != null && imageUrl.isNotEmpty
        ? _getImageUrl(imageUrl)
        : null;

    return Container(
      height: 280,
      color: Colors.grey[200], // Fallback background color
      child: Stack(
        children: [
          // Image with error handling or default SVG
          Positioned.fill(
            child: imageUrlToUse != null
                ? Image.network(
                    imageUrlToUse,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Show default SVG placeholder on error
                      return Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: SvgPicture.asset(
                            EcliniqIcons.doctorDefault.assetPath,
                            width: 100,
                            height: 100,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    // Show default SVG when no image URL
                    color: Colors.grey[300],
                    child: Center(
                      child: SvgPicture.asset(
                        EcliniqIcons.doctorDefault.assetPath,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
          ),
          // Navigation buttons
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  EcliniqIcons.arrowLeft,
                  () => EcliniqRouter.pop(),
                ),
                Row(
                  children: [
                    _buildCircleButton(
                      _isFavourite
                          ? EcliniqIcons.heart
                          : EcliniqIcons.heartUnfilled,
                      _toggleFavourite,
                    ),
                    const SizedBox(width: 8),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(icon.assetPath, width: 32, height: 32),
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
      padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 24),
      child: Column(
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xff424242),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                specialization,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff424242),
                ),
              ),
            ],
          ),
          if (education.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              education,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xff424242),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.hospitalBuilding.assetPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _selectedLocation?.name ?? 'Sunrise Family Clinic',
                style: EcliniqTextStyles.titleXLarge.copyWith(
                  color: Color(0xff626060),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 20, color: Colors.grey),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _openLocationChangeBottomSheet,
                child: const Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2372EC),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                EcliniqIcons.shuffle.assetPath,
                width: 16,
                height: 16,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.mapPoint.assetPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 6),
              Text(
                location,
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
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
      padding: const EdgeInsets.symmetric(vertical: 24),
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
            DashedVerticalDivider(height: 100),
            _buildStatCard(
              EcliniqIcons.caseDoctor,
              'Experience',
              experience > 0 ? '$experience Yrs' : 'N/A',
            ),
            DashedVerticalDivider(height: 100),
            _buildStatCard(
              EcliniqIcons.tagPrice,
              'Fees',
              experience > 0 ? '$experience Yrs' : 'N/A',
            ),
            DashedVerticalDivider(height: 100),
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
      width: 140,
      child: Column(
        children: [
          SvgPicture.asset(icon.assetPath, width: 32, height: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xff626060),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xff2372EC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 90),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTab('Details', true),
          GestureDetector(
            child: _buildTab('Branches', false),
            onTap: () {
              EcliniqRouter.push(Branches());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Color(0xff2372EC) : Colors.white,
          fontWeight: isActive ? FontWeight.w400 : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
              // Header image shimmer
              ShimmerLoading(height: 280, borderRadius: BorderRadius.zero),

              // Doctor info section shimmer
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(
                  top: 60,
                  left: 16,
                  right: 16,
                  bottom: 24,
                ),
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Name shimmer
                      ShimmerLoading(
                        width: 200,
                        height: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      // Specialization shimmer
                      ShimmerLoading(
                        width: 150,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      // Education shimmer
                      ShimmerLoading(
                        width: 180,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 16),
                      // Location shimmer
                      ShimmerLoading(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Stats cards shimmer
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
                        width: 1,
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.grey[200],
                      ),
                      _buildStatCardShimmer(),
                      Container(
                        width: 1,
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        color: Colors.grey[200],
                      ),
                      _buildStatCardShimmer(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Appointment timing shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerLoading(
                  height: 150,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              // Address section shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerLoading(
                  height: 120,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              // About section shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerLoading(
                  height: 100,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              // Additional sections shimmer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerLoading(
                  height: 200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerLoading(
                  height: 150,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
          // Profile picture positioned shimmer
          Positioned(
            top: 230,
            left: 0,
            right: 0,
            child: Center(
              child: ShimmerLoading(
                width: 100,
                height: 100,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardShimmer() {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          ShimmerLoading(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 8),
          ShimmerLoading(
            width: 80,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          ShimmerLoading(
            width: 60,
            height: 20,
            borderRadius: BorderRadius.circular(4),
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
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFF96BFFF),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Appointment & OPD timing',
                      style: TextStyle(
                        fontSize: 20.0,
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      'Monday to Saturday',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff626060),
                      ),
                    ),

                    Row(
                      children: [
                        SvgPicture.asset(
                          EcliniqIcons.calendar.assetPath,
                          width: 26,
                          height: 26,
                        ),
                        const SizedBox(width: 2),
                        const Text(
                          '10:30 AM - 4:00 PM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff424242),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue[700],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Color(0xff96BFFF), width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      
                      FittedBox(
                        child: const Text(
                          'Inquire Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff2372EC),
                          ),
                        ),
                      ),
                    ],
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
