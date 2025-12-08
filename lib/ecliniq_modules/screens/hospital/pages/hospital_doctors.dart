// lib/ecliniq_modules/screens/hospital/hospital_doctors_screen.dart

import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/hospital_doctor_model.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart' as api_doctor;
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/availability_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/filter_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/select_specialities_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/sort_by_filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class HospitalDoctorsScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;
  final String authToken; // REQUIRED: Authentication token
  final bool hideAppBar;

  const HospitalDoctorsScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
    required this.authToken,
    this.hideAppBar = false,
  });

  @override
  State<HospitalDoctorsScreen> createState() => _HospitalDoctorsScreenState();
}

class _HospitalDoctorsScreenState extends State<HospitalDoctorsScreen> {
  final HospitalService _hospitalService = HospitalService();
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _searchController = TextEditingController();

  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  
  // Filter state
  Map<String, dynamic>? _appliedFilters;
  bool _isUsingFilters = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterDoctors();
    });
  }

  void _filterDoctors() {
    if (_searchQuery.isEmpty) {
      _filteredDoctors = _doctors;
    } else {
      _filteredDoctors = _doctors.where((doctor) {
        final name = doctor.name.toLowerCase();
        final specializations = doctor.specializations.join(' ').toLowerCase();
        final qualifications = doctor.qualifications.toLowerCase();
        return name.contains(_searchQuery) ||
            specializations.contains(_searchQuery) ||
            qualifications.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _hospitalService.getHospitalDoctors(
        hospitalId: widget.hospitalId,
        authToken: widget.authToken,
      );

      if (response.success && mounted) {
        setState(() {
          _doctors = response.data;
          _filteredDoctors = response.data;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load doctors: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyFilters(Map<String, dynamic> filterData) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _appliedFilters = filterData;
      _isUsingFilters = true;
    });

    try {
      // Build filter request
      final request = api_doctor.FilterDoctorsRequest(
        latitude: 28.6139, // TODO: Get from user's location
        longitude: 77.209,
        speciality: filterData['specialities'] != null 
            ? List<String>.from(filterData['specialities']) 
            : null,
        gender: filterData['gender']?.toString().toUpperCase(),
        distance: filterData['distance']?.toInt(),
        workExperience: _mapExperienceFilter(filterData['experience']),
        availability: _mapAvailabilityFilter(filterData['availability']),
      );

      final response = await _doctorService.getFilteredDoctors(request);

      if (response.success && response.data != null && mounted) {
        // Convert API doctors to hospital doctor model
        final convertedDoctors = response.data!.doctors.map((apiDoctor) {
          return Doctor(
            id: apiDoctor.id,
            name: apiDoctor.name,
            specializations: apiDoctor.specializations,
            degreeTypes: apiDoctor.degreeTypes,
            qualifications: apiDoctor.degreeTypes.join(', '),
            experience: apiDoctor.yearOfExperience,
            rating: apiDoctor.rating,
            timings: null, // Not available in filter API
            availability: null, // Not available in filter API
          );
        }).toList();

        setState(() {
          _doctors = convertedDoctors;
          _filteredDoctors = convertedDoctors;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to apply filters: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String? _mapExperienceFilter(String? experience) {
    if (experience == null) return null;
    if (experience.contains('0 - 5')) return '0-5';
    if (experience.contains('6 - 10')) return '6-10';
    if (experience.contains('10+')) return '10+';
    if (experience.toLowerCase() == 'any') return 'any';
    return null;
  }

  String? _mapAvailabilityFilter(String? availability) {
    if (availability == null) return null;
    if (availability.toLowerCase().contains('today')) return 'TODAY';
    if (availability.toLowerCase().contains('tomorrow')) return 'TOMORROW';
    if (availability.toLowerCase().contains('now')) return 'TODAY';
    return null;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _getAvailabilityStatus(Doctor doctor) {
    if (doctor.availability == null) return 'Queue Not Started';

    switch (doctor.availability!.status) {
      case 'AVAILABLE':
        return 'Available Now';
      case 'NEXT_DAY':
        return doctor.availability!.message;
      case 'BUSY':
        return 'Currently Busy';
      case 'UNAVAILABLE':
        return 'Not Available';
      default:
        return 'Queue Not Started';
    }
  }

  Color _getAvailabilityColor(Doctor doctor) {
    if (doctor.availability == null) return Colors.grey[100]!;

    switch (doctor.availability!.status) {
      case 'AVAILABLE':
        return Colors.green[50]!;
      case 'NEXT_DAY':
        return Colors.blue[50]!;
      case 'BUSY':
        return Colors.orange[50]!;
      case 'UNAVAILABLE':
        return Colors.red[50]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _getTokenAvailability(Doctor doctor) {
    if (doctor.availability?.availableTokens != null &&
        doctor.availability?.totalTokens != null) {
      final available = doctor.availability!.availableTokens!;

      return '$available Tokens Available';
    }
    return 'Token information unavailable';
  }

  String _formatTimings(String? timings) {
    if (timings == null || timings.isEmpty) {
      return '10am - 9:30pm (Mon - Sat)';
    }
    return timings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => EcliniqRouter.pop(),
        ),
        title: Text(
          textAlign: TextAlign.left,
          widget.hospitalName,
          style: EcliniqTextStyles.headlineMedium.copyWith(
            color: Color(0xff424242),
          ),
        ),
      ),

      body: _isLoading
          ? _buildShimmerScreen()
          : Container(
              color: const Color(0xffF9F9F9),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildSearchBar(),
                  _buildFilterOptions(),
                  Expanded(child: _buildDoctorList()),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff626060), width: 0.7),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 4),
            child: Image.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: 20,
              height: 20,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice search coming soon!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: SvgPicture.asset(
                EcliniqIcons.microphone.assetPath,
                width: 16,
                height: 16,
              ),
            ),
          ),
          hintText: 'Search Doctor',
          hintStyle: TextStyle(
            color: Color(0xffD6D6D6),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterButton(
            iconAssetPath: EcliniqIcons.sort.assetPath,
            label: 'Sort',
            onTap: () {
              EcliniqBottomSheet.show(
                context: context,
                child: SortByBottomSheet(),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildFilterButton(
            iconAssetPath:
                EcliniqIcons.filter.assetPath, 
            label: 'Filters',
            onTap: () async {
              final filterData = await EcliniqBottomSheet.show<Map<String, dynamic>>(
                context: context,
                child: DoctorFilterBottomSheet(),
              );
              
              if (filterData != null) {
                _applyFilters(filterData);
              }
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Specialities',
            isSelected: true,
            onTap: () async {
              final specialities = await EcliniqBottomSheet.show<List<String>>(
                context: context,
                child: SelectSpecialitiesBottomSheet(),
              );
              
              if (specialities != null && specialities.isNotEmpty) {
                _applyFilters({'specialities': specialities});
              }
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Availability',
            isSelected: false,
            onTap: () async {
              final availability = await EcliniqBottomSheet.show<String>(
                context: context,
                child: AvailabilityFilterBottomSheet(),
              );
              
              if (availability != null) {
                _applyFilters({'availability': availability});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String iconAssetPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAssetPath,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(Colors.grey[700]!, BlendMode.srcIn),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff424242),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:  Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Color(0xff8E8E8E), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              EcliniqIcons.arrowDown.assetPath,
              width: 16,
              height: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(_filteredDoctors[index]);
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final specializations = doctor.specializations.isNotEmpty
        ? doctor.specializations.join(', ')
        : 'General';
    final qualifications = doctor.degreeTypes.join(', ');
    final experience = doctor.experience != null
        ? '${doctor.experience}yrs of exp'
        : '';

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            _getInitials(doctor.name),
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: SvgPicture.asset(
                            EcliniqIcons.verified.assetPath,
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Doctor Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: EcliniqTextStyles.headlineLarge.copyWith(
                            color: const Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specializations,
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: const Color(0xFF424242),
                          ),
                        ),
                        if (qualifications.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            qualifications,
                            style: EcliniqTextStyles.titleXLarge.copyWith(
                              color: const Color(0xFF424242),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Experience and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (experience.isNotEmpty) ...[
                        SvgPicture.asset(
                          EcliniqIcons.medicalKit.assetPath,
                          width: 24,
                          height: 23,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          experience,
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: const Color(0xFF626060),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '●',
                          style: TextStyle(
                            color: Color(0xff8E8E8E),
                            fontSize: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF9E6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              EcliniqIcons.star.assetPath,
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              doctor.rating?.toStringAsFixed(1) ?? '4.0',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xffBE8B00),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Availability Time
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.appointmentRemindar.assetPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatTimings(doctor.timings),
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: const Color(0xFF626060),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Token Availability
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffF2FFF3),
                      borderRadius: BorderRadius.circular(6),
                    ),

                    child: Text(
                      _getTokenAvailability(doctor),
                      style: EcliniqTextStyles.titleXLarge.copyWith(
                        color: Color(0xff3EAF3F),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Booking Section
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: _getAvailabilityColor(doctor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getAvailabilityStatus(doctor),
                        textAlign: TextAlign.center,
                        style: EcliniqTextStyles.titleXLarge.copyWith(
                          color: const Color(0xff626060),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        EcliniqRouter.push(
                          ClinicVisitSlotScreen(
                            doctorId: doctor.id,
                            hospitalId: widget.hospitalId,
                            doctorName: doctor.name,
                            doctorSpecialization:
                                doctor.specializations.isNotEmpty
                                ? doctor.specializations.first
                                : null,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2372EC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Book Appointment',
                        style: EcliniqTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey[300]),
      ],
    );
  }

  Widget _buildShimmerScreen() {
    return Column(
      children: [
        if (!widget.hideAppBar) const SizedBox(height: 8),
        _buildShimmerSearchBar(),

        Expanded(child: _buildShimmerDoctorList()),
      ],
    );
  }

  Widget _buildShimmerSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerDoctorList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildShimmerDoctorCard();
      },
    );
  }

  Widget _buildShimmerDoctorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 150,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Failed to load doctors',
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDoctors,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2372EC),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'No doctors found matching your search'
                  : 'No doctors available',
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
