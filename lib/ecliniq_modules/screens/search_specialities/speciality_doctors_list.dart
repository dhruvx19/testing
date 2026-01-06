import 'dart:async';

import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart' as api_doctor;
import 'package:ecliniq/ecliniq_api/models/hospital_doctor_model.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/location_search.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';

class SpecialityDoctorsList extends StatefulWidget {
  final String? initialSpeciality;

  const SpecialityDoctorsList({super.key, this.initialSpeciality});

  @override
  State<SpecialityDoctorsList> createState() => _SpecialityDoctorsListState();
}

class _SpecialityDoctorsListState extends State<SpecialityDoctorsList> {
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();

  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _currentLocation = 'Vishnu Dev Nagar, Wakad';
  Timer? _debounceTimer;
  String? _selectedSortOption;
  Map<String, dynamic> _filterParams = {};

  double _latitude = 28.6139;
  double _longitude = 77.209;

  // Updated category list to match UI
  final List<String> _categories = [
    'All',
    'General Physician',
    'Paediatrics',
    'Gynaecology',
    'Dermatology',
    'Cardiology',
    'Orthopedics',
    'ENT',
    'Ophthalmology',
    'Neurology',
    'Psychiatry',
    'Dentistry',
  ];

  // Keys for each category to measure their positions
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    // Initialize keys for all categories
    for (var category in _categories) {
      _categoryKeys[category] = GlobalKey();
    }

    if (widget.initialSpeciality != null) {
      _selectedCategory = widget.initialSpeciality!;
      // Add initial speciality if not in list
      if (!_categories.contains(widget.initialSpeciality)) {
        _categories.insert(1, widget.initialSpeciality!);
        _categoryKeys[widget.initialSpeciality!] = GlobalKey();
      }
    }
    _loadLocationAndFetch();
    _searchController.addListener(_onSearchChanged);

