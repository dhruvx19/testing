import 'dart:async';
import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/model/doctor_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/widgets/doctor_info_widgets.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../ecliniq_icons/icons.dart';

class MyDoctors extends StatefulWidget {
  const MyDoctors({super.key});

  @override
  State<MyDoctors> createState() => _MyDoctorsState();
}

class _MyDoctorsState extends State<MyDoctors> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  List<FavouriteDoctor> _doctors = [];
  List<FavouriteDoctor> _filteredDoctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchFavouriteDoctors();
    _initSpeech();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
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
    } catch (e) {
      _speechEnabled = false;
    }
  }

  void _startListening() async {
    if (_isListening) return;

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
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
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
        final specialization = doctor.specialization.toLowerCase();
        final qualification = doctor.qualification.toLowerCase();
        return name.contains(_searchQuery) ||
            specialization.contains(_searchQuery) ||
            qualification.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _fetchFavouriteDoctors() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required. Please login again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _patientService.getFavouriteDoctors(
        authToken: authToken,
      );

      if (mounted) {
        if (response.success) {
          setState(() {
            _doctors = response.data;
            _filteredDoctors = response.data;
            _isLoading = false;
            _errorMessage = null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load doctors: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leadingWidth: 58,
        titleSpacing: 0,
        backgroundColor: Colors.white,

        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'My Doctors',
            style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
              color: Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
            height: EcliniqTextStyles.getResponsiveButtonHeight(
              context,
              baseHeight: 50.0,
            ),
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 10,
              vertical: 0,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(
                EcliniqTextStyles.getResponsiveBorderRadius(context, 8),
              ),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Row(
              spacing: 10,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SvgPicture.asset(
                  EcliniqIcons.magnifierMyDoctor.assetPath,
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      hintText: 'Search Doctor',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleVoiceSearch,
                  child: Padding(
                    padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                      context,
                      right: 8,
                      top: 0,
                      bottom: 0,
                      left: 0,
                    ),
                    child: SvgPicture.asset(
                      EcliniqIcons.microphone.assetPath,
                      height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                      width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                      colorFilter: _isListening
                          ? const ColorFilter.mode(
                              Color(0xFF2372EC),
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildDoctorsList()),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    if (_isLoading) {
      return _buildShimmerList();
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 48),
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFavouriteDoctors,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredDoctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.favorite_border,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 48),
              color: Colors.grey,
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
            ),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No doctors found matching "$_searchQuery"'
                  : 'No favourite doctors yet',
              style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) {
        return DoctorInfoWidget(doctor: _filteredDoctors[index]);
      },
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Container(
          height: 300,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Avatar shimmer
                  ShimmerLoading(
                    width: 64,
                    height: 64,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  const SizedBox(width: 12),
                  // Name and details shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerLoading(
                          width: 160,
                          height: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        ShimmerLoading(
                          width: 120,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        ShimmerLoading(
                          width: 100,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ShimmerLoading(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              // Stats row
              Row(
                children: [
                  ShimmerLoading(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 10),
                  ShimmerLoading(
                    width: 110,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 10),
                  ShimmerLoading(
                    width: 58,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 10),
                  ShimmerLoading(
                    width: 60,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              // Availability row
              Row(
                children: [
                  ShimmerLoading(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 10),
                  ShimmerLoading(
                    width: 140,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 8),
                  ShimmerLoading(
                    width: 100,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              // Location row
              Row(
                children: [
                  ShimmerLoading(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ShimmerLoading(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShimmerLoading(
                    width: 70,
                    height: 24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              // Tokens + button
              ShimmerLoading(
                width: 180,
                height: 24,
                borderRadius: BorderRadius.circular(4),
              ),
              Row(
                children: [
                  Expanded(
                    child: ShimmerLoading(
                      height: 48,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShimmerLoading(
                      height: 48,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
