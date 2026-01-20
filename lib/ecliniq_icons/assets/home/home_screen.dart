import 'dart:convert';
import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_api/appointment_service.dart';
import 'package:ecliniq/ecliniq_api/search_service.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/navigation_helper.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:page_transition/page_transition.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/hospital_provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/appointment_banner.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/easy_to_book.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/not_feeling_well.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/quick_actions.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/searched_specialities.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/location_search.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_bar_widgets/search_bar.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/widgets/top_hospitals.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/top_doctor/top_doctors.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/notification_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/provider/notification_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/search/search_page.dart' hide SearchBarWidget, MostSearchedSpecialities;
import 'package:ecliniq/ecliniq_modules/screens/search/search_results_screen.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_navigation/bottom_navigation.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/action_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final int _currentIndex = 0;
  bool _hasShownLocationSheet = false;
  bool _hasInitializedDoctors = false;
  final AppointmentService _appointmentService = AppointmentService();
  List<AppointmentBanner> _banners = [];
  bool _isLoadingBanners = false;
  static const String _bannersCacheKey = 'cached_appointment_banners';
  
  // Voice search functionality
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final SearchService _searchService = SearchService();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLocationSheet();
      _initializeDoctors();
      _loadCachedBannersAndFetch();
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchUnreadCount();
    });
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
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

