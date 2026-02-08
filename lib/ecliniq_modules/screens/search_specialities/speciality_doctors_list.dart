import 'dart:async';
import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart' as api_doctor;
import 'package:ecliniq/ecliniq_api/models/hospital_doctor_model.dart';
import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/location_search.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/doctor_details.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpecialityDoctorsList extends StatefulWidget {
  final String? initialSpeciality;

  const SpecialityDoctorsList({super.key, this.initialSpeciality});

  @override
  State<SpecialityDoctorsList> createState() => _SpecialityDoctorsListState();
}

class _SpecialityDoctorsListState extends State<SpecialityDoctorsList> {
  final DoctorService _doctorService = DoctorService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  final SpeechToText _speechToText = SpeechToText();

  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _currentLocation = 'Vishnu Dev Nagar, Wakad';
  Timer? _debounceTimer;
  String? _selectedSortOption;
  Map<String, dynamic> _filterParams = {};

  double _latitude = 12.9173;
  double _longitude = 77.6377;
  bool _speechEnabled = false;
  bool _isListening = false;

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
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
          final errorMsg = error.errorMsg.toLowerCase();
          if (!errorMsg.contains('no_match') &&
              !errorMsg.contains('listen_failed')) {
            developer.log(
              'Speech recognition initialization error: ${error.errorMsg}',
            );
          }
        },
        onStatus: (status) {
          developer.log('Speech recognition status: $status');
          if (mounted) {
            if (status == 'notListening' ||
                status == 'done' ||
                status == 'doneNoResult') {
              setState(() => _isListening = false);
            } else if (status == 'listening') {
              setState(() => _isListening = true);
            }
          }
        },
      );
      if (mounted) {
        setState(() {});
      }
      developer.log('Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      developer.log('Error initializing speech recognition: $e');
      _speechEnabled = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startListening() async {
    if (_isListening) {
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition is not available. Please check your permissions.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    final isAvailable = await _speechToText.initialize(
      onError: (error) {
        developer.log('Speech recognition error: ${error.errorMsg}');
        final errorMsg = error.errorMsg.toLowerCase();
        if (errorMsg.contains('no_match') ||
            errorMsg.contains('listen_failed') ||
            errorMsg.contains('error_network_error')) {
          developer.log('Expected speech recognition error: ${error.errorMsg}');
          if (mounted) {
            setState(() => _isListening = false);
          }
          return;
        }

        if (mounted) {
          setState(() => _isListening = false);
          if (errorMsg.contains('error_permission') ||
              errorMsg.contains('permission')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Microphone permission is required for voice search.',
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: ${error.errorMsg}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onStatus: (status) {
        developer.log('Speech recognition status: $status');
        if (mounted) {
          if (status == 'notListening' ||
              status == 'done' ||
              status == 'doneNoResult') {
            setState(() => _isListening = false);
          } else if (status == 'listening') {
            setState(() => _isListening = true);
          }
        }
      },
    );

    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available. Please check your permissions.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    } catch (e) {
      developer.log('Error starting speech recognition: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting voice search: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      developer.log('Speech recognition stopped');
    } catch (e) {
      developer.log('Error stopping speech recognition: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
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
      _searchQuery = result.recognizedWords.toLowerCase();
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
    setState(() {
      _latitude = 12.9173;
      _longitude = 77.6377;
      _currentLocation = 'Current Location';
    });
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _categoryScrollController.dispose();
    _debounceTimer?.cancel();
    _speechToText.cancel();
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

      child: DoctorFilterBottomSheet(
        initialFilters: _filterParams.isNotEmpty ? _filterParams : null,
        onFilterChanged: (params) {
          setState(() {
            if (!_hasActiveFiltersInParams(params)) {
              _filterParams = {};

              _fetchDoctorsInitial();
            } else {
              _filterParams = params;

              _fetchDoctors();
            }
          });
        },
      ),
    );
  }

  Future<void> _fetchDoctorsInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<String>? specialityFilter;
      if (_selectedCategory != 'All') {
        specialityFilter = [_selectedCategory];
      }

      final request = api_doctor.FilterDoctorsRequest(
        latitude: 12.9173,
        longitude: 77.6377,
        speciality: specialityFilter,
        gender: null,
        distance: null,
        workExperience: null,
        availability: null,
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

        // Sort doctors alphabetically by name
        convertedDoctors.sort((a, b) => a.name.compareTo(b.name));
        
        if (mounted) {
          setState(() {
            _doctors = convertedDoctors;
            _isLoading = false;
          });
          _applySort();
        }
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

  bool _hasActiveFiltersInParams(Map<String, dynamic> params) {
    return (params['specialities'] as List?)?.isNotEmpty == true ||
        params['availability'] != null ||
        params['gender'] != null ||
        params['experience'] != null ||
        (params['distance'] != null && (params['distance'] as num) != 50);
  }

  bool _hasActiveFilters() {
    if (_filterParams.isEmpty) return false;
    return _hasActiveFiltersInParams(_filterParams);
  }

  void _applySort() {
    if (_doctors.isEmpty) return;

    // If no sort option selected, sort alphabetically by default
    if (_selectedSortOption == null) {
      setState(() {
        _doctors.sort((a, b) => a.name.compareTo(b.name));
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
          _doctors.sort((a, b) {
            double scoreA = _computeRelevanceScore(a);
            double scoreB = _computeRelevanceScore(b);
            return scoreB.compareTo(scoreA);
          });
          break;
        default:
          break;
      }
    });
  }

  double _computeRelevanceScore(Doctor doctor) {
    double score = 0;

    // Rating contributes up to 30 points (rating is typically 0-5)
    if (doctor.rating != null) {
      score += (doctor.rating! / 5.0) * 30;
    }

    // Distance contributes up to 40 points (closer is better)
    double? minDist;
    for (final h in doctor.hospitals) {
      if (h.distanceKm != null) {
        if (minDist == null || h.distanceKm! < minDist) {
          minDist = h.distanceKm;
        }
      }
    }
    for (final c in doctor.clinics) {
      final dist = c['distance'];
      if (dist is num) {
        if (minDist == null || dist.toDouble() < minDist) {
          minDist = dist.toDouble();
        }
      }
    }
    if (minDist != null) {
      // Cap at 50 km; closer doctors score higher
      score += (1 - (minDist.clamp(0, 50) / 50)) * 40;
    }

    // Experience contributes up to 30 points (more is better, cap at 30 years)
    if (doctor.experience != null) {
      score += (doctor.experience!.clamp(0, 30) / 30) * 30;
    }

    return score;
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<String>? specialityFilter;

      if (_filterParams['specialities'] != null &&
          (_filterParams['specialities'] as List).isNotEmpty) {
        specialityFilter = (_filterParams['specialities'] as List)
            .cast<String>();
      } else if (_selectedCategory != 'All') {
        specialityFilter = [_selectedCategory];
      }

      final request = api_doctor.FilterDoctorsRequest(
        latitude: 12.9173,
        longitude: 77.6377,
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

        // Sort doctors alphabetically by name
        convertedDoctors.sort((a, b) => a.name.compareTo(b.name));
        
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
        leadingWidth: 56,
        titleSpacing: 0,
        toolbarHeight: 42,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Doctors',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        actions: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
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
                  if (_selectedSortOption != null)
                    Positioned(
                      right: 4,
                      top: 3,
                      child: Container(
                        width: 10,
                        height: 10,
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
                indent: 10,
                endIndent: 10,
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 1.5),
              ),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
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
                        width: 10,
                        height: 10,
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
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 16,
          vertical: 4,
        ),
        color: Colors.white,
        child: Row(
          children: [
            SvgPicture.asset(
              EcliniqIcons.mapPointBlue.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 6)),
            Text(
              _currentLocation,
              style: EcliniqTextStyles.responsiveHeadlineXMedium(
                context,
              ).copyWith(color: Color(0xff424242), fontWeight: FontWeight.w400),
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
                hintText: 'Search Doctor',
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
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                  context,
                  4,
                ),

                child: SvgPicture.asset(
                  EcliniqIcons.microphone.assetPath,
                  width: 32,
                  height: 32,
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

  Widget _buildDoctorList() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    final doctors = _filteredDoctors;

    if (doctors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                EcliniqIcons.noDoctor.assetPath,
                width: EcliniqTextStyles.getResponsiveWidth(context, 200),
                height: EcliniqTextStyles.getResponsiveHeight(context, 200),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
              ),
              Text(
                'No Doctors Found',
                style: EcliniqTextStyles.responsiveHeadlineMedium(
                  context,
                ).copyWith(
                  color: Color(0xff424242),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
              ),
              Text(
                _hasActiveFiltersInParams(_filterParams) || _selectedCategory != 'All'
                    ? 'Try adjusting your filters or search criteria'
                    : 'No doctors available in this location',
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
        GestureDetector(
          onTap: () {
            // Navigate to doctor details
            EcliniqRouter.push(
              DoctorDetailScreen(doctorId: doctor.id),
            );
          },
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
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
                            future: _getDoctorProfilePhotoUrl(doctor),
                            builder: (context, snapshot) {
                              final imageUrl = snapshot.data;
                              if (imageUrl != null && imageUrl.isNotEmpty) {
                                return ClipOval(
                                  child: Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
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
                      mainAxisAlignment: doctor.qualifications.isEmpty 
                          ? MainAxisAlignment.center 
                          : MainAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor.name}',
                          style: EcliniqTextStyles.responsiveHeadlineLarge(
                            context,
                          ).copyWith(color: const Color(0xFF424242)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doctor.specialization.isNotEmpty
                              ? doctor.specialization
                              : 'General',
                          style: EcliniqTextStyles.responsiveTitleXLarge(
                            context,
                          ).copyWith(color: const Color(0xFF424242)),
                        ),
                        if (doctor.qualifications.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            doctor.qualifications,
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
                        const SizedBox(width: 8),
                        Text(
                          '${doctor.experience}yrs of exp',
                          style: EcliniqTextStyles.responsiveTitleXLarge(
                            context,
                          ).copyWith(color: const Color(0xFF626060)),
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
                        doctor.fee != null ? '₹${doctor.fee}' : 'N.A.',
                        style: EcliniqTextStyles.responsiveTitleXLarge(
                          context,
                        ).copyWith(color: const Color(0xFF626060)),
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
                      const SizedBox(width: 8),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.mapPointBlack.assetPath,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getHospitalLocation(doctor),
                          style: EcliniqTextStyles.responsiveTitleXLarge(
                            context,
                          ).copyWith(color: const Color(0xFF626060)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_getDistanceText(doctor) != 'Nearby') ...[
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
                            style:
                                EcliniqTextStyles.responsiveTitleXLarge(
                                  context,
                                ).copyWith(
                                  color: Color(0xff424242),
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Color(0xffF2FFF3),
                      borderRadius: BorderRadius.circular(6),
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
              const SizedBox(height: 12),
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
                        color: Color(0xffF2FFF3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          _getAvailabilityStatus(doctor),
                          textAlign: TextAlign.center,
                          style: EcliniqTextStyles.responsiveTitleXLarge(
                            context,
                          ).copyWith(color: Color(0xff3EAF3F)),
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
                            style: EcliniqTextStyles.responsiveHeadlineMedium(
                              context,
                            ).copyWith(color: Colors.white),
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

  Future<String?> _getDoctorProfilePhotoUrl(Doctor doctor) async {
    if (doctor.profilePhoto == null || doctor.profilePhoto!.isEmpty) {
      return null;
    }

    if (doctor.profilePhoto!.startsWith('http://') ||
        doctor.profilePhoto!.startsWith('https://')) {
      return doctor.profilePhoto;
    }

    if (doctor.profilePhoto!.startsWith('public/')) {
      return await _storageService.getPublicUrl(doctor.profilePhoto);
    }
    return null;
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

  String _getHospitalLocation(Doctor doctor) {
    // Get the nearest hospital's location
    if (doctor.hospitals.isNotEmpty) {
      final hospital = doctor.hospitals.first;
      final parts = <String>[];
      
      if (hospital.city != null && hospital.city!.isNotEmpty) {
        parts.add(hospital.city!);
      }
      
      if (hospital.state != null && hospital.state!.isNotEmpty) {
        parts.add(hospital.state!);
      }
      
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }
    
    // Fallback to current location if no hospital location available
    return _currentLocation;
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
  final String? initialSortOption;

  const SortByBottomSheet({
    super.key,
    required this.onChanged,
    this.initialSortOption,
  });

  @override
  State<SortByBottomSheet> createState() => _SortByBottomSheetState();
}

class _SortByBottomSheetState extends State<SortByBottomSheet> {
  late String? selectedSortOption;

  @override
  void initState() {
    super.initState();
    selectedSortOption = widget.initialSortOption;
  }

  void _resetSort() {
    setState(() {
      selectedSortOption = null;
    });

    widget.onChanged('');
  }

  final List<String> sortOptions = [
    'Relevance',
    'Price: Low - High',

    'Experience - Most Experience first',
    'Distance - Nearest First',

    'Rating High - low',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
          topRight: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
          bottomLeft: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
          bottomRight: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 16,
              right: 16,
              top: 22,
              bottom: 0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort By',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: Color(0xff424242),
                        ),
                  ),
                  GestureDetector(
                    onTap: _resetSort,
                    child: Text(
                      'Clear',
                      style:
                          EcliniqTextStyles.responsiveHeadlineBMedium(
                            context,
                          ).copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff2372EC),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                left: 16,
                right: 16,
                top: 0,
                bottom: 0,
              ),
              itemCount: sortOptions.length,
              itemBuilder: (context, index) {
                final option = sortOptions[index];
                final isSelected = selectedSortOption == option;
                return _buildSortOption(option, isSelected);
              },
            ),
          ),
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
        padding: EdgeInsets.only(
          top: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          bottom: EcliniqTextStyles.getResponsiveSpacing(context, 4),
        ),
        child: Row(
          children: [
            Container(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
              width: EcliniqTextStyles.getResponsiveSpacing(context, 24),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF8E8E8E),
                  width: 1,
                ),
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2563EB) : Colors.white,
              ),
              child: isSelected
                  ? Container(
                      margin: EdgeInsets.all(
                        EcliniqTextStyles.getResponsiveSpacing(context, 5),
                      ),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 10),
            ),
            Expanded(
              child: Text(
                option,
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                    .copyWith(
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
