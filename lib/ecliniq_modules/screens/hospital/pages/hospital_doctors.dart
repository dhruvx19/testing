// lib/ecliniq_modules/screens/hospital/hospital_doctors_screen.dart

import 'dart:async';

import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart' as api_doctor;
import 'package:ecliniq/ecliniq_api/models/hospital_doctor_model.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/availability_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/filter_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/select_specialities_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/sort_by_filter_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class HospitalDoctorsScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;
  final String authToken;
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
  Timer? _filterDebounceTimer;
  String? _selectedSortOption;

  // Filter state
  List<String>? _selectedSpecialities;
  String? _selectedAvailability;
  Map<String, dynamic>? _otherFilters;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  void _applySort() {
    if (_filteredDoctors.isEmpty || _selectedSortOption == null) return;
    final option = _selectedSortOption!;
    int safeCompare<T extends Comparable>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    double? computeFee(Doctor d) {
      if (d.fee != null) return d.fee;
      double? minFee;
      for (final h in d.hospitals) {
        final val = double.tryParse(h.consultationFee ?? '');
        if (val != null) {
          if (minFee == null || val < minFee) minFee = val;
        }
      }
      for (final c in d.clinics) {
        final val = (c is Map && c['consultationFee'] != null)
            ? (c['consultationFee'] is num
                  ? (c['consultationFee'] as num).toDouble()
                  : double.tryParse(c['consultationFee'].toString()))
            : null;
        if (val != null) {
          if (minFee == null || val < minFee) minFee = val;
        }
      }
      return minFee;
    }

    double? computeDistance(Doctor d) {
      double? minDist;
      for (final h in d.hospitals) {
        final val = h.distanceKm;
        if (val != null) {
          if (minDist == null || val < minDist) minDist = val;
        }
      }
      for (final c in d.clinics) {
        final val = (c is Map && c['distance'] != null)
            ? (c['distance'] is num
                  ? (c['distance'] as num).toDouble()
                  : double.tryParse(c['distance'].toString()))
            : null;
        if (val != null) {
          if (minDist == null || val < minDist) minDist = val;
        }
      }
      return minDist;
    }

    setState(() {
      switch (option) {
        case 'Price: Low - High':
          _filteredDoctors.sort(
            (a, b) => safeCompare(computeFee(a), computeFee(b)),
          );
          break;
        case 'Price: High - Low':
          _filteredDoctors.sort(
            (a, b) => safeCompare(computeFee(b), computeFee(a)),
          );
          break;
        case 'Experience - Most Experience first':
          _filteredDoctors.sort(
            (a, b) => safeCompare(b.experience, a.experience),
          );
          break;
        case 'Distance - Nearest First':
          _filteredDoctors.sort(
            (a, b) => safeCompare(computeDistance(a), computeDistance(b)),
          );
          break;
        case 'Order A-Z':
          _filteredDoctors.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case 'Order Z-A':
          _filteredDoctors.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
        case 'Rating High - low':
          _filteredDoctors.sort((a, b) => safeCompare(b.rating, a.rating));
          break;
        case 'Rating Low - High':
          _filteredDoctors.sort((a, b) => safeCompare(a.rating, b.rating));
          break;
        case 'Relevance':
        default:
          // no-op
          break;
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _filterDebounceTimer?.cancel();
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
    _applySort();
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
        _applySort();
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

  void _applyFiltersDebounced() {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      _applyFilters();
    });
  }

  Future<void> _applyFilters() async {
    // Check if any filters are actually applied
    final hasFilters =
        (_selectedSpecialities != null && _selectedSpecialities!.isNotEmpty) ||
        _selectedAvailability != null ||
        (_otherFilters != null && _otherFilters!.isNotEmpty);

    if (!hasFilters) {
      // No filters, fetch original hospital doctors
      _fetchDoctors();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user location from stored location or provider
      double? latitude;
      double? longitude;

      // Try to get from stored location
      final storedLocation = await LocationStorageService.getStoredLocation();
      if (storedLocation != null) {
        latitude = storedLocation['latitude'] as double;
        longitude = storedLocation['longitude'] as double;
      }

      // Build filter request
      final request = api_doctor.FilterDoctorsRequest(
        latitude: latitude ?? 28.6139,
        longitude: longitude ?? 77.209,
        speciality: _normalizeSpecialities(_selectedSpecialities),
        gender: _otherFilters?['gender']?.toString().toUpperCase(),
        distance: (_otherFilters?['distance'] is num)
            ? (_otherFilters!['distance'] as num).toDouble()
            : null,
        workExperience: _mapExperienceFilter(_otherFilters?['experience']),
        availability: _mapAvailabilityFilter(_selectedAvailability),
      );

      final response = await _doctorService.getFilteredDoctors(request);

      if (response.success && response.data != null && mounted) {
        // Filter API returns data.data (nested structure)
        // Convert API doctors to hospital doctor model
        final convertedDoctors = response.data!.doctors.map((apiDoctor) {
          return Doctor(
            id: apiDoctor.id,
            firstName: apiDoctor.firstName ?? '',
            lastName: apiDoctor.lastName ?? '',
            headline: apiDoctor.headline,
            specialization: apiDoctor.specializations.join(', '),
            qualifications: apiDoctor.degreeTypes.join(', '),
            experience: apiDoctor.yearOfExperience,
            rating: apiDoctor.rating,
            fee: apiDoctor.fee,
            timings: null, // Not available in filter API
            availability: null, // Not available in filter API
            profilePhoto: apiDoctor.profilePhoto,
            hospitals: apiDoctor.hospitals.map((h) {
              return DoctorHospital(
                id: h.id,
                name: h.name,
                city: h.city,
                state: h.state,
                latitude: h.latitude,
                longitude: h.longitude,
                distanceKm: h.distance,
                consultationFee: h.consultationFee?.toString(),
              );
            }).toList(),
            clinics: apiDoctor.clinics.map((c) {
              return {
                'id': c.id,
                'name': c.name,
                'city': c.city,
                'state': c.state,
                'latitude': c.latitude,
                'longitude': c.longitude,
                'distance': c.distance,
                'consultationFee': c.consultationFee,
              };
            }).toList(),
            isFavourite: apiDoctor.isFavourite,
          );
        }).toList();

        setState(() {
          _doctors = convertedDoctors;
          _filteredDoctors = convertedDoctors;
          _isLoading = false;
        });
        _applySort();
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

  List<String>? _normalizeSpecialities(List<String>? selected) {
    if (selected == null || selected.isEmpty) return null;
    final map = <String, String>{
      'General Physician / Family Doctor': 'General Physician',
      'Pediatrician (Child Specialist)': 'Pediatrics',
      "Gynaecologist (Women's Health Doctor)": 'Gynaecology',
      'Dentist': 'Dentistry',
      'Dermatologist (Skin Doctor)': 'Dermatology',
      'ENT (Ear, Nose, Throat Specialist)': 'ENT',
      'Ophthalmologist (Eye Specialist)': 'Ophthalmology',
      'Cardiologist (Heart Specialist)': 'Cardiology',
      'Orthopedic (Bone & Joint Specialist)': 'Orthopedics',
      'Diabetologist (Sugar Specialist)': 'Diabetology',
    };

    return selected
        .map((s) => s.trim())
        .map((s) => map[s] ?? _stripParentheses(s))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  }

  String _stripParentheses(String s) {
    final withoutParen = s.replaceAll(RegExp(r"\s*\(.*?\)"), '').trim();
    // Handle common suffixes
    if (withoutParen.contains('/')) {
      return withoutParen.split('/').first.trim();
    }
    return withoutParen;
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
        return 'Queue Started';
      case 'NEXT_DAY':
        return doctor.availability!.message;
      case 'BUSY':
        return 'Currently Busy';
      case 'UNAVAILABLE':
        return 'Queue Not Started';
      default:
        return 'Queue Not Started';
    }
  }

  Color _getAvailabilityBackgroundColor(Doctor doctor) {
    if (doctor.availability == null) return Colors.yellow[50]!;

    switch (doctor.availability!.status) {
      case 'AVAILABLE':
        return Colors.green[50]!;
      case 'NEXT_DAY':
        return Colors.white;
      case 'BUSY':
        return Colors.orange[50]!;
      case 'UNAVAILABLE':
        return Colors.yellow[50]!;
      default:
        return Colors.yellow[50]!;
    }
  }

  Color _getAvailabilityTextColor(Doctor doctor) {
    if (doctor.availability == null) return Colors.grey[600]!;

    switch (doctor.availability!.status) {
      case 'AVAILABLE':
        return Colors.green[700]!;
      case 'NEXT_DAY':
        return Colors.grey[600]!;
      case 'BUSY':
        return Colors.orange[700]!;
      case 'UNAVAILABLE':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildAvailabilityStatusWidget(Doctor doctor) {
    if (doctor.availability == null ||
        doctor.availability!.status == 'UNAVAILABLE') {
      // Queue Not Started - yellow container, grey text
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.yellow[50]!,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'Queue Not Started',
            textAlign: TextAlign.center,
            style: EcliniqTextStyles.titleXLarge.copyWith(
              color: Colors.grey[600]!,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (doctor.availability!.status == 'AVAILABLE') {
      // Queue Started - green container, green text
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.green[50]!,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            'Queue Started',
            textAlign: TextAlign.center,
            style: EcliniqTextStyles.titleXLarge.copyWith(
              color: Colors.green[700]!,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (doctor.availability!.status == 'NEXT_DAY') {
      // Next available - white container, "Next available" in grey, day/time in blue
      final message = doctor.availability!.message;
      // Parse message like "Next available Wednesday, 3:30 AM"
      String prefix = '';
      String dayTime = message;

      if (message.toLowerCase().startsWith('next available')) {
        prefix = 'Next available';
        dayTime = message.substring('Next available'.length).trim();
      }

      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Color(0xffF9F9F9),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: EcliniqTextStyles.labelMedium.copyWith(
                color: Color(0xff2372EC),
              ),
              children: [
                if (prefix.isNotEmpty) ...[TextSpan(text: '$prefix ')],
                TextSpan(
                  text: dayTime,
                  style: EcliniqTextStyles.titleXLarge.copyWith(
                    color: const Color(0xff626060),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default case
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _getAvailabilityBackgroundColor(doctor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          _getAvailabilityStatus(doctor),
          textAlign: TextAlign.center,
          style: EcliniqTextStyles.titleXLarge.copyWith(
            color: _getAvailabilityTextColor(doctor),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
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
        leadingWidth: 58,
        titleSpacing: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            widget.hospitalName,
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 0.5),
        ),
      ),
      body: Container(
        color: const Color(0xffF9F9F9),
        child: Column(
          children: [
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
      margin: EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xff626060), width: 0.5),
      ),
      child: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SvgPicture.asset(
            EcliniqIcons.magnifierMyDoctor.assetPath,
            height: 24,
            width: 24,
          ),
          Expanded(
            child: TextField(
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: 'Search Doctor',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          SvgPicture.asset(
            EcliniqIcons.microphone.assetPath,
            height: 32,
            width: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          _buildFilterButton(
            iconAssetPath: EcliniqIcons.sort.assetPath,
            label: 'Sort',
            onTap: () {
              EcliniqBottomSheet.show(
                context: context,
                child: SortByBottomSheet(
                  onChanged: (option) {
                    setState(() {
                      _selectedSortOption = option;
                      _applySort();
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Container(width: 0.5, height: 20, color: const Color(0xffD6D6D6)),
          const SizedBox(width: 12),
          _buildFilterButton(
            iconAssetPath: EcliniqIcons.filter.assetPath,
            label: 'Filters',
            onTap: () {
              EcliniqBottomSheet.show(
                context: context,
                child: DoctorFilterBottomSheet(
                  onFilterChanged: (filterData) {
                    setState(() {
                      _otherFilters = filterData;
                      final specs = filterData['specialities'];
                      if (specs is List) {
                        _selectedSpecialities = specs.cast<String>();
                      }
                      final avail = filterData['availability'];
                      if (avail is String?) {
                        _selectedAvailability = avail;
                      }
                    });
                    _applyFiltersDebounced();
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Container(width: 0.5, height: 20, color: const Color(0xffD6D6D6)),
          const SizedBox(width: 12),
          _buildFilterChip(
            label: 'Specialities',
            isSelected:
                _selectedSpecialities != null &&
                _selectedSpecialities!.isNotEmpty,
            onTap: () {
              EcliniqBottomSheet.show(
                context: context,
                child: SelectSpecialitiesBottomSheet(
                  initialSelection: _selectedSpecialities,
                  onSelectionChanged: (specialities) {
                    setState(() {
                      _selectedSpecialities = specialities.isEmpty
                          ? null
                          : specialities;
                    });
                    _applyFiltersDebounced();
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Availability',
            isSelected: _selectedAvailability != null,
            onTap: () async {
              final availability = await EcliniqBottomSheet.show<String>(
                context: context,
                child: AvailabilityFilterBottomSheet(),
              );

              if (availability != null) {
                setState(() {
                  _selectedAvailability = availability;
                });
                _applyFiltersDebounced();
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
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
                color: Color(0xff424242),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 0.5, height: 20, color: const Color(0xffD6D6D6)),
            const SizedBox(width: 8),
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
    if (_isLoading) {
      return _buildShimmerDoctorList();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredDoctors.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16),
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
                      color: Color(0xffF8FAFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xff96BFFF), width: 0.5),
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
              const SizedBox(height: 16),
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
                          height: 24,
                        ),
                        const SizedBox(width: 8),
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
                            fontSize: 6,
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
                          borderRadius: BorderRadius.circular(6),
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
                                fontWeight: FontWeight.w400,
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
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 4),
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
                    child: _buildAvailabilityStatusWidget(doctor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x4D2372EC),
                            offset: Offset(2, 2),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
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
                          backgroundColor: Color(0xff2372EC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
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
      padding: EdgeInsets.only(bottom: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildShimmerDoctorCard();
      },
    );
  }

  Widget _buildShimmerDoctorCard() {
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
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 80,
                      height: 80,
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
                        const SizedBox(height: 4),
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: 100,
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
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 200,
                  height: 16,
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
                  width: 150,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
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
          SvgPicture.asset(EcliniqIcons.noDoctor.assetPath),
          const SizedBox(height: 8),
          Text(
            'No Doctor Match Found',
            style: EcliniqTextStyles.bodyMedium.copyWith(
              color: Color(0xff424242),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