    // Auto scroll to initial category after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCategory(_selectedCategory);
    });
  }

  Future<void> _loadLocationAndFetch() async {
    // Load location from storage
    final storedLocation = await LocationStorageService.getStoredLocation();
    if (storedLocation != null) {
      setState(() {
        _latitude = storedLocation['latitude'] as double;
        _longitude = storedLocation['longitude'] as double;
        _currentLocation = storedLocation['locationName'] as String? ?? 'Current Location';
      });
    }
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _categoryScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _scrollToCategory(String category) {
    final key = _categoryKeys[category];
    if (key?.currentContext != null) {
      final RenderBox renderBox =
          key!.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenWidth = MediaQuery.of(context).size.width;
      final boxWidth = renderBox.size.width;

      // Calculate scroll offset to center the selected category
      final scrollOffset =
          _categoryScrollController.offset +
          position.dx -
          (screenWidth / 2) +
          (boxWidth / 2);

      _categoryScrollController.animateTo(
        scrollOffset.clamp(
          0.0,
          _categoryScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    _scrollToCategory(category);
    _fetchDoctors();
  }

  void _openSort() {
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
  }

  void _openFilter() {
    EcliniqBottomSheet.show(
      context: context,
      child: DoctorFilterBottomSheet(
        onFilterChanged: (params) {
          setState(() {
            _filterParams = params;
            // Update selected category if specialities changed in filter
            if (params['specialities'] != null &&
                (params['specialities'] as List).isNotEmpty) {
              // If single speciality, select it in tabs, else 'All' or keep as is?
              // For now, let filter override or coexist.
              // The API request prioritizes explicit speciality list.
            }
          });
          _fetchDoctors();
        },
      ),
    );
  }

  void _applySort() {
    if (_doctors.isEmpty || _selectedSortOption == null) return;

    final option = _selectedSortOption!;

    int safeCompare<T extends Comparable>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    double? computeFee(Doctor d) {
      return d.fee;
    }

    double? computeDistance(Doctor d) {
      double? minDist;
      for (final h in d.hospitals) {
        final val = h.distanceKm;
        if (val != null) {
          if (minDist == null || val < minDist) minDist = val;
        }
      }
      return minDist;
    }

    setState(() {
      switch (option) {
        case 'Price: Low - High':
          _doctors.sort((a, b) => safeCompare(computeFee(a), computeFee(b)));
          break;
        case 'Price: High - Low':
          _doctors.sort((a, b) => safeCompare(computeFee(b), computeFee(a)));
          break;
        case 'Experience - Most Experience first':
          _doctors.sort((a, b) => safeCompare(b.experience, a.experience));
          break;
        case 'Distance - Nearest First':
          _doctors.sort(
            (a, b) => safeCompare(computeDistance(a), computeDistance(b)),
          );
          break;
        case 'Order A-Z':
          _doctors.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case 'Order Z-A':
          _doctors.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
        case 'Rating High - low':
          _doctors.sort((a, b) => safeCompare(b.rating, a.rating));
          break;
        case 'Rating Low - High':
          _doctors.sort((a, b) => safeCompare(a.rating, b.rating));
          break;
        case 'Relevance':
        default:
          // Default order from API
          break;
      }
    });
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<String>? specialityFilter;

      // Merge tab selection with bottom sheet filter
      if (_filterParams['specialities'] != null &&
          (_filterParams['specialities'] as List).isNotEmpty) {
        specialityFilter = (_filterParams['specialities'] as List)
            .cast<String>();
      } else if (_selectedCategory != 'All') {
        specialityFilter = [_selectedCategory];
      }

      final request = api_doctor.FilterDoctorsRequest(
        latitude: _latitude,
        longitude: _longitude,
        speciality: specialityFilter,
        gender: _filterParams['gender']?.toString().toUpperCase(),
        distance: (_filterParams['distance'] is num)
            ? (_filterParams['distance'] as num).toDouble()
            : null,
        workExperience: _mapExperienceFilter(_filterParams['experience']),
        availability: _mapAvailabilityFilter(_filterParams['availability']),
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

  List<Doctor> get _filteredDoctors {
    if (_searchQuery.isEmpty) {
      return _doctors;
    }
    return _doctors.where((doctor) {
      final name = doctor.name.toLowerCase();
      final specializations = doctor.specialization.toLowerCase();
      final qualifications = doctor.qualifications.toLowerCase();
      return name.contains(_searchQuery) ||
          specializations.contains(_searchQuery) ||
          qualifications.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
         surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
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
            'Doctors',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openSort,
            icon: SvgPicture.asset(
              EcliniqIcons.sortAlt.assetPath,
              width: 32,
              height: 32,
            ),
          ),
          VerticalDivider(
            color: Color(0xffD6D6D6),
            thickness: 1,
            width: 24,
            indent: 18,
            endIndent: 18,
          ),
          IconButton(
            onPressed: _openFilter,
            icon: SvgPicture.asset(
              EcliniqIcons.filter.assetPath,
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFB8B8B8), height: 0.5),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildLocationSection(),
            _buildSearchBar(),
            _buildCategoryFilters(),
            Expanded(child: _buildDoctorList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return GestureDetector(
      onTap: () {
        EcliniqBottomSheet.show(
          context: context,
          child: LocationBottomSheet(currentLocation: _currentLocation),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            SvgPicture.asset(
              EcliniqIcons.mapPointBlue.assetPath,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _currentLocation,
              style: EcliniqTextStyles.headlineXMedium.copyWith(
                color: Color(0xff424242),
              ),
            ),
            SizedBox(width: 10),
            Container(height: 20, width: 0.5, color: Color(0xffD6D6D6)),
            const SizedBox(width: 8.0),
            SvgPicture.asset(
              EcliniqIcons.arrowDown.assetPath,
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF626060), width: 0.5),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: SvgPicture.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: 24,
              height: 24,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: Color(0xFF424242),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Search Doctor',
                hintStyle: TextStyle(
                  color: Color(0xFF8E8E8E),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              cursorColor: Color(0xFF2372EC),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SvgPicture.asset(
                EcliniqIcons.microphone.assetPath,
                width: 32,
                height: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: SingleChildScrollView(
        controller: _categoryScrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                key: _categoryKeys[category],
                onTap: () => _onCategorySelected(category),
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? Color(0xFF2372EC)
                                  : Color(0xFF626060),
                            ),
                          ),
                        ),
                        Container(
                          height: 2,
                          color: isSelected
                              ? Color(0xFF2372EC)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
      );
    }

    final doctors = _filteredDoctors;

    if (doctors.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        return _buildDoctorCard(doctors[index]);
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(width: 150, height: 16, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(width: 100, height: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 100, height: 16, color: Colors.white),
                const SizedBox(width: 16),
                Container(width: 60, height: 16, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
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
                          doctor.specialization.isNotEmpty
                              ? doctor.specialization
                              : 'General',
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: const Color(0xFF424242),
                          ),
                        ),
                        if (doctor.qualifications.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            doctor.qualifications,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (doctor.experience != null) ...[
                        SvgPicture.asset(
                          EcliniqIcons.medicalKit.assetPath,
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.experience}yrs of exp',
                          style: EcliniqTextStyles.titleXLarge.copyWith(
                            color: const Color(0xFF626060),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E8E8E),
                            shape: BoxShape.circle,
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
                          color: Color(0xffFEF9E6),
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xffBE8B00),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E8E8E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        doctor.fee != null
                            ? '₹${doctor.fee}'
                            : 'Fee Unavailable',
                        style: EcliniqTextStyles.titleXLarge.copyWith(
                          color: const Color(0xFF626060),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.mapPointBlack.assetPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentLocation,
                        style: EcliniqTextStyles.titleXLarge.copyWith(
                          color: const Color(0xFF626060),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffF9F9F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Color(0xffB8B8B8),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          _getDistanceText(doctor),
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xff424242),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xffF2FFF3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getTokenAvailability(doctor),
                      style: EcliniqTextStyles.bodySmallProminent.copyWith(
                        color: Colors.green[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                child: Row(
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
                        child: Center(
                          child: Text(
                            _getAvailabilityStatus(doctor),
                            textAlign: TextAlign.center,
                            style: EcliniqTextStyles.titleXLarge.copyWith(
                              color: Color(0xff3EAF3F),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
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
                                hospitalId: doctor.hospitals.isNotEmpty
                                    ? doctor.hospitals.first.id
                                    : '',
                                doctorName: doctor.name,
                                doctorSpecialization:
                                    doctor.specialization.isNotEmpty
                                    ? doctor.specialization
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
                          child: FittedBox(
                            child: Text(
                              'Book Appointment',
                              style: EcliniqTextStyles.headlineMedium.copyWith(
                                color: Colors.white,
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
          ),
        ),
        Container(height: 1, color: Colors.grey[300]),
      ],
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _formatTimings(String? timings) {
    if (timings == null || timings.isEmpty) {
      return '10am - 9:30pm (Mon - Sat)';
    }
    return timings;
  }

  String _getDistanceText(Doctor doctor) {
    double? minDist;

    for (var h in doctor.hospitals) {
      if (h.distanceKm != null) {
        if (minDist == null || h.distanceKm! < minDist) {
          minDist = h.distanceKm;
        }
      }
    }

    for (var c in doctor.clinics) {
      final dist = c['distance'];
      if (dist is num) {
        if (minDist == null || dist.toDouble() < minDist) {
          minDist = dist.toDouble();
        }
      }
    }

    if (minDist != null) {
      return '${minDist.toStringAsFixed(1)} Km';
    }
    return 'Nearby';
  }

  String _getAvailabilityStatus(Doctor doctor) {
    if (doctor.availability == null) return 'Available';

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
        return 'Available';
    }
  }

  Color _getAvailabilityColor(Doctor doctor) {
    if (doctor.availability == null) return Colors.green[50]!;

    switch (doctor.availability!.status) {
      case 'AVAILABLE':
        return Color(0xffF2FFF3);
      case 'NEXT_DAY':
        return Color(0xffF9F9F9);
      case 'BUSY':
        return Colors.orange[50]!;
      case 'UNAVAILABLE':
        return Colors.red[50]!;
      default:
        return Colors.green[50]!;
    }
  }

  String _getTokenAvailability(Doctor doctor) {
    if (doctor.availability?.availableTokens != null) {
      final available = doctor.availability!.availableTokens!;
      return '$available Tokens Available';
    }
    return 'Tokens Available';
  }
}

class SortByBottomSheet extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const SortByBottomSheet({super.key, required this.onChanged});

  @override
  State<SortByBottomSheet> createState() => _SortByBottomSheetState();
}

class _SortByBottomSheetState extends State<SortByBottomSheet> {
  String? selectedSortOption;

  final List<String> sortOptions = [
    'Relevance',
    'Price: Low - High',
    // 'Price: High - Low',
    'Experience - Most Experience first',
    'Distance - Nearest First',
    // 'Order A-Z',
    // 'Order Z-A',
    'Rating High - low',
    //'Rating Low - High',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.40,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sort By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // List of sort options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortOptions.length,
              itemBuilder: (context, index) {
                final option = sortOptions[index];
                final isSelected = selectedSortOption == option;
                return _buildSortOption(option, isSelected);
              },
            ),
          ),

          // Apply button
        ],
      ),
    );
  }

  Widget _buildSortOption(String option, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedSortOption = option;
        });
        widget.onChanged(option);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xff2372EC) : Color(0xff8E8E8E),
                  width: 1,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff2372EC),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xff424242),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
