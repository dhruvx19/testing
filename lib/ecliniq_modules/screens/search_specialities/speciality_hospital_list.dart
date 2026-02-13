import 'dart:async';
import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_api/hospital_service.dart';
import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/location_search.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/hospital_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/widgets/hospital_filter.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/widgets/hospital_filter_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/sort_by_filter_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/horizontal_divider.dart';
import 'package:ecliniq/ecliniq_utils/phone_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:ecliniq/ecliniq_utils/speech_helper.dart';

class SpecialityHospitalList extends StatefulWidget {
  final String? initialSpeciality;

  const SpecialityHospitalList({super.key, this.initialSpeciality});

  @override
  State<SpecialityHospitalList> createState() => _SpecialityHospitalListState();
}

class _SpecialityHospitalListState extends State<SpecialityHospitalList> {
  final HospitalService _hospitalService = HospitalService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  final SpeechHelper _speechHelper = SpeechHelper();

  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _currentLocation = 'Vishnu Dev Nagar, Wakad';
  String? _selectedSortOption;
  HospitalFilterParams? _filterParams;
  Map<String, dynamic>? _activeFilters;

  double _latitude = 12.9173;
  double _longitude = 77.6377;
  bool get _isListening => _speechHelper.isListening;

  List<String> _categories = [
    'All',
    'Cardiology',
    'Dentistry',
    'Dermatology',
    'ENT',
    'General Physician',
    'Gynaecology',
    'Neurology',
    'Ophthalmology',
    'Orthopedics',
    'Paediatrics',
    'Psychiatry',
  ];

  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();

    for (var category in _categories) {
      _categoryKeys[category] = GlobalKey();
    }

    if (widget.initialSpeciality != null) {
      _selectedCategory = widget.initialSpeciality!;

      if (!_categories.contains(widget.initialSpeciality)) {
        _categories.insert(1, widget.initialSpeciality!);
        _categoryKeys[widget.initialSpeciality!] = GlobalKey();
      }
    }

