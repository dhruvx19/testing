import 'dart:async';
import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_api/search_service.dart';
import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_core/auth/session_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/doctor_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/hospital/pages/hospital_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/action_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Search page with recent searches, frequent specialities, and search results
class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.shouldStartVoiceSearch = false});

  final bool shouldStartVoiceSearch;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchService _searchService = SearchService();
  final StorageService _storageService = StorageService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SpeechToText _speechToText = SpeechToText();

  bool _isSearching = false;
  bool _isLoading = false;
  Map<String, dynamic>? _searchResults;
  String? _errorMessage;
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';
  bool _speechEnabled = false;
  bool _isListening = false;

  // Random search suggestions if no recent searches
  final List<String> _randomSuggestions = [
    'Cardiologist',
    'Dermatologist',
    'Orthopedic',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _initSpeech().then((_) {
      // Start voice search if requested from home screen, after speech is initialized
      if (widget.shouldStartVoiceSearch && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _toggleVoiceSearch();
          }
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
            CustomErrorSnackBar.show(
              context: context,
              title: 'Permission Required',
              subtitle: 'Microphone permission is required for voice search.',
              duration: const Duration(seconds: 3),
            );
          } else {
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

    if (result.recognizedWords.trim().isNotEmpty) {
      _performSearch(result.recognizedWords);
    }

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

  /// Load recent searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey) ?? [];
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      developer.log('Error loading recent searches: $e');
    }
  }

  /// Save search query to recent searches
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];

      // Remove if already exists
      searches.remove(query.trim());
      // Add to beginning
      searches.insert(0, query.trim());
      // Keep only last 10
      if (searches.length > 10) {
        searches = searches.sublist(0, 10);
      }

      await prefs.setStringList(_recentSearchesKey, searches);
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      developer.log('Error saving recent search: $e');
    }
  }

  /// Perform search
  Future<void> _performSearch(String query) async {
    if (query.length < 3) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _errorMessage = null;
    });

    // Save to recent searches
    await _saveRecentSearch(query);

    try {
      final authToken = await SessionService.getAuthToken();
      final response = await _searchService.searchProviders(
        query: query,
        authToken: authToken,
      );

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _searchResults = response;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Search failed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      developer.log('Error performing search: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Network error: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = null;
      _errorMessage = null;
    });
    _searchFocusNode.requestFocus();
  }

  /// Navigate to doctor details
  void _navigateToDoctor(String doctorId) {
    EcliniqRouter.push(DoctorDetailScreen(doctorId: doctorId));
  }

  /// Navigate to hospital details
  void _navigateToHospital(String hospitalId) {
    EcliniqRouter.push(HospitalDetailScreen(hospitalId: hospitalId));
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
          padding: EdgeInsets.zero,
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Provider',
          style: EcliniqTextStyles.responsiveHeadlineMedium(
            context,
          ).copyWith(color: Color(0xff424242)),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          // Content
          Expanded(
            child: _isSearching
                ? _buildSearchResults()
                : _buildInitialContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
        context,
        top: 12,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: SearchBarWidget(
        hintText: 'Search Doctors or Hospitals',
        autofocus: true,
        controller: _searchController,
        isListening: _isListening,
        onSearch: (query) {
          if (query.length >= 3) {
            _performSearch(query);
          } else {
            setState(() {
              _isSearching = false;
              _searchResults = null;
            });
          }
        },
        onClear: _clearSearch,
        onVoiceSearch: _toggleVoiceSearch,
      ),
    );
  }

  Widget _buildInitialContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty || _randomSuggestions.isNotEmpty) ...[
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: 16.0,
                left: 16,
                top: 16,
                bottom: 0,
              ),
              child: Text(
                'Your Recent Searches',
                style: EcliniqTextStyles.responsiveHeadlineXMedium(
                  context,
                ).copyWith(color: Color(0xFF8E8E8E)),
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
            ),
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16.0,
                vertical: 0,
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    (_recentSearches.isNotEmpty
                            ? _recentSearches
                            : _randomSuggestions)
                        .map((search) => _buildSearchChip(search))
                        .toList(),
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
            ),
          ],
          // Most Searched Specialities
          const MostSearchedSpecialities(),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
        _performSearch(text);
      },

      child: Container(
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
          context,
          horizontal: 6,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 6),
          ),
          border: Border.all(color: const Color(0xFFD6D6D6), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              EcliniqIcons.history.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 18),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 18),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 4),
            ),
            Text(
              text,
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Color(0xFF424242)),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildShimmerLoading() {
    return ListView(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
      children: [
        ShimmerLoading(
          width: EcliniqTextStyles.getResponsiveWidth(context, 120),
          height: EcliniqTextStyles.getResponsiveHeight(context, 20),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
          ),
        ),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
        ),
        ...List.generate(3, (index) => _buildDoctorCardShimmer()),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 24),
        ),
        ShimmerLoading(
          width: EcliniqTextStyles.getResponsiveWidth(context, 120),
          height: EcliniqTextStyles.getResponsiveHeight(context, 20),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
          ),
        ),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
        ),
        ...List.generate(2, (index) => _buildHospitalCardShimmer()),
      ],
    );
  }

  Widget _buildDoctorCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: ShimmerLoading(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(30),
        ),
        title: ShimmerLoading(
          width: 200,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ShimmerLoading(
            width: 150,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: ShimmerLoading(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHospitalCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: ShimmerLoading(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(8),
        ),
        title: ShimmerLoading(
          width: 200,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoading(
                width: 150,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              ShimmerLoading(
                width: 100,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        trailing: ShimmerLoading(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
  Widget _buildSearchResults() {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1C63D5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults == null || _searchResults!['data'] == null) {
      return const Center(child: Text('No results found'));
    }

    final data = _searchResults!['data'];
    final doctors = data['doctors'] as List<dynamic>? ?? [];
    final hospitals = data['hospitals'] as List<dynamic>? ?? [];

    if (doctors.isEmpty && hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'No results found for "${_searchController.text}"',
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (doctors.isNotEmpty) ...[
          _buildSectionHeader('Doctors', doctors.length),
          const SizedBox(height: 12),
          ...doctors.map((doctor) => _buildDoctorCard(doctor)),
          const SizedBox(height: 24),
        ],
        if (hospitals.isNotEmpty) ...[
          _buildSectionHeader('Hospitals', hospitals.length),
          const SizedBox(height: 12),
          ...hospitals.map((hospital) => _buildHospitalCard(hospital)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Text(
      '$title ($count)',
      style: EcliniqTextStyles.responsiveHeadlineBMedium(
        context,
      ).copyWith(color: Color(0xFF424242)),
    );
  }

  /// Get full image URL from storage key
  /// @description Gets the public URL for a storage key if it starts with "public/",
  /// otherwise returns the key as-is (assuming it's already a full URL)
  /// @param imagePath - Image key or URL
  /// @returns Future<String?> - Public URL, original key, or null
  Future<String?> _getImageUrl(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // If starts with "public/", get public URL from API
    if (imagePath.startsWith('public/')) {
      return await _storageService.getPublicUrl(imagePath);
    }
    // Fallback to constructing URL from relative path
    return '${Endpoints.localhost}/$imagePath';
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final specialties = (doctor['specialties'] as List<dynamic>?) ?? [];
    final specialtyText = specialties.isNotEmpty
        ? specialties.join(', ')
        : 'General Physician';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: ClipOval(
          child: Container(
            width: 60,
            height: 60,
            color: const Color(0xFFF8FAFF),
            child: FutureBuilder<String?>(
              future: _getImageUrl(doctor['image'] as String?),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: EcliniqLoader(size: 20),
                  );
                }
                final imageUrl = snapshot.data;
                return imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            size: EcliniqTextStyles.getResponsiveIconSize(context, 30),
                            color: Color(0xFF8E8E8E),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: EcliniqLoader(size: 20),
                          );
                        },
                      )
                    : Icon(
                        Icons.person,
                        size: EcliniqTextStyles.getResponsiveIconSize(context, 30),
                        color: Color(0xFF8E8E8E),
                      );
              },
            ),
          ),
        ),
        title: Text(
          doctor['name'] ?? 'Unknown Doctor',
          style: EcliniqTextStyles.responsiveTitleXBLarge(
            context,
          ).copyWith(color: Color(0xFF424242)),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            specialtyText,
            style: EcliniqTextStyles.responsiveBodySmall(
              context,
            ).copyWith(color: Color(0xFF8E8E8E)),
          ),
        ),
        trailing: Transform.rotate(
          angle: 3.14 / 2,
          child: SvgPicture.asset(
            EcliniqIcons.arrowUp.assetPath,
            width: 24,
            height: 24,
          ),
        ),
        onTap: () {
          final doctorId = doctor['id'] as String?;
          if (doctorId != null) {
            _navigateToDoctor(doctorId);
          }
        },
      ),
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> hospital) {
    final numberOfDoctors = hospital['numberOfDoctors'] ?? 0;
    final doctorsText = numberOfDoctors > 0
        ? '$numberOfDoctors ${numberOfDoctors == 1 ? 'Doctor' : 'Doctors'}'
        : 'No Doctors';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, ),
        leading: ClipOval(
          child: Container(
            width: 60,
            height: 60,
            color: const Color(0xFFF8FAFF),
            child: FutureBuilder<String?>(
              future: _getImageUrl(hospital['image'] as String?),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: EcliniqLoader(size: 20),
                  );
                }
                final imageUrl = snapshot.data;
                return imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.local_hospital,
                            size: EcliniqTextStyles.getResponsiveIconSize(context, 30),
                            color: Color(0xFF8E8E8E),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: EcliniqLoader(size: 20),
                          );
                        },
                      )
                    : Icon(
                        Icons.local_hospital,
                        size: EcliniqTextStyles.getResponsiveIconSize(context, 30),
                        color: Color(0xFF8E8E8E),
                      );
              },
            ),
          ),
        ),
        title: Text(
          hospital['name'] ?? 'Unknown Hospital',
          style: EcliniqTextStyles.responsiveTitleXBLarge(
            context,
          ).copyWith(color: Color(0xFF424242)),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            doctorsText,
            style: EcliniqTextStyles.responsiveBodySmall(
              context,
            ).copyWith(color: Color(0xFF8E8E8E)),
          ),
        ),
        trailing: Transform.rotate(
          angle: 3.14 / 2,
          child: SvgPicture.asset(
            EcliniqIcons.arrowUp.assetPath,
            width: 24,
            height: 24,
          ),
        ),
        onTap: () {
          final hospitalId = hospital['id'] as String?;
          if (hospitalId != null) {
            _navigateToHospital(hospitalId);
          }
        },
      ),
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    this.onBack,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search Doctor',
    this.showBackButton = false,
    this.autofocus = false,
    this.onVoiceSearch,
    this.controller,
    this.onTap,
    this.isListening = false,
  });

  final VoidCallback? onBack;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final VoidCallback? onTap;
  final String hintText;
  final bool showBackButton;
  final bool autofocus;
  final TextEditingController? controller;
  final bool isListening;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  String query = '';
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    // Initialize query from controller if it has text
    query = _controller.text;
    // Always add listener to sync state with controller changes (for voice search)
    _controller.addListener(_onControllerChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If controller changed, update listener and sync state
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onControllerChanged);
      query = _controller.text;
    }
  }

  void _onControllerChanged() {
    if (mounted && _controller.text != query) {
      setState(() {
        query = _controller.text;
      });
    }
  }

  Future<void> search(String text) async {
    setState(() => query = text);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(text);
    });
  }

  void _handleVoiceSearch() {
    if (widget.onVoiceSearch != null) {
      widget.onVoiceSearch!();
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

CustomErrorSnackBar.show(
          context: context,
          title: 'Coming Soon',
          subtitle: 'Voice search feature coming soon!',
          duration: const Duration(seconds: 3),
       
      );
    }
  }

  void _clearSearch() {
    if (widget.onClear != null) {
      widget.onClear!();
    }
    setState(() => query = '');
    _controller.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Remove listener before disposing
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF626060), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: AbsorbPointer(
                absorbing: widget.onTap != null,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: search,
                  textInputAction: TextInputAction.search,
                  style: EcliniqTextStyles.responsiveTitleXLarge(
                    context,
                  ).copyWith(color: Color(0xFF424242)),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    hintText: widget.hintText,
                    hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xFF8E8E8E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,

                    isDense: true,
                  ),
                  cursorColor: Color(0xFF2372EC),
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                ),
              ),
            ),
          ),
          // Clear or Voice Icon
          if (query.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.close,
                  color: Color(0xFF9E9E9E),
                  size: EcliniqTextStyles.getResponsiveIconSize(context, 20),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _handleVoiceSearch,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  // decoration: widget.isListening
                  //     ? BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         boxShadow: [
                  //           BoxShadow(
                  //             color: const Color(0xFF2372EC).withOpacity(0.5),
                  //             blurRadius: 12,
                  //             spreadRadius: 2,
                  //           ),
                  //         ],
                  //       )
                  //     : null,
                  child: SvgPicture.asset(
                    EcliniqIcons.microphone.assetPath,
                    width: 32,
                    height: 32,
                    colorFilter: widget.isListening
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
}

class MostSearchedSpecialities extends StatelessWidget {
  final bool showShimmer;

  const MostSearchedSpecialities({super.key, this.showShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return _buildShimmer();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        final cardSpacing = isSmallScreen ? 8.0 : 18.0;
        final cardHeight = isSmallScreen ? 85.0 : 100.0;
        final cardWidth = (screenWidth - (isSmallScreen ? 40 : 48)) / 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 16.0,
                          left: 16,
                          top: 16,
                        ),
                        child: Text(
                          'Frequent Searched Specialities',
                          style: EcliniqTextStyles.responsiveHeadlineXMedium(
                            context,
                          ).copyWith(color: Color(0xff8E8E8E)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16.0),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.generalPhysician.assetPath,
                          title: 'General\nPhysician',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(
                                initialSpeciality: 'General Physician',
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.gynaecologist.assetPath,
                          title: 'Women\'s\nHealth',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(
                                initialSpeciality: 'Gynaecologist',
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.ophthalmologist.assetPath,
                          title: 'Eye\nCare',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(
                                initialSpeciality: 'Ophthalmologist',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.dentist.assetPath,
                          title: 'Dental\nCare',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(
                                initialSpeciality: 'Dentist',
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.pediatrician.assetPath,
                          title: 'Child\nSpecialist',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(
                                initialSpeciality: 'Pediatrician',
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.ent.assetPath,
                          title: 'Ear, Nose\n& Throat',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(initialSpeciality: 'ENT'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: cardSpacing),
          ],
        );
      },
    );
  }

  Widget _buildSpecialtyCard(
    BuildContext context, {
    required double cardWidth,
    required double cardHeight,
    required String iconPath,

    required String title,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = cardWidth < 130;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 150,
          height: 130,
          padding: EdgeInsets.all(isSmallScreen ? 6.0 : 12.0),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(99.0),
                ),
                child: Center(
                  child: Image.asset(iconPath, width: 52, height: 52),
                ),
              ),
              SizedBox(height: isSmallScreen ? 6.0 : 8.0),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: EcliniqTextStyles.responsiveTitleXLarge(
                    context,
                  ).copyWith(color: Color(0xff424242), height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 18,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 14,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  /// Build shimmer loading widget for search results
  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section header shimmer
        ShimmerLoading(
          width: 120,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        // Doctor card shimmers
        ...List.generate(3, (index) => _buildDoctorCardShimmer()),
        const SizedBox(height: 24),
        // Section header shimmer for hospitals
        ShimmerLoading(
          width: 120,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        // Hospital card shimmers
        ...List.generate(2, (index) => _buildHospitalCardShimmer()),
      ],
    );
  }

  /// Build shimmer for a doctor card
  Widget _buildDoctorCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: ShimmerLoading(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(30),
        ),
        title: ShimmerLoading(
          width: 200,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ShimmerLoading(
            width: 150,
            height: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: ShimmerLoading(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Build shimmer for a hospital card
  Widget _buildHospitalCardShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        leading: ShimmerLoading(
          width: 60,
          height: 60,
          borderRadius: BorderRadius.circular(8),
        ),
        title: ShimmerLoading(
          width: 200,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLoading(
                width: 150,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              ShimmerLoading(
                width: 100,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        trailing: ShimmerLoading(
          width: 24,
          height: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
