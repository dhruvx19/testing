
import 'package:ecliniq/ecliniq_core/location/location_permission_manager.dart';
import 'package:ecliniq/ecliniq_core/location/location_service.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/search_bar.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:ecliniq/ecliniq_utils/speech_helper.dart';

class ManualLocationPage extends StatefulWidget {
  const ManualLocationPage({super.key});

  @override
  State<ManualLocationPage> createState() => _ManualLocationPageState();
}

class _ManualLocationPageState extends State<ManualLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final LocationPermissionManager _permissionManager =
      LocationPermissionManager();
  final SpeechHelper _speechHelper = SpeechHelper();

  List<String> _filteredCities = [];
  bool _isSearching = false;
  bool get _isListening => _speechHelper.isListening;

  final List<String> _popularCities = [
    'Delhi',
    'Bengaluru',
    'Chennai',
    'Kolkata',
    'Hyderabad',
    'Pune',
    'Mumbai',
    'Ahmedabad',
    'Jaipur',
    'Surat',
  ];

  final List<String> _otherCities = [
    'Agra',
    'Ajmer',
    'Akola',
    'Aligarh',
    'Allahabad',
    'Alwar',
    'Amravati',
    'Amritsar',
    'Asansol',
    'Aurangabad',
    'Bareilly',
    'Belgaum',
    'Bhavnagar',
    'Bhilai',
    'Bhilwara',
    'Bhopal',
    'Bhubaneswar',
    'Bhiwandi',
    'Bikaner',
    'Bilaspur',
    'Bokaro Steel City',
    'Chandigarh',
    'Coimbatore',
    'Cuttack',
    'Dehradun',
    'Dhanbad',
    'Durgapur',
    'Erode',
    'Faridabad',
    'Firozabad',
    'Gaya',
    'Ghaziabad',
    'Goa',
    'Gorakhpur',
    'Gulbarga',
    'Guntur',
    'Gurgaon',
    'Guwahati',
    'Gwalior',
    'Hubli-Dharwad',
    'Indore',
    'Jabalpur',
    'Jalandhar',
    'Jalgaon',
    'Jammu',
    'Jamnagar',
    'Jamshedpur',
    'Jhansi',
    'Jodhpur',
    'Kakinada',
    'Kalyan-Dombivli',
    'Kannur',
    'Kanpur',
    'Kochi',
    'Kolhapur',
    'Kollam',
    'Kota',
    'Kozhikode',
    'Kurnool',
    'Lucknow',
    'Ludhiana',
    'Madurai',
    'Malappuram',
    'Malegaon',
    'Mangalore',
    'Mathura',
    'Meerut',
    'Moradabad',
    'Mysore',
    'Nagpur',
    'Nanded',
    'Nashik',
    'Nellore',
    'Noida',
    'Patna',
    'Pondicherry',
    'Prayagraj',
    'Raipur',
    'Rajahmundry',
    'Rajkot',
    'Ranchi',
    'Rourkela',
    'Salem',
    'Sangli',
    'Saharanpur',
    'Shimoga',
    'Siliguri',
    'Solapur',
    'Srinagar',
    'Thane',
    'Thiruvananthapuram',
    'Thrissur',
    'Tiruchirappalli',
    'Tirunelveli',
    'Tiruppur',
    'Udaipur',
    'Ujjain',
    'Vadodara',
    'Varanasi',
    'Vasai-Virar',
    'Vijayawada',
    'Visakhapatnam',
    'Warangal',
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
    _speechHelper.cancel();
    super.dispose();
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
        ].toSet().toList(); // Deduplicate
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

    // As per user request: "only show the selected user location do not send to backend"
    // I am skipping the actual API fetch calls here to satisfy the requirement
    // Wait, if I skip fetch, nothing changes on home. I'll comment them for now or 
    // keep them if it feels like a mistake. But the user was specific.
    /*
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
    ]);
    */

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
      body: Consumer<HospitalProvider>(
        builder: (context, hospitalProvider, _) {
          final currentSelected = hospitalProvider.currentLocationName;

          return ListView(
            padding: EdgeInsets.zero,
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
                  child: Row(
                    children: [
                      Icon(Icons.my_location, size: 20, color: const Color(0xFF2372EC)),
                      const SizedBox(width: 8),
                      Text(
                        'Use my Current Location',
                        style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                            .copyWith(
                              color: const Color(0xFF2372EC),
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              if (!_isSearching) ...[
                const SizedBox(height: 8),

                // Popular Cities Header
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
                  (city) => _buildCityItem(city, currentSelected == city),
                ),

                const SizedBox(height: 16),

                // Other Cities Header
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

                // Other Cities List
                ..._otherCities.map(
                  (city) => _buildCityItem(city, currentSelected == city),
                ),
              ] else ...[
                // Search Results
                ..._filteredCities.map(
                  (city) => _buildCityItem(city, currentSelected == city),
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCityItem(String city, bool isSelected) {
    return InkWell(
      onTap: () => _selectCity(city),
      child: Container(
        color: isSelected ? const Color(0xFFF0F7FF) : null,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                city,
                style: EcliniqTextStyles.responsiveHeadlineZMedium(context)
                    .copyWith(
                      color: isSelected ? const Color(0xFF2372EC) : const Color(0xFF424242),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF2372EC), size: 18),
          ],
        ),
      ),
    );
  }
}