    _loadLocationAndFetch();
    _searchController.addListener(_onSearchChanged);
    _initSpeech();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCategory(_selectedCategory);
    });
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
    developer.log(
      'Speech result: ${result.recognizedWords}, final: ${result.finalResult}',
    );

    _searchController.text = result.recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: result.recognizedWords.length),
    );

    setState(() {
      _searchQuery = result.recognizedWords;
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

  Future<void> _loadLocationAndFetch() async {
    // Check if location is already stored
    final storedLocation = await LocationStorageService.getStoredLocation();

    if (storedLocation != null) {
      // Use stored location
      setState(() {
        _latitude = storedLocation['latitude'] ?? 12.9173;
        _longitude = storedLocation['longitude'] ?? 77.6377;
        _currentLocation = storedLocation['locationName'] ?? 'Current Location';
      });
    } else {
      // Use default location
      setState(() {
        _latitude = 12.9173;
        _longitude = 77.6377;
        _currentLocation = 'Current Location';
      });
    }

    _fetchHospitals();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _categoryScrollController.dispose();
    _speechHelper.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _hasActiveFilters()) {
        _fetchFilteredHospitals();
      }
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
    });
    _scrollToCategory(category);
  }

  void _openSort() {
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
  }

  void _openFilter() {
    EcliniqBottomSheet.show(
      context: context,
      borderRadius: 16,
      backgroundColor: Colors.white,
      child: HospitalFilterBottomSheet(
        initialFilters: _activeFilters,
        onFilterChanged: (params) {
          setState(() {
            if (!_hasActiveFiltersInParams(params)) {
              _activeFilters = null;
            } else {
              _activeFilters = params;
            }
          });
          if (_activeFilters == null) {
            _fetchHospitals();
          } else {
            _applyFilters();
          }
        },
      ),
    );
  }

  bool _hasActiveFiltersInParams(Map<String, dynamic> params) {
    return (params['specialities'] as List?)?.isNotEmpty == true ||
        params['availability'] != null ||
        params['gender'] != null ||
        params['experience'] != null ||
        (params['distance'] != null && (params['distance'] as num) != 50);
  }

  void _applySort() {
    if (_hospitals.isEmpty) return;

    // If no sort option selected, sort alphabetically by default
    if (_selectedSortOption == null) {
      setState(() {
        _hospitals.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      });
      return;
    }

    final option = _selectedSortOption!;

    int safeCompare<T extends Comparable>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    setState(() {
      switch (option) {
        case 'Distance - Nearest First':
          _hospitals.sort((a, b) => safeCompare(a.distance, b.distance));
          break;
        case 'Order A-Z':
          _hospitals.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case 'Order Z-A':
          _hospitals.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
        case 'Relevance':
        default:
          break;
      }
    });
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_activeFilters != null && _hasActiveFilters()) {
        await _fetchFilteredHospitals();
      } else {
        final response = await _hospitalService.getAllHospitals(
          latitude: _latitude,
          longitude: _longitude,
        );

        if (response.success && mounted) {
          // Sort hospitals alphabetically by name
          response.data.sort((a, b) => a.name.compareTo(b.name));

          setState(() {
            _hospitals = response.data;
            _isLoading = false;
          });
          _applySort();
        } else {
          // Check if it's a 404 or "no hospitals found" error
          final is404Error =
              response.message?.contains('No hospitals found') == true ||
              response.message?.contains('within the specified radius') ==
                  true ||
              (response.meta != null && response.meta['statusCode'] == 404);

          if (is404Error) {
            // Show empty state immediately
            if (mounted) {
              setState(() {
                _hospitals = [];
                _errorMessage = null;
                _isLoading = false;
              });
            }

            // Try fallback in background if using custom location
            final isUsingCustomLocation =
                _latitude != 12.9173 || _longitude != 77.6377;

            if (isUsingCustomLocation && mounted) {
              // Fetch with default location in background
              _fetchHospitalsWithDefaultLocation();
            }
          } else {
            // Show empty state for other errors too (don't show error message)
            if (mounted) {
              setState(() {
                _hospitals = [];
                _errorMessage = null;
                _isLoading = false;
              });
            }
          }
        }
      }
    } catch (e) {
      // Show empty state instead of error
      if (mounted) {
        setState(() {
          _hospitals = [];
          _errorMessage = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchHospitalsWithDefaultLocation() async {
    try {
      final fallbackResponse = await _hospitalService.getAllHospitals(
        latitude: 12.9173,
        longitude: 77.6377,
      );

      if (fallbackResponse.success && mounted) {
        fallbackResponse.data.sort((a, b) => a.name.compareTo(b.name));

        setState(() {
          _hospitals = fallbackResponse.data;
        });
        _applySort();
      }
    } catch (e) {
      // Silently fail - empty state is already shown
    }
  }

  Future<void> _fetchFilteredHospitals() async {
    try {
      List<String>? specialities;
      if (_activeFilters?['specialities'] != null) {
        final specialitiesList = _activeFilters!['specialities'] as List;
        if (specialitiesList.isNotEmpty) {
          specialities = specialitiesList.cast<String>();
        }
      }

      String? workExperience;
      if (_activeFilters?['experience'] != null) {
        final exp = _activeFilters!['experience'] as String;
        if (exp == '0 - 5 Years') {
          workExperience = '0-5';
        } else if (exp == '6 - 10 Years') {
          workExperience = '5-10';
        } else if (exp == '10+ Years') {
          workExperience = '10+';
        }
      }

      String? availability;
      if (_activeFilters?['availability'] != null) {
        final avail = _activeFilters!['availability'] as String;
        if (avail == 'Available Now') {
          availability = 'TODAY';
        } else if (avail == 'Today') {
          availability = 'TODAY';
        } else if (avail == 'Tomorrow') {
          availability = 'TOMORROW';
        } else if (avail == 'Anytime') {
          availability = null;
        } else {
          availability = 'TODAY';
        }
      }

      String? gender;
      if (_activeFilters?['gender'] != null) {
        final genderValue = _activeFilters!['gender'] as String;
        if (genderValue == 'Male') {
          gender = 'MALE';
        } else if (genderValue == 'Female') {
          gender = 'FEMALE';
        } else if (genderValue == 'Others') {
          gender = 'OTHERS';
        }
      }

      final response = await _hospitalService.getFilteredHospitalsTyped(
        latitude: _latitude,
        longitude: _longitude,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        distance: _activeFilters?['distance'] != null
            ? (_activeFilters!['distance'] as num).toDouble()
            : null,
        speciality: specialities,
        availability: availability,
        gender: gender,
        workExperience: workExperience,
      );

      if (response.success && response.data != null && mounted) {
        // Sort hospitals alphabetically by name
        response.data!.hospitals.sort((a, b) => a.name.compareTo(b.name));

        setState(() {
          _hospitals = response.data!.hospitals;
          _isLoading = false;
        });
        _applySort();
      } else {
        // Check if it's a 404 or "no hospitals found" error
        final is404Error =
            response.message?.contains('No hospitals found') == true ||
            response.message?.contains('within the specified radius') == true ||
            (response.meta != null && response.meta['statusCode'] == 404);

        if (is404Error) {
          // Show empty state immediately
          if (mounted) {
            setState(() {
              _hospitals = [];
              _errorMessage = null;
              _isLoading = false;
            });
          }

          // Try fallback in background if using custom location
          final isUsingCustomLocation =
              _latitude != 12.9173 || _longitude != 77.6377;

          if (isUsingCustomLocation && mounted) {
            // Fetch with default location in background
            _fetchFilteredHospitalsWithDefaultLocation(
              specialities: specialities,
              availability: availability,
              gender: gender,
              workExperience: workExperience,
            );
          }
        } else {
          // Show empty state for other errors
          if (mounted) {
            setState(() {
              _hospitals = [];
              _errorMessage = null;
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      // Show empty state instead of error
      if (mounted) {
        setState(() {
          _hospitals = [];
          _errorMessage = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFilteredHospitalsWithDefaultLocation({
    List<String>? specialities,
    String? availability,
    String? gender,
    String? workExperience,
  }) async {
    try {
      final fallbackResponse = await _hospitalService.getFilteredHospitalsTyped(
        latitude: 12.9173,
        longitude: 77.6377,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        distance: _activeFilters?['distance'] != null
            ? (_activeFilters!['distance'] as num).toDouble()
            : null,
        speciality: specialities,
        availability: availability,
        gender: gender,
        workExperience: workExperience,
      );

      if (fallbackResponse.success &&
          fallbackResponse.data != null &&
          mounted) {
        fallbackResponse.data!.hospitals.sort(
          (a, b) => a.name.compareTo(b.name),
        );

        setState(() {
          _hospitals = fallbackResponse.data!.hospitals;
        });
        _applySort();

        if (mounted && _hospitals.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Showing nearby hospitals'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Silently fail - empty state is already shown
    }
  }

  void _applyFilters() {
    _fetchFilteredHospitals();
  }

  bool _hasActiveFilters() {
    if (_activeFilters == null) return false;
    return (_activeFilters!['specialities'] as List?)?.isNotEmpty == true ||
        _activeFilters!['availability'] != null ||
        _activeFilters!['gender'] != null ||
        _activeFilters!['experience'] != null ||
        (_activeFilters!['distance'] != null &&
            (_activeFilters!['distance'] as num) > 0);
  }

  bool _hasActiveSort() {
    return _selectedSortOption != null && _selectedSortOption != 'Relevance';
  }

  List<Hospital> get _filteredHospitals {
    List<Hospital> filtered = _hospitals;

    if (_selectedCategory != 'All' && !_hasActiveFilters()) {
      filtered = filtered.where((hospital) {
        final type = hospital.type.toLowerCase();
        final category = _selectedCategory.toLowerCase();
        return type.contains(category) || category.contains(type);
      }).toList();
    }

    if (_searchQuery.isNotEmpty && !_hasActiveFilters()) {
      filtered = filtered.where((hospital) {
        final name = hospital.name.toLowerCase();
        final city = hospital.city.toLowerCase();
        return name.contains(_searchQuery.toLowerCase()) ||
            city.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 58,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Hospital',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: const Color(0xff424242)),
          ),
        ),
        actions: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _openSort,
                    icon: SvgPicture.asset(
                      EcliniqIcons.sortAlt.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        32,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        32,
                      ),
                    ),
                  ),
                  if (_hasActiveSort())
                    Positioned(
                      right: 4,
                      top: 3,
                      child: Container(
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          10,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          10,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 1.5),
              ),
              VerticalDivider(
                color: Color(0xffD6D6D6),
                thickness: 1,
                width: 0.5,
                indent: 18,
                endIndent: 18,
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 1.5),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _openFilter,
                    icon: SvgPicture.asset(
                      EcliniqIcons.filter.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        32,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        32,
                      ),
                    ),
                  ),
                  if (_hasActiveFilters())
                    Positioned(
                      right: 4,
                      top: 3,
                      child: Container(
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          10,
                        ),
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          10,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),
            ],
          ),
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
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
            ),
            _buildLocationSection(),
            _buildSearchBar(),
            _buildCategoryFilters(),
            Expanded(child: _buildHospitalList()),
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
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 16,
          vertical: 8,
        ),
        color: Colors.white,
        child: Row(
          children: [
            SvgPicture.asset(
              EcliniqIcons.mapPointBlue.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
            Text(
              _currentLocation,
              style: EcliniqTextStyles.responsiveHeadlineXMedium(
                context,
              ).copyWith(color: const Color(0xff424242)),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 10),
            ),
            Container(
              height: EcliniqTextStyles.getResponsiveHeight(context, 20),
              width: 0.5,
              color: Color(0xffD6D6D6),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
            ),
            SvgPicture.asset(
              EcliniqIcons.arrowDown.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 20),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 14,
        vertical: 8,
      ),
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 48.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
        ),
        border: Border.all(color: Color(0xFF626060), width: 0.5),
      ),
      child: Row(
        children: [
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 12,
              right: 8,
              top: 0,
              bottom: 0,
            ),
            child: SvgPicture.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Color(0xFF424242), fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'Search Hospital',
                hintStyle: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                    .copyWith(
                      color: Color(0xFF8E8E8E),

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
            onTap: _toggleVoiceSearch,
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: 12,
                top: 0,
                bottom: 0,
                left: 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),

                child: SvgPicture.asset(
                  EcliniqIcons.microphone.assetPath,
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                  colorFilter: _isListening
                      ? const ColorFilter.mode(
                          Color(0xFF2372EC),
                          BlendMode.srcIn,
                        )
                      : null,
                ),
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
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 16,
            vertical: 0,
          ),
          child: Row(
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                key: _categoryKeys[category],
                onTap: () => _onCategorySelected(category),
                child: Padding(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                    context,
                    right: 24,
                    top: 0,
                    bottom: 0,
                    left: 0,
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding:
                              EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                context,
                                horizontal: 0,
                                vertical: 12,
                              ),
                          child: Text(
                            category,
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
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

  Widget _buildHospitalList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    final hospitals = _filteredHospitals;

    if (hospitals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.noHospital.assetPath,
                width: EcliniqTextStyles.getResponsiveWidth(context, 200),
                height: EcliniqTextStyles.getResponsiveHeight(context, 200),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
              ),
              Text(
                'No Hospitals Found',
                style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                    .copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),
              Text(
                _hasActiveFilters() || _hasActiveSort()
                    ? 'Try adjusting your filters or search criteria'
                    : 'No hospitals available in this location',
                style: EcliniqTextStyles.responsiveBodyMedium(
                  context,
                ).copyWith(color: Color(0xff626060)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16,
        vertical: 12,
      ),
      itemCount: hospitals.length,
      itemBuilder: (context, index) {
        return _buildHospitalCard(hospitals[index]);
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16,
        vertical: 12,
      ),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildShimmerCard();
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        bottom: 16,
        top: 0,
        left: 0,
        right: 0,
      ),
      decoration: BoxDecoration(color: Colors.white),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(
              height: EcliniqTextStyles.getResponsiveHeight(context, 120),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                  ),
                ),
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: 12.0,
                bottom: 12.0,
                top: 28.0,
                left: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: EcliniqTextStyles.getResponsiveHeight(context, 20),
                    width: EcliniqTextStyles.getResponsiveWidth(context, 200),
                    color: Colors.white,
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),
                  Container(
                    height: EcliniqTextStyles.getResponsiveHeight(context, 16),
                    width: EcliniqTextStyles.getResponsiveWidth(context, 150),
                    color: Colors.white,
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),
                  Container(
                    height: EcliniqTextStyles.getResponsiveHeight(context, 16),
                    width: EcliniqTextStyles.getResponsiveWidth(context, 100),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return GestureDetector(
      onTap: () {
        // Navigate to hospital details
        EcliniqRouter.push(HospitalDetailScreen(hospitalId: hospital.id));
      },
      child: Container(
        margin: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
          context,
          bottom: 16,
          top: 0,
          left: 0,
          right: 0,
        ),
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: EcliniqTextStyles.getResponsiveHeight(context, 120),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          12,
                        ),
                      ),
                    ),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          12,
                        ),
                      ),
                    ),
                    child: FutureBuilder<String?>(
                      future: hospital.getImageUrl(_storageService),
                      builder: (context, snapshot) {
                        final imageUrl = snapshot.data;
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          return Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          );
                        }
                        return _buildImagePlaceholder();
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Container(
                        padding:
                            EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                              context,
                              horizontal: 8,
                              vertical: 4,
                            ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF9E6),
                          borderRadius: BorderRadius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              4,
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
                                18,
                              ),
                              height: EcliniqTextStyles.getResponsiveIconSize(
                                context,
                                18,
                              ),
                            ),
                            SizedBox(
                              width: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                2,
                              ),
                            ),
                            Text(
                              '4.0',
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
                ),
                Positioned(
                  top: EcliniqTextStyles.getResponsiveHeight(context, 60),
                  child: Container(
                    width: EcliniqTextStyles.getResponsiveWidth(context, 80),
                    height: EcliniqTextStyles.getResponsiveHeight(context, 80),
                    decoration: BoxDecoration(
                      color: Color(0xffF8FAFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xff96BFFF), width: 0.5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: FutureBuilder<String?>(
                            future: hospital.getLogoUrl(_storageService),
                            builder: (context, snapshot) {
                              final logoUrl = snapshot.data;
                              if (logoUrl != null && logoUrl.isNotEmpty) {
                                return ClipOval(
                                  child: Image.network(
                                    logoUrl,
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
                                        hospital.name.isNotEmpty
                                            ? hospital.name.substring(0, 1)
                                            : 'H',
                                        style:
                                            EcliniqTextStyles.responsiveHeadlineXXXLarge(
                                              context,
                                            ).copyWith(
                                              color: Colors.blue.shade700,
                                            ),
                                      );
                                    },
                                  ),
                                );
                              }
                              return Text(
                                hospital.name.isNotEmpty
                                    ? hospital.name.substring(0, 1)
                                    : 'H',
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
                ),
              ],
            ),
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: 12.0,
                bottom: 12.0,
                top: 28.0,
                left: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hospital.name,
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),
                  Text(
                    '${hospital.type} | ${hospital.numberOfDoctors}+ Doctors',
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w400,
                          color: Color(0xff424242),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.mapPointHospital.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24,
                        ),
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          4,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${hospital.city}, ${hospital.state}',
                                style:
                                    EcliniqTextStyles.responsiveTitleXLarge(
                                      context,
                                    ).copyWith(
                                      color: Color(0xff424242),
                                      fontWeight: FontWeight.w400,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: EcliniqTextStyles.getResponsiveSpacing(
                                context,
                                8,
                              ),
                            ),
                            Container(
                              padding:
                                  EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                    context,
                                    horizontal: 6,
                                    vertical: 2.5,
                                  ),
                              decoration: BoxDecoration(
                                color: const Color(0xffF9F9F9),
                                borderRadius: BorderRadius.circular(
                                  EcliniqTextStyles.getResponsiveBorderRadius(
                                    context,
                                    4,
                                  ),
                                ),
                                border: Border.all(
                                  color: const Color(0xffB8B8B8),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                hospital.distance > 0
                                    ? '${(hospital.distance / 1000).toStringAsFixed(1)} Km'
                                    : 'Nearby',
                                style:
                                    EcliniqTextStyles.responsiveBodySmall(
                                      context,
                                    ).copyWith(
                                      color: Color(0xff424242),
                                      fontWeight: FontWeight.w400,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.clockCircleHospital.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          24,
                        ),
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          4,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'OPD: 10:00 AM - 2:00 PM , 4:00 PM - 6:00 PM',
                          style:
                              EcliniqTextStyles.responsiveTitleXLarge(
                                context,
                              ).copyWith(
                                color: Color(0xff424242),
                                fontWeight: FontWeight.w400,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              EcliniqTextStyles.getResponsiveBorderRadius(
                                context,
                                4,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x4D2372EC),
                                offset: Offset(2, 2),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          height: EcliniqTextStyles.getResponsiveButtonHeight(
                            context,
                            baseHeight: 52.0,
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              EcliniqRouter.push(
                                HospitalDetailScreen(
                                  hospitalId: hospital.id,
                                  initialTabIndex: 1, // Open Doctors tab
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2372EC),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  EcliniqTextStyles.getResponsiveBorderRadius(
                                    context,
                                    4,
                                  ),
                                ),
                              ),
                              elevation: 0,
                              padding:
                                  EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                    context,
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'View All Doctors',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineBMedium(
                                        context,
                                      ).copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  maxLines: 1,
                                ),
                                SizedBox(
                                  width: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    2,
                                  ),
                                ),
                                SvgPicture.asset(
                                  EcliniqIcons.arrowRight.assetPath,
                                  width:
                                      EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        24,
                                      ),
                                  height:
                                      EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        24,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          22,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => PhoneLauncher.launchPhoneCall(null),
                        child: SvgPicture.asset(
                          EcliniqIcons.phone.assetPath,
                          width: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            32,
                          ),
                          height: EcliniqTextStyles.getResponsiveIconSize(
                            context,
                            32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 6),
            ),
            HorizontalDivider(color: Color(0xffD6D6D6)),
          ],
        ),
      ),
    );
  }

  bool _isValidImageUrl(String url) {
    if (url.startsWith('file://') || url.startsWith('/hospitals/')) {
      return false;
    }
    return url.startsWith('http://') || url.startsWith('https://');
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade100, Colors.blue.shade50],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital,
          size: EcliniqTextStyles.getResponsiveIconSize(context, 40),
          color: Colors.blue.shade300,
        ),
      ),
    );
  }
}
