import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_core/location/location_permission_manager.dart';
import 'package:ecliniq/ecliniq_core/location/location_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/search_bar.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/login/profile_help.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final LocationPermissionManager _permissionManager =
      LocationPermissionManager();
  final SpeechToText _speechToText = SpeechToText();

  List<String> _filteredCities = [];
  bool _isSearching = false;
  bool _speechEnabled = false;
  bool _isListening = false;

  final List<String> _popularCities = [
    'Delhi',
    'Bengaluru',
    'Chennai',
    'Kolkata',
    'Hyderabad',
    'Pune',
    'Mumbai',
  ];

  final List<String> _otherCities = [
    'Akola',
    'Amravati',
    'Akot',
    'Amritsar',
    'Ahmedabad',
    'Agra',
    'Allahabad',
    'Aurangabad',
    'Bhopal',
    'Chandigarh',
    'Coimbatore',
    'Dehradun',
    'Faridabad',
    'Ghaziabad',
    'Goa',
    'Gurgaon',
    'Guwahati',
    'Indore',
    'Jaipur',
    'Kanpur',
    'Kochi',
    'Lucknow',
    'Ludhiana',
    'Madurai',
    'Mangalore',
    'Mysore',
    'Nagpur',
    'Nashik',
    'Noida',
    'Patna',
    'Rajkot',
    'Ranchi',
    'Surat',
    'Thane',
    'Thiruvananthapuram',
    'Vadodara',
    'Varanasi',
    'Vijayawada',
    'Visakhapatnam',
  ];

  @override
  void initState() {
    super.initState();
    _filteredCities = _otherCities;
    _searchController.addListener(_onSearchChanged);
    _initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speechToText.cancel();
    super.dispose();
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
      _stopListening();
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          CustomErrorSnackBar.show(
            context: context,
            title: 'Permission Required',
            subtitle:
                'Speech recognition is not available. Please check your permissions.',
            duration: const Duration(seconds: 3),
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
          if (mounted) {
            setState(() => _isListening = false);
          }
          return;
        }

        if (mounted) {
          setState(() => _isListening = false);
          if (errorMsg.contains('error_permission') ||
              errorMsg.contains('permission')) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            CustomErrorSnackBar.show(
              context: context,
              title: 'Permission Required',
              subtitle:
                  'Microphone permission is required for voice search.',
              duration: const Duration(seconds: 3),
            );
          }
        }
      },
      onStatus: (status) {
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        CustomErrorSnackBar.show(
          context: context,
          title: 'Permission Required',
          subtitle:
              'Speech recognition is not available. Please check your permissions.',
          duration: const Duration(seconds: 3),
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        CustomErrorSnackBar.show(
          context: context,
          title: 'Error',
          subtitle: 'Error starting voice search: ${e.toString()}',
          duration: const Duration(seconds: 3),
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
    _searchController.text = result.recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: result.recognizedWords.length),
    );

    setState(() {});

    if (result.finalResult) {
      _stopListening();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      if (_isSearching) {
        final query = _searchController.text.toLowerCase();
        _filteredCities = [
          ..._popularCities.where(
            (city) => city.toLowerCase().contains(query),
          ),
          ..._otherCities.where(
            (city) => city.toLowerCase().contains(query),
          ),
        ];
      } else {
        _filteredCities = _otherCities;
      }
    });
  }

  void _handleSearch(String query) {
    _searchController.text = query;
  }

  void _clearSearch() {
    _searchController.clear();
    if (_isListening) {
      _stopListening();
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final isGranted = await LocationPermissionManager.isPermissionGranted();
      if (isGranted) {
        final position = await _permissionManager.getCurrentLocationIfGranted();
        if (position != null) {
          await _handleLocationReceived(position);
          return;
        }
      }

      final isDeniedForever =
          await LocationPermissionManager.isPermissionDeniedForever();
      if (isDeniedForever) {
        _showSettingsDialog();
        return;
      }

      bool serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar(
          'Location services are disabled. Please enable them in settings.',
        );
        return;
      }

      final permissionStatus =
          await LocationPermissionManager.requestPermissionIfNeeded();

      if (permissionStatus == LocationPermissionStatus.granted) {
        final position = await _permissionManager.getCurrentLocationIfGranted();
        if (position != null) {
          await _handleLocationReceived(position);
        } else {
          _showErrorSnackBar(
            'Unable to get your current location. Please try again.',
          );
        }
      } else if (permissionStatus == LocationPermissionStatus.deniedForever) {
        _showSettingsDialog();
      } else {
        _showErrorSnackBar(
          'Location permission denied. Please enable location permission to continue.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error getting location: $e');
    }
  }

  Future<void> _handleLocationReceived(Position position) async {
    String? locationName;
    try {
      locationName = await _locationService.getLocationName(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      locationName = 'Current Location';
    }

    if (!mounted) return;

    await LocationStorageService.storeLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      locationName: locationName,
    );

    _updateProvidersAndNavigateBack(
      position.latitude,
      position.longitude,
      locationName!,
    );
  }

  Future<void> _selectCity(String cityName) async {
    final Map<String, Map<String, double>> cityCoordinates = {
      'Delhi': {'lat': 28.7041, 'lng': 77.1025},
      'Bengaluru': {'lat': 12.9716, 'lng': 77.5946},
      'Chennai': {'lat': 13.0827, 'lng': 80.2707},
      'Kolkata': {'lat': 22.5726, 'lng': 88.3639},
      'Hyderabad': {'lat': 17.3850, 'lng': 78.4867},
      'Pune': {'lat': 18.5204, 'lng': 73.8567},
      'Mumbai': {'lat': 19.0760, 'lng': 72.8777},
      'Ahmedabad': {'lat': 23.0225, 'lng': 72.5714},
      'Jaipur': {'lat': 26.9124, 'lng': 75.7873},
      'Surat': {'lat': 21.1702, 'lng': 72.8311},
    };

    final coords =
        cityCoordinates[cityName] ?? {'lat': 12.9716, 'lng': 77.5946};

    await LocationStorageService.storeLocation(
      latitude: coords['lat']!,
      longitude: coords['lng']!,
      locationName: cityName,
    );

    if (!mounted) return;

    _updateProvidersAndNavigateBack(coords['lat']!, coords['lng']!, cityName);
  }

  void _updateProvidersAndNavigateBack(
    double lat,
    double lng,
    String locationName,
  ) {
    final hospitalProvider = Provider.of<HospitalProvider>(
      context,
      listen: false,
    );
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);

    hospitalProvider.setLocation(
      latitude: lat,
      longitude: lng,
      locationName: locationName,
    );

    doctorProvider.setLocation(
      latitude: lat,
      longitude: lng,
      locationName: locationName,
    );

    Future.wait([
      hospitalProvider.fetchTopHospitals(
        latitude: lat,
        longitude: lng,
        isRefresh: true,
      ),
      doctorProvider.fetchTopDoctors(
        latitude: lat,
        longitude: lng,
        isRefresh: true,
      ),
    ]).catchError((e) {});

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const EcliniqText('Location Permission Required'),
        content: const EcliniqText(
          'Location permission has been permanently denied. Please enable it in app settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const EcliniqText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _locationService.openAppSettings();
              Navigator.of(context).pop();
            },
            child: const EcliniqText('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Select Location',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
      
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          SearchBarWidget(
            controller: _searchController,
            hintText: 'Search Location',
            isListening: _isListening,
            onSearch: _handleSearch,
            onClear: _clearSearch,
            onVoiceSearch: _startListening,
          ),

          // Use Current Location
          InkWell(
            onTap: _useCurrentLocation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Use my Current Location',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                    .copyWith(
                      color: const Color(0xFF2372EC),
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
          ),

          if (!_isSearching) ...[
            const SizedBox(height: 8),

            // Popular Cities
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Popular Cities',
                style: EcliniqTextStyles.responsiveHeadlineLargeBold(context)
                    .copyWith(
                      color: const Color(0xFF424242),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(height: 8),

            // Popular Cities List
            ..._popularCities.map(
              (city) => InkWell(
                onTap: () => _selectCity(city),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    city,
                    style: EcliniqTextStyles.responsiveHeadlineZMedium(context)
                        .copyWith(
                          color: const Color(0xFF424242),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Other Cities
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Other Cities',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                    .copyWith(
                      color: const Color(0xFF424242),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            const SizedBox(height: 8),
          ],

          // Cities List (Scrollable) - shows filtered results when searching
          Expanded(
            child: ListView.builder(
              itemCount: _isSearching ? _filteredCities.length : _otherCities.length,
              itemBuilder: (context, index) {
                final city = _isSearching ? _filteredCities[index] : _otherCities[index];
                return InkWell(
                  onTap: () => _selectCity(city),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Text(
                      city,
                      style:
                          EcliniqTextStyles.responsiveHeadlineZMedium(
                            context,
                          ).copyWith(
                            color: const Color(0xFF424242),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
