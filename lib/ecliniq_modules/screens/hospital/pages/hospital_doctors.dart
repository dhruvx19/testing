import 'dart:async';

import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart' as api_doctor;
import 'package:ecliniq/ecliniq_api/models/hospital_doctor_model.dart';
import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
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
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:ecliniq/ecliniq_utils/speech_helper.dart';

class HospitalDoctorsScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;
  final String authToken;
  final bool hideAppBar;
  final VoidCallback? onBackPressed;

  const HospitalDoctorsScreen({
    super.key,
    this.onBackPressed,
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
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final SpeechHelper _speechHelper = SpeechHelper();

  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  Timer? _filterDebounceTimer;
  String? _selectedSortOption;
  bool get _isListening => _speechHelper.isListening;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  List<String>? _selectedSpecialities;
  String? _selectedAvailability;
  Map<String, dynamic>? _otherFilters;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _searchController.addListener(_onSearchChanged);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speechHelper.initSpeech(
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
      mounted: () => mounted,
    );
  }

  void _startListening() async {
    await _speechHelper.startListening(
      onResult: _onSpeechResult,
      onError: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
          );
        }
      },
      mounted: () => mounted,
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _stopListening() async {
    await _speechHelper.stopListening(
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _searchController.text = result.recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: result.recognizedWords.length),
    );

    setState(() {
      _searchQuery = result.recognizedWords.toLowerCase();
      _filterDoctors();
    });

    if (result.finalResult) {
      _stopListening();
    }
  }

  void _toggleVoiceSearch() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
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
          break;
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _filterDebounceTimer?.cancel();
    _speechHelper.cancel();
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
          _retryCount = 0; // Reset retry count on success
        });
        _applySort();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
            _retryCount++; // Increment retry count on failure
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load doctors: ${e.toString()}';
          _isLoading = false;
          _retryCount++; // Increment retry count on error
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
    final hasFilters =
        (_selectedSpecialities != null && _selectedSpecialities!.isNotEmpty) ||
        _selectedAvailability != null ||
        (_otherFilters != null && _otherFilters!.isNotEmpty);

    if (!hasFilters) {
      _fetchDoctors();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const double latitude = 12.9173;
      const double longitude = 77.6377;

      final request = api_doctor.FilterDoctorsRequest(
        latitude: latitude,
        longitude: longitude,
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
            timings: null,
            availability: null,
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
          _retryCount = 0; // Reset retry count on success
        });
        _applySort();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
            _retryCount++; // Increment retry count on failure
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to apply filters: ${e.toString()}';
          _isLoading = false;
          _retryCount++; // Increment retry count on error
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
      return Container(
        height: EcliniqTextStyles.getResponsiveButtonHeight(
          context,
          baseHeight: 52.0,
        ),
        decoration: BoxDecoration(
          color: Colors.yellow[50]!,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
          ),
        ),
        child: Center(
          child: Text(
            'Queue Not Started',
            textAlign: TextAlign.center,
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(color: Colors.grey[600]!),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (doctor.availability!.status == 'AVAILABLE') {
      return Container(
        height: EcliniqTextStyles.getResponsiveButtonHeight(
          context,
          baseHeight: 52.0,
        ),
        decoration: BoxDecoration(
          color: Colors.green[50]!,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedDot(),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
              ),
              Text(
                'Queue Started',
                textAlign: TextAlign.center,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Colors.green[700]!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    if (doctor.availability!.status == 'NEXT_DAY') {
      final message = doctor.availability!.message;

      String prefix = '';
      String dayTime = message;

      if (message.toLowerCase().startsWith('next available')) {
        prefix = 'Next available';
        dayTime = message.substring('Next available'.length).trim();
      }

      return Container(
        height: EcliniqTextStyles.getResponsiveButtonHeight(
          context,
          baseHeight: 52.0,
        ),
        decoration: BoxDecoration(
          color: Color(0xffF9F9F9),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (prefix.isNotEmpty)
                Text(
                  prefix,
                  style: EcliniqTextStyles.responsiveLabelMedium(
                    context,
                  ).copyWith(color: Color(0xff2372EC)),
                  textAlign: TextAlign.center,
                ),
              Text(
                dayTime,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: const Color(0xff626060)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
      decoration: BoxDecoration(
        color: _getAvailabilityBackgroundColor(doctor),
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
        ),
      ),
      child: Center(
        child: Text(
          _getAvailabilityStatus(doctor),
          textAlign: TextAlign.center,
          style: EcliniqTextStyles.responsiveTitleXLarge(
            context,
          ).copyWith(color: _getAvailabilityTextColor(doctor)),
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
        surfaceTintColor: Colors.transparent,
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
        titleSpacing: 0,
        toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${widget.hospitalName} Doctors',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 0.2),
          ),
          child: Container(
            color: Color(0xFFB8B8B8),
            height: EcliniqTextStyles.getResponsiveSize(context, 0.5),
          ),
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
      margin: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        top: 12.0,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      height: EcliniqTextStyles.getResponsiveHeight(context, 50.0),
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        vertical: 0,
        context,
        horizontal: 10.0,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
        ),
        border: Border.all(
          color: Color(0xff626060),
          width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
        ),
      ),
      child: Row(
        spacing: EcliniqTextStyles.getResponsiveSpacing(context, 10.0),
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SvgPicture.asset(
            EcliniqIcons.magnifierMyDoctor.assetPath,
            height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
            width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: 'Search Doctor',
                hintStyle: TextStyle(
                  color: Color(0xff8E8E8E),
                  fontWeight: FontWeight.w400,
                  fontSize: EcliniqTextStyles.getResponsiveFontSize(
                    context,
                    18.0,
                  ),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleVoiceSearch,
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: 2.0,
              ),
              child: SvgPicture.asset(
                EcliniqIcons.microphone.assetPath,
                height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                colorFilter: _isListening
                    ? const ColorFilter.mode(Color(0xFF2372EC), BlendMode.srcIn)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        left: 16.0,

        bottom: 16.0,
      ),
      child: Row(
        children: [
          _buildFilterButton(
            iconAssetPath: EcliniqIcons.sort.assetPath,
            label: 'Sort',
            onTap: () {
              EcliniqBottomSheet.show(
                context: context,
                child: SortByBottomSheet(
                  initialSortOption: _selectedSortOption,
                  onChanged: (option) {
                    setState(() {
                      if (option.isEmpty) {
                        _selectedSortOption = null;
                      } else {
                        _selectedSortOption = option;
                      }
                      _applySort();
                    });
                  },
                ),
              );
            },
          ),
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
          Container(width: 0.5, height: 20.0, color: const Color(0xffD6D6D6)),
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
          _buildFilterButton(
            iconAssetPath: EcliniqIcons.filter.assetPath,
            label: 'Filters',
            showRedIndicator: _hasActiveFilters(),
            onTap: () {
              EcliniqBottomSheet.show(
                context: context,
                child: DoctorFilterBottomSheet(
                  onFilterChanged: (filterData) {
                    setState(() {
                      if (!_hasActiveFiltersInParams(filterData)) {
                        _otherFilters = null;
                        _selectedSpecialities = null;
                        _selectedAvailability = null;

                        _fetchDoctors();
                      } else {
                        _otherFilters = filterData;
                        final specs = filterData['specialities'];
                        if (specs is List) {
                          _selectedSpecialities = specs.cast<String>();
                        }
                        final avail = filterData['availability'];
                        if (avail is String?) {
                          _selectedAvailability = avail;
                        }

                        _applyFiltersDebounced();
                      }
                    });
                  },
                ),
              );
            },
          ),
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 2.0)),
          Container(width: 0.5, height: 20, color: const Color(0xffD6D6D6)),
          SizedBox(
            width: EcliniqTextStyles.getResponsiveSpacing(context, 14.0),
          ),
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
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
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
    bool showRedIndicator = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 12.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  iconAssetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
                  height: EcliniqTextStyles.getResponsiveIconSize(
                    context,
                    16.0,
                  ),
                  colorFilter: ColorFilter.mode(
                    Colors.grey[700]!,
                    BlendMode.srcIn,
                  ),
                ),
                if (showRedIndicator)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
                      height: EcliniqTextStyles.getResponsiveSize(context, 8.0),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
            ),
            Text(
              label,
              style: EcliniqTextStyles.responsiveBodySmall(
                context,
              ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff424242)),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
            ),
            SvgPicture.asset(
              EcliniqIcons.arrowDown.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFiltersInParams(Map<String, dynamic> filterData) {
    return (filterData['specialities'] as List?)?.isNotEmpty == true ||
        filterData['availability'] != null ||
        filterData['gender'] != null ||
        filterData['experience'] != null ||
        (filterData['distance'] != null &&
            (filterData['distance'] as num) != 50);
  }

  bool _hasActiveFilters() {
    return (_selectedSpecialities != null &&
            _selectedSpecialities!.isNotEmpty) ||
        _selectedAvailability != null ||
        (_otherFilters != null && _hasActiveFiltersInParams(_otherFilters!));
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 8.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
          ),
          border: Border.all(
            color: Color(0xff8E8E8E),
            width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: EcliniqTextStyles.responsiveBodySmall(
                context,
              ).copyWith(fontWeight: FontWeight.w500, color: Color(0xff424242)),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
            ),
            Container(width: 0.5, height: 20, color: const Color(0xffD6D6D6)),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
            ),
            SvgPicture.asset(
              EcliniqIcons.arrowDown.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 16.0),
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
      // Show shimmer and auto-retry on error if within retry limit
      if (_retryCount < _maxRetries) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _errorMessage != null && _retryCount < _maxRetries) {
            // Retry with filters if they are active, otherwise fetch all doctors
            if (_hasActiveFilters()) {
              _applyFilters();
            } else {
              _fetchDoctors();
            }
          }
        });
        return _buildShimmerDoctorList();
      } else {
        // Max retries reached, show error state
        return _buildErrorState();
      }
    }

    if (_filteredDoctors.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        bottom: 16.0,
      ),
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
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: qualifications.isEmpty
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    width: EcliniqTextStyles.getResponsiveWidth(context, 80),
                    height: EcliniqTextStyles.getResponsiveHeight(context, 80),
                    decoration: BoxDecoration(
                      color: Color(0xffF8FAFF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xff96BFFF),
                        width: EcliniqTextStyles.getResponsiveSize(
                          context,
                          0.5,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: FutureBuilder<String?>(
                            future: doctor.getProfilePhotoUrl(_storageService),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const EcliniqLoader(size: 24);
                              }
                              final imageUrl = snapshot.data;
                              if (imageUrl != null && imageUrl.isNotEmpty) {
                                return ClipOval(
                                  child: Image.network(
                                    imageUrl,
                                    width: EcliniqTextStyles.getResponsiveWidth(
                                      context,
                                      80,
                                    ),
                                    height:
                                        EcliniqTextStyles.getResponsiveHeight(
                                          context,
                                          80,
                                        ),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        _getInitials(doctor.name),
                                        style:
                                            EcliniqTextStyles.responsiveHeadlineXXXLarge(
                                              context,
                                            ).copyWith(
                                              color: Colors.blue.shade700,
                                            ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const EcliniqLoader(size: 24);
                                        },
                                  ),
                                );
                              }
                              return Text(
                                _getInitials(doctor.name),
                                style:
                                    EcliniqTextStyles.responsiveHeadlineXXXLarge(
                                      context,
                                    ).copyWith(color: Colors.blue.shade700),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: SvgPicture.asset(
                            EcliniqIcons.verified.assetPath,
                            width: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              24,
                            ),
                            height: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: qualifications.isEmpty
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: EcliniqTextStyles.responsiveHeadlineLarge(
                            context,
                          ).copyWith(color: const Color(0xFF424242)),
                        ),
                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            2.0,
                          ),
                        ),
                        Text(
                          specializations,
                          style: EcliniqTextStyles.responsiveTitleXLarge(
                            context,
                          ).copyWith(color: const Color(0xFF424242)),
                        ),
                        if (qualifications.isNotEmpty) ...[
                          SizedBox(
                            height: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              2.0,
                            ),
                          ),
                          Text(
                            qualifications,
                            style: EcliniqTextStyles.responsiveTitleXLarge(
                              context,
                            ).copyWith(color: const Color(0xFF424242)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (experience.isNotEmpty) ...[
                        SvgPicture.asset(
                          EcliniqIcons.medicalKit.assetPath,
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
                            8.0,
                          ),
                        ),
                        Text(
                          experience,
                          style: EcliniqTextStyles.responsiveTitleXLarge(
                            context,
                          ).copyWith(color: const Color(0xFF626060)),
                        ),
                        SizedBox(
                          width: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            8.0,
                          ),
                        ),
                        Text(
                          '●',
                          style: TextStyle(
                            color: Color(0xff8E8E8E),
                            fontSize: EcliniqTextStyles.getResponsiveFontSize(
                              context,
                              6.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            8.0,
                          ),
                        ),
                      ],
                      Container(
                        padding:
                            EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                              context,
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF9E6),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              6.0,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              EcliniqIcons.star.assetPath,
                              width: EcliniqTextStyles.getResponsiveIconSize(
                                context,
                                18.0,
                              ),
                              height: EcliniqTextStyles.getResponsiveIconSize(
                                context,
                                18.0,
                              ),
                            ),
                            SizedBox(
                              width: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                2.0,
                              ),
                            ),
                            Text(
                              doctor.rating?.toStringAsFixed(1) ?? '4.0',
                              style:
                                  EcliniqTextStyles.responsiveTitleXLarge(
                                    context,
                                  ).copyWith(
                                    color: Color(0xffBE8B00),
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      4.0,
                    ),
                  ),

                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.appointmentRemindar.assetPath,
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
                          8.0,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatTimings(doctor.timings),
                          style: EcliniqTextStyles.responsiveTitleXLarge(
                            context,
                          ).copyWith(color: const Color(0xFF626060)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      4.0,
                    ),
                  ),

                  Container(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                      context,
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xffF2FFF3),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          6.0,
                        ),
                      ),
                    ),

                    child: Text(
                      _getTokenAvailability(doctor),
                      style: EcliniqTextStyles.responsiveTitleXLarge(
                        context,
                      ).copyWith(color: Color(0xff3EAF3F)),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),

              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildAvailabilityStatusWidget(doctor),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      12.0,
                    ),
                  ),
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
                          minimumSize: Size(
                            0,
                            EcliniqTextStyles.getResponsiveButtonHeight(
                              context,
                              baseHeight: 52.0,
                            ),
                          ),
                          padding:
                              EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                context,
                                vertical: 14.0,
                                horizontal: 2.0,
                              ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              EcliniqTextStyles.getResponsiveBorderRadius(
                                context,
                                4.0,
                              ),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Book Appointment',
                          style: EcliniqTextStyles.responsiveHeadlineMedium(
                            context,
                          ).copyWith(color: Colors.white),
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


  Widget _buildShimmerDoctorList() {
    return ListView.builder(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        bottom: 16.0,
      ),
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
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
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
                      width: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        80.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveHeight(
                        context,
                        80.0,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      16.0,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: EcliniqTextStyles.getResponsiveWidth(
                              context,
                              150.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveSize(
                              context,
                              20.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                EcliniqTextStyles.getResponsiveBorderRadius(
                                  context,
                                  4.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            8.0,
                          ),
                        ),
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: EcliniqTextStyles.getResponsiveWidth(
                              context,
                              120.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveSize(
                              context,
                              16.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                EcliniqTextStyles.getResponsiveBorderRadius(
                                  context,
                                  4.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: EcliniqTextStyles.getResponsiveSpacing(
                            context,
                            4.0,
                          ),
                        ),
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(
                            width: EcliniqTextStyles.getResponsiveWidth(
                              context,
                              100.0,
                            ),
                            height: EcliniqTextStyles.getResponsiveSize(
                              context,
                              16.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                EcliniqTextStyles.getResponsiveBorderRadius(
                                  context,
                                  4.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: EcliniqTextStyles.getResponsiveWidth(context, 200.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
              ),
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 32.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 6.0),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: EcliniqTextStyles.getResponsiveButtonHeight(
                          context,
                          baseHeight: 52.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              4.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      12.0,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: EcliniqTextStyles.getResponsiveButtonHeight(
                          context,
                          baseHeight: 52.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              4.0,
                            ),
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
        Container(
          height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
            color: Colors.grey[400],
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
          ),
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              vertical: 0,
              horizontal: 32.0,
            ),
            child: Text(
              _errorMessage ?? 'Failed to load doctors',
              style: EcliniqTextStyles.responsiveBodyMedium(
                context,
              ).copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _retryCount = 0; // Reset retry count on manual retry
              });
              // Retry with filters if they are active, otherwise fetch all doctors
              if (_hasActiveFilters()) {
                _applyFilters();
              } else {
                _fetchDoctors();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2372EC),
              foregroundColor: Colors.white,
              minimumSize: Size(
                0,
                EcliniqTextStyles.getResponsiveButtonHeight(
                  context,
                  baseHeight: 52.0,
                ),
              ),
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
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
          ),
          Text(
            'No Doctor Match Found',
            style: EcliniqTextStyles.responsiveBodyMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  const _AnimatedDot();

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.green[700]!,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