CustomErrorSnackBar.show(
              context: context,
              title: 'Permission Required',
              subtitle: 'Speech recognition is not available. Please check your permissions.',
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
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
         
   CustomErrorSnackBar.show(
                context: context,
                title: 'Permission Required',
                subtitle: 'Microphone permission is required for voice search.',
                duration: const Duration(seconds: 3),
              
            );
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
         
            CustomErrorSnackBar.show(
                context: context,
                title: 'Speech Recognition Error',
                subtitle: 'Speech recognition error: ${error.errorMsg}',
                duration: const Duration(seconds: 3),
              
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
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
     
    CustomErrorSnackBar.show(
            context: context,
            title: 'Permission Required',
            subtitle: 'Speech recognition is not available. Please check your permissions.',
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

    // Update the search controller with recognized words
    _searchController.text = result.recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: result.recognizedWords.length),
    );

    setState(() {});

    // If we have a valid search query (3+ characters), navigate to search results
    if (result.recognizedWords.trim().length >= 3) {
      _performSearchAndNavigate(result.recognizedWords);
    }

    if (result.finalResult) {
      _stopListening();
      // If final result has valid query, navigate
      if (result.recognizedWords.trim().length >= 3) {
        _performSearchAndNavigate(result.recognizedWords);
      }
    }
  }

  Future<void> _performSearchAndNavigate(String query) async {
    try {
      final authToken = await SessionService.getAuthToken();
      // Navigate to search results screen with the query
      EcliniqRouter.push(
        SearchResultsScreen(
          searchQuery: query,
          authToken: authToken,
        ),
        transition: PageTransitionType.rightToLeft,
      );
    } catch (e) {
      developer.log('Error navigating to search results: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
          CustomErrorSnackBar.show(
            context: context,
            title: 'Error',
            subtitle: 'Error: ${e.toString()}',
            duration: const Duration(seconds: 3),
     
        );
      }
    }
  }

  void _toggleVoiceSearch() {
    // Navigate to search page and start voice search there
    EcliniqRouter.push(
      const SearchPage(shouldStartVoiceSearch: true),
      transition: PageTransitionType.rightToLeft,
    );
  }

  void _handleSearch(String query) {
    if (query.trim().length >= 3) {
      _performSearchAndNavigate(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    if (_isListening) {
      _stopListening();
    }
  }

  void _checkAndShowLocationSheet() {
    if (!_hasShownLocationSheet && mounted) {
      _hasShownLocationSheet = true;
      final hospitalProvider = Provider.of<HospitalProvider>(
        context,
        listen: false,
      );

      if (!hospitalProvider.hasLocation) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showLocationBottomSheet(context);
          }
        });
      }
    }
  }

  void _initializeDoctors() async {
    if (!_hasInitializedDoctors && mounted) {
      _hasInitializedDoctors = true;
      
      if (!mounted) return;
      
      final doctorProvider = Provider.of<DoctorProvider>(
        context,
        listen: false,
      );
      final hospitalProvider = Provider.of<HospitalProvider>(
        context,
        listen: false,
      );

      // Check if doctors need to be fetched
      if (!doctorProvider.hasDoctors && !doctorProvider.isLoading) {
        // Hardcoded location values
        const double latitude = 12.9173;
        const double longitude = 77.6377;
        const String locationName = 'Current Location';

        // Update providers with hardcoded location
        hospitalProvider.setLocation(
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
        );
        
        if (!mounted) return;
        
        doctorProvider.setLocation(
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
        );

        // Use hardcoded location values
        const double finalLatitude = 12.9173;
        const double finalLongitude = 77.6377;

        if (!mounted) return;

        doctorProvider.fetchTopDoctors(
          latitude: finalLatitude,
          longitude: finalLongitude,
          isRefresh: true,
        );
      }
    }
  }

  void _showLocationBottomSheet(BuildContext context) {
    EcliniqBottomSheet.show(
      context: context,
      child: const LocationBottomSheet(currentLocation: ''),
    );
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      return;
    }
    NavigationHelper.navigateToTab(context, index, _currentIndex);
  }

  Future<void> _onRefresh() async {
    final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
    await doctorProvider.refreshDoctors();
    await _fetchBannersForHome();
  }

  /// Load cached banners immediately, then fetch fresh ones in background
  Future<void> _loadCachedBannersAndFetch() async {
    // Load cached banners first for instant display
    await _loadCachedBanners();
    
    // Then fetch fresh banners in background
    await _fetchBannersForHome();
  }

  /// Load banners from cache
  Future<void> _loadCachedBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedBannersJson = prefs.getString(_bannersCacheKey);
      
      if (cachedBannersJson != null && cachedBannersJson.isNotEmpty) {
        final List<dynamic> bannersList = json.decode(cachedBannersJson);
        final cachedBanners = bannersList
            .map((banner) => AppointmentBanner.fromJson(banner))
            .toList();
        
        if (mounted && cachedBanners.isNotEmpty) {
          setState(() {
            _banners = cachedBanners;
          });
          developer.log('Loaded ${cachedBanners.length} cached banners');
        }
      }
    } catch (e) {
      developer.log('Error loading cached banners: $e');
    }
  }

  /// Save banners to cache
  Future<void> _saveBannersToCache(List<AppointmentBanner> banners) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bannersJson = json.encode(
        banners.map((banner) => {
          'type': banner.type,
          'appointmentId': banner.appointmentId,
          'doctorName': banner.doctorName,
          'doctorSpecialization': banner.doctorSpecialization,
          'tokenNumber': banner.tokenNumber,
          'appointmentDate': banner.appointmentDate,
          'appointmentDateFormatted': banner.appointmentDateFormatted,
          'appointmentTime': banner.appointmentTime,
          'hospitalName': banner.hospitalName,
          'bookedFor': banner.bookedFor,
          'patientName': banner.patientName,
          'status': banner.status,
          'isInQueue': banner.isInQueue,
        }).toList(),
      );
      await prefs.setString(_bannersCacheKey, bannersJson);
      developer.log('Saved ${banners.length} banners to cache');
    } catch (e) {
      developer.log('Error saving banners to cache: $e');
    }
  }

  Future<void> _fetchBannersForHome() async {
    if (_isLoadingBanners) return;

    setState(() {
      _isLoadingBanners = true;
    });

    try {
      final authToken = await SessionService.getAuthToken();
      if (authToken == null || authToken.isEmpty) {
        developer.log('No auth token available for banners API call');
        if (mounted) {
          setState(() {
            _isLoadingBanners = false;
            // Keep cached banners if available, only clear if no cache exists
            if (_banners.isEmpty) {
              _banners = [];
            }
          });
        }
        return;
      }

      final response = await _appointmentService.getBannersForHome(
        authToken: authToken,
      );

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final bannersData = response['data']['banners'] as List<dynamic>?;
          if (bannersData != null) {
            final allBanners = bannersData
                .map((banner) => AppointmentBanner.fromJson(banner))
                .toList();

            // Filter to show only latest banner per type
            final filteredBanners = _getLatestBannerPerType(allBanners);

            // Save to cache
            await _saveBannersToCache(filteredBanners);

            setState(() {
              _banners = filteredBanners;
              _isLoadingBanners = false;
            });
            developer.log(
              'Banners fetched successfully: ${allBanners.length} total, ${_banners.length} unique types',
            );
          } else {
            setState(() {
              _banners = [];
              _isLoadingBanners = false;
            });
            // Clear cache if no banners
            await _clearBannersCache();
          }
        } else {
          developer.log('Failed to fetch banners: ${response['message']}');
          // Don't clear banners on error, keep cached ones
          setState(() {
            _isLoadingBanners = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error fetching banners: $e');
      if (mounted) {
        // Don't clear banners on error, keep cached ones
        setState(() {
          _isLoadingBanners = false;
        });
      }
    }
  }

  /// Clear banners cache
  Future<void> _clearBannersCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bannersCacheKey);
    } catch (e) {
      developer.log('Error clearing banners cache: $e');
    }
  }


  /// Filter banners to show only the latest one per type
  List<AppointmentBanner> _getLatestBannerPerType(
    List<AppointmentBanner> banners,
  ) {
    final Map<String, AppointmentBanner> latestByType = {};

    for (final banner in banners) {
      final type = banner.type.toUpperCase();

      // Parse appointment date to compare
      DateTime? bannerDate;
      try {
        bannerDate = DateTime.parse(banner.appointmentDate);
      } catch (e) {
        developer.log('Error parsing date for banner: ${banner.appointmentId}');
        continue;
      }

      // If this type doesn't exist or this banner is newer, use it
      if (!latestByType.containsKey(type) ||
          (latestByType[type] != null &&
              DateTime.parse(
                latestByType[type]!.appointmentDate,
              ).isBefore(bannerDate))) {
        latestByType[type] = banner;
      }
    }

    return latestByType.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return EcliniqScaffold(
          backgroundColor: EcliniqScaffold.primaryBlue,
          body: SizedBox.expand(
            child: Column(
              children: [
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 44),
                ),
                _buildAppBar(),
                LocationSelectorWidget(
                  currentLocation: 'Vishnu Dev Nagar, Wakad',
                ),
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search Doctors',
                  isListening: _isListening,
                  onTap: () {
                    EcliniqRouter.push(
                      const SearchPage(),
                      transition: PageTransitionType.rightToLeft,
                    );
                  },
                  onSearch: _handleSearch,
                  onClear: _clearSearch,
                  onVoiceSearch: _toggleVoiceSearch,
                ),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 10),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return RefreshIndicator(
                            onRefresh: _onRefresh,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                children: [
                                        SizedBox(
                                          height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
                                        ),
                                  QuickActionsWidget(),
                                        SizedBox(
                                          height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
                                        ),
                                  _buildTopDoctorsSection(),
                                        SizedBox(
                                          height: EcliniqTextStyles.getResponsiveSpacing(context, 48),
                                        ),
                                  MostSearchedSpecialities(),
                                        SizedBox(
                                          height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                                        ),
                                  NotFeelingWell(),
                                        SizedBox(
                                          height: EcliniqTextStyles.getResponsiveSpacing(context, 10),
                                        ),
                                  TopHospitalsWidget(),
                                        SizedBox(
                                          height: EcliniqTextStyles.getResponsiveSpacing(context, 30),
                                        ),
                                  EasyWayToBookWidget(),
                                        SizedBox(
                                          height: EcliniqTextStyles.getResponsiveSpacing(context, 60),
                                        ),
                                ],
                              ),
                            ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Fixed Banners above navbar
                        if (_banners.isNotEmpty)
                          AppointmentBannersList(
                            banners: _banners,
                            onBannerTap: (appointmentId) {
                              // Navigation handled in banner widget
                            },
                            onBannerClose: (appointmentId) async {
                              setState(() {
                                _banners = _banners
                                    .where(
                                      (b) => b.appointmentId != appointmentId,
                                    )
                                    .toList();
                              });
                              // Update cache after closing banner
                              await _saveBannersToCache(_banners);
                            },
                          ),
                        EcliniqBottomNavigationBar(
                          currentIndex: _currentIndex,
                          onTap: _onTabTapped,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 14.0),
      child: Row(
        children: [
          SvgPicture.asset(
            EcliniqIcons.nameLogo.assetPath,
            height: EcliniqTextStyles.getResponsiveHeight(context, 32),
            width: EcliniqTextStyles.getResponsiveWidth(context, 138),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await EcliniqRouter.push(NotificationScreen());
              if (mounted) {
                Provider.of<NotificationProvider>(
                  context,
                  listen: false,
                ).fetchUnreadCount();
              }
            },
            child: Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset(
                      EcliniqIcons.notificationBell.assetPath,
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                    ),
                    if (provider.unreadCount > 0)
                      Positioned(
                        top: -12,
                        right: -8,
                        child: Container(
                          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 4),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffF04248),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: EcliniqText(
                              provider.unreadCount > 99
                                  ? '99+'
                                  : '${provider.unreadCount}',
                              style: EcliniqTextStyles.headlineSmall.copyWith(
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDoctorsSection() {
    return RepaintBoundary(
      key: const ValueKey('top_doctors_section'),
      child: Consumer<DoctorProvider>(
      builder: (context, doctorProvider, child) {
        // Show error state if there's an error
        if (doctorProvider.errorMessage != null &&
            !doctorProvider.isLoading &&
            !doctorProvider.hasDoctors) {
          return _buildErrorState(doctorProvider);
        }

        // Show doctors or shimmer
        return TopDoctorsWidget(
            key: ValueKey('top_doctors_${doctorProvider.doctors?.length ?? 0}_${doctorProvider.isLoading}'),
          doctors: doctorProvider.doctors,
          showShimmer: doctorProvider.isLoading,
        );
      },
      ),
    );
  }

  Widget _buildErrorState(DoctorProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: EcliniqTextStyles.getResponsiveIconSize(context, 48),
          ),
          const SizedBox(height: 12),
          EcliniqText(
            'Failed to load doctors',
            style: EcliniqTextStyles.titleXBLarge.copyWith(
              color: Colors.red.shade900,
            ),
          ),
          const SizedBox(height: 4),
          EcliniqText(
            provider.errorMessage ?? 'Unknown error occurred',
            style: EcliniqTextStyles.bodySmall.copyWith(
              color: Colors.red.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.retry(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const EcliniqText('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds a widget with error handling to prevent white screen
  Widget _buildSafeWidget(Widget Function() builder) {
    return Builder(
      builder: (context) {
        try {
          return builder();
        } catch (e, stackTrace) {
          developer.log('Error building widget: $e', error: e, stackTrace: stackTrace);
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: EcliniqText(
                'Error loading widget',
                style: EcliniqTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
