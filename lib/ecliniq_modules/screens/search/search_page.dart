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

  final List<String> _allSpecialities = [
    'General Physician',
    'Pediatrician',
    'Gynaecologist',
    'Dermatologist',
    'Cardiologist',
    'Orthopedic',
    'ENT',
    'Ophthalmologist',
    'Neurologist',
    'Psychiatrist',
    'Dentist',
    'Pulmonologist',
    'Urologist',
    'Gastroenterologist',
    'Dietitian',
    'Physiotherapist'
  ];

  final List<String> _allSymptoms = [
    'Fever',
    'Chills',
    'Cold',
    'Cough',
    'Headache',
    'Stomach Pain',
    'Body Pain',
    'Back Pain',
    'Breathing Difficulty',
    'Skin Rash',
    'Itching',
    'Acne',
    'Period Problems',
    'Sleep Issues',
    'Hair Fall',
    'Toothache',
    'Joint Pain',
    'Anxiety',
    'Depression',
    'Weakness',
    'Fatigue'
  ];

  List<String> _filteredSpecialities = [];
  List<String> _filteredSymptoms = [];
  
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

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
      setState(() {
        _recentSearches = [];
      });
    } catch (e) {
      developer.log('Error clearing history: $e');
    }
  }
  
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = prefs.getStringList(_recentSearchesKey) ?? [];

      
      searches.remove(query.trim());
      
      searches.insert(0, query.trim());
      
      if (searches.length > 3) {
        searches = searches.sublist(0, 3);
      }

      await prefs.setStringList(_recentSearchesKey, searches);
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      developer.log('Error saving recent search: $e');
    }
  }

  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
        _filteredSpecialities = [];
        _filteredSymptoms = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      // Always filter local specialities and symptoms
      _filteredSpecialities = _allSpecialities
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _filteredSymptoms = _allSymptoms
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });

    // Only call API if query is 3+ characters
    if (query.length < 3) {
      setState(() {
        _isLoading = false;
        _searchResults = null; // Clear API results for short queries
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    
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
            _searchResults = null;
            _isLoading = false;
            // Don't set error message - just show local results
          });
        }
      }
    } catch (e) {
      developer.log('Error performing search: $e');
      if (mounted) {
        setState(() {
          _searchResults = null;
          _isLoading = false;
          // Don't set error message - just show local results
        });
      }
    }
  }

  
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = null;
      _errorMessage = null;
      _filteredSpecialities = [];
      _filteredSymptoms = [];
    });
    _searchFocusNode.requestFocus();
  }

  
  void _navigateToDoctor(String doctorId) {
    EcliniqRouter.push(DoctorDetailScreen(doctorId: doctorId));
  }

  
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
          
          _buildSearchBar(),
          
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
        rotatingHints: const [
          'Search Doctor',
          'Search Hospital',
          'Search Speciality',
          'Search Symptoms',
        ],
        onSearch: (query) {
          if (query.isNotEmpty) {
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
          
          if (_recentSearches.isNotEmpty) ...[ 
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: 16.0,
                left: 16,
                top: 16,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Recent Searches',
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xFF8E8E8E)),
                  ),
                  InkWell(
                    onTap: _clearHistory,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        'Clear',
                        style: EcliniqTextStyles.responsiveBodySmall(
                          context,
                        ).copyWith(
                          color: Color(0xff1C63D5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
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
                children: _recentSearches
                    .map((search) => _buildSearchChip(search))
                    .toList(),
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
            ),
          ],
          
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
      // Show shimmer only for API results section
      // Local results will still be visible below
      return _buildShimmerLoading();
    }

    // Parse API results if available
    final doctors = _searchResults != null && _searchResults!['data'] != null
        ? (_searchResults!['data']['doctors'] as List<dynamic>? ?? [])
        : <dynamic>[];
    final hospitals = _searchResults != null && _searchResults!['data'] != null
        ? (_searchResults!['data']['hospitals'] as List<dynamic>? ?? [])
        : <dynamic>[];

    // Check if we have any results at all (local + API)
    if (doctors.isEmpty &&
        hospitals.isEmpty &&
        _filteredSpecialities.isEmpty &&
        _filteredSymptoms.isEmpty) {
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
        if (_filteredSpecialities.isNotEmpty) ...[
          _buildSectionHeader('Specialities', _filteredSpecialities.length),
          const SizedBox(height: 12),
          ..._filteredSpecialities.map(
            (s) => _buildSimpleResultCard(s, 'Speciality'),
          ),
          const SizedBox(height: 24),
        ],
        if (_filteredSymptoms.isNotEmpty) ...[
          _buildSectionHeader('Symptoms', _filteredSymptoms.length),
          const SizedBox(height: 12),
          ..._filteredSymptoms.map((s) => _buildSimpleResultCard(s, 'Symptom')),
          const SizedBox(height: 24),
        ],
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

  Widget _buildSimpleResultCard(dynamic item, String type) {
    // Expect item to be a String or Map. If simple string list from API:
    final name = item is Map ? (item['name'] ?? item['title'] ?? '') : item.toString();
    
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      child: InkWell(
        onTap: () {
           // Navigate to speciality/symptom doctor list
           // If it's a symptom, we might need a mapping or just pass it as speciality filter
           // Assuming SpecialityDoctorsList can handle a filter string
           EcliniqRouter.push(SpecialityDoctorsList(initialSpeciality: name));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: type == 'Speciality' ? Colors.blue.shade50 : Colors.orange.shade50,
                   shape: BoxShape.circle,
                 ),
                 child: Icon(
                   type == 'Speciality' ? Icons.local_hospital : Icons.sick,
                   color: type == 'Speciality' ? const Color(0xff1C63D5) : Colors.orange,
                   size: 20,
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Text(
                   name,
                   style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                     fontWeight: FontWeight.w500,
                     color: const Color(0xff424242),
                   ),
                 ),
               ),
               Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
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

  
  
  
  
  
  Future<String?> _getImageUrl(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    if (imagePath.startsWith('public/')) {
      return await _storageService.getPublicUrl(imagePath);
    }
    
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
    this.rotatingHints,
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
  final List<String>? rotatingHints;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> with SingleTickerProviderStateMixin {
  String query = '';
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  Timer? _timer;
  Timer? _hintRotationTimer;
  int _currentHintIndex = 0;
  int _nextHintIndex = 1;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    query = _controller.text;
    _controller.addListener(_onControllerChanged);
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: -1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start rotating hints if provided
    if (widget.rotatingHints != null && widget.rotatingHints!.length > 1) {
      _startHintRotation();
    }
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onControllerChanged);
      query = _controller.text;
    }
    
    if (oldWidget.rotatingHints != widget.rotatingHints) {
      _hintRotationTimer?.cancel();
      if (widget.rotatingHints != null && widget.rotatingHints!.length > 1) {
        _currentHintIndex = 0;
        _nextHintIndex = 1;
        _startHintRotation();
      }
    }
  }

  void _startHintRotation() {
    _hintRotationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && widget.rotatingHints != null && query.isEmpty) {
        final nextIndex = (_currentHintIndex + 1) % widget.rotatingHints!.length;
        
        // Check if we're wrapping around (going from last to first)
        if (nextIndex == 0 && _currentHintIndex == widget.rotatingHints!.length - 1) {
          // Fast reverse animation through all hints
          _performFastReverse();
        } else {
          // Normal forward animation
          _nextHintIndex = nextIndex;
          _animationController.forward(from: 0.0).then((_) {
            if (mounted) {
              setState(() {
                _currentHintIndex = _nextHintIndex;
              });
              _animationController.reset();
            }
          });
        }
      }
    });
  }

  void _performFastReverse() async {
    // Temporarily speed up animation for reverse effect
    _animationController.duration = const Duration(milliseconds: 150);
    
    // Cycle through all hints in reverse quickly
    for (int i = widget.rotatingHints!.length - 1; i >= 0; i--) {
      if (!mounted) break;
      
      _nextHintIndex = i == 0 ? widget.rotatingHints!.length - 1 : i - 1;
      
      await _animationController.forward(from: 0.0);
      
      if (mounted) {
        setState(() {
          _currentHintIndex = _nextHintIndex;
        });
        _animationController.reset();
      }
      
      // Small delay between each hint during fast reverse
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    
    // Restore normal animation speed
    _animationController.duration = const Duration(milliseconds: 500);
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
    _hintRotationTimer?.cancel();
    _animationController.dispose();
    _controller.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildRotatingHint() {
    if (widget.rotatingHints == null || widget.rotatingHints!.isEmpty) {
      return Text(
        widget.hintText,
        style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
            .copyWith(color: Color(0xFF8E8E8E)),
      );
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return ClipRect(
          child: SizedBox(
            height: 24,
            child: Stack(
              children: [
                // Current hint sliding up
                Transform.translate(
                  offset: Offset(0, _slideAnimation.value * 16),
                  child: Opacity(
                    opacity: 1.0 + _slideAnimation.value,
                    child: Text(
                      widget.rotatingHints![_currentHintIndex],
                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                          .copyWith(color: Color(0xFF8E8E8E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Next hint sliding up from bottom
                Transform.translate(
                  offset: Offset(0, (1.0 + _slideAnimation.value) * 16),
                  child: Opacity(
                    opacity: -_slideAnimation.value,
                    child: Text(
                      widget.rotatingHints![_nextHintIndex],
                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context)
                          .copyWith(color: Color(0xFF8E8E8E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Stack(
                  children: [
                    // Show rotating hint only when field is empty
                    if (query.isEmpty)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: _buildRotatingHint(),
                          ),
                        ),
                      ),
                    // TextField
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: search,
                      textInputAction: TextInputAction.search,
                      style: EcliniqTextStyles.responsiveTitleXLarge(
                        context,
                      ).copyWith(color: Color(0xFF424242)),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        hintText: null, 
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                      ),
                      cursorColor: Color(0xFF2372EC),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  
  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        
        ShimmerLoading(
          width: 120,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        
        ...List.generate(3, (index) => _buildDoctorCardShimmer()),
        const SizedBox(height: 24),
        
        ShimmerLoading(
          width: 120,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),
        
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
}
