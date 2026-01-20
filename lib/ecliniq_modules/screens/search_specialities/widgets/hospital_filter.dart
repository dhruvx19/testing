import 'dart:async';
import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HospitalFilterBottomSheet extends StatefulWidget {
  const HospitalFilterBottomSheet({
    super.key,
    required this.onFilterChanged,
    this.initialFilters,
  });

  final ValueChanged<Map<String, dynamic>> onFilterChanged;
  final Map<String, dynamic>? initialFilters;

  @override
  State<HospitalFilterBottomSheet> createState() =>
      _HospitalFilterBottomSheetState();
}

class _HospitalFilterBottomSheetState extends State<HospitalFilterBottomSheet> {
  String selectedTab = 'Specialities';
  Set<String> selectedSpecialities = {};
  String? selectedAvailability;
  String? selectedGender;
  String? selectedExperience;
  double distanceRange = 50;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize with existing filter values if provided
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;

      if (filters['specialities'] != null) {
        selectedSpecialities = Set<String>.from(
          filters['specialities'] as List,
        );
      }

      if (filters['availability'] != null) {
        selectedAvailability = filters['availability'] as String;
      }

      if (filters['gender'] != null) {
        selectedGender = filters['gender'] as String;
      }

      if (filters['experience'] != null) {
        selectedExperience = filters['experience'] as String;
      }

      if (filters['distance'] != null) {
        distanceRange = (filters['distance'] as num).toDouble();
      }
    }
  }

  void _resetFilters() {
    setState(() {
      selectedSpecialities.clear();
      selectedAvailability = null;
      selectedGender = null;
      selectedExperience = null;
      distanceRange = 50;
      selectedTab = 'Specialities';
    });
    // Emit empty filter state to clear active filters in parent
    widget.onFilterChanged({
      'specialities': <String>[],
      'availability': null,
      'gender': null,
      'experience': null,
      'distance': 50,
    });
  }

  void _emitFilterChange() {
    widget.onFilterChanged({
      'specialities': selectedSpecialities.toList(),
      'availability': selectedAvailability,
      'gender': selectedGender,
      'experience': selectedExperience,
      'distance': distanceRange,
    });
  }

  final List<String> filterTabs = [
    'Specialities',
    'Availability',
    'Gender',
    'Distance',
    // 'Fees',
    'Experience',
    'Languages',
    'Meet at',
  ];

  final List<String> specialities = [
    'General Physician / Family Doctor',
    'Pediatrician (Child Specialist)',
    "Gynaecologist (Women's Health Doctor)",
    'Dentist',
    'Dermatologist (Skin Doctor)',
    'ENT (Ear, Nose, Throat Specialist)',
    'Ophthalmologist (Eye Specialist)',
    'Cardiologist (Heart Specialist)',
    'Orthopedic (Bone & Joint Specialist)',
    'Diabetologist (Sugar Specialist)',
  ];

  final List<String> availabilityOptions = [
    'Anytime',
    'Available Now',
    'Today',
    'Tomorrow',
    'Saturday, 01 Nov',
    'Sunday, 02 Nov',
    'Monday, 03 Nov',
    'Tuesday, 04 Nov',
    'Wednesday, 05 Nov',
  ];

  final List<String> genderOptions = ['Male', 'Female', 'Others'];

  final List<String> experienceOptions = [
    '0 - 5 Years',
    '6 - 10 Years',
    '10+ Years',
    'Any',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Title
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, top: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: Color(0xff424242),
                        ),
                  ),
                  GestureDetector(
                    onTap: _resetFilters,
                    child: Text(
                      'Reset',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                          .copyWith(
                            fontWeight: FontWeight.w400,
                            color: Color(0xff2372EC),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SearchBarWidget(
            onSearch: (String value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          SizedBox(height: 6),
          Container(height: 0.5, color: Color(0xffD6D6D6)),
          SizedBox(height: 8),
          // Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: ListView.builder(
                    itemCount: filterTabs.length,
                    itemBuilder: (context, index) {
                      final tab = filterTabs[index];
                      final isSelected = selectedTab == tab;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedTab = tab;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xffF8FAFF)
                                : Colors.transparent,
                            border: Border(
                              top: BorderSide(
                                color: isSelected
                                    ? Color(0xff96BFFF)
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                              bottom: BorderSide(
                                color: isSelected
                                    ? Color(0xff96BFFF)
                                    : Colors.transparent,
                                width: 0.5,
                              ),
                              right: BorderSide(
                                color: isSelected
                                    ? Color(0xff96BFFF)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            tab,
                            style: isSelected
                                ? EcliniqTextStyles.responsiveTitleXBLarge(
                                    context,
                                  ).copyWith(color: Color(0xff2372EC))
                                : EcliniqTextStyles.responsiveTitleXLarge(
                                    context,
                                  ).copyWith(color: Color(0xff626060)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Container(width: 0.5, color: Color(0xffD6D6D6)),

                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: _buildFilterContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent() {
    switch (selectedTab) {
      case 'Specialities':
        return _buildSpecialitiesList();
      case 'Availability':
        return _buildAvailabilityList();
      case 'Gender':
        return _buildGenderList();
      case 'Distance':
        return _buildDistanceSlider();
      case 'Experience':
        return _buildExperienceList();
      default:
        return Center(
          child: Text(
            '$selectedTab options',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
    }
  }

  Widget _buildSpecialitiesList() {
    // Filter specialities based on search query
    final filteredSpecialities = _searchQuery.isEmpty
        ? specialities
        : specialities.where((speciality) {
            return speciality.toLowerCase().contains(_searchQuery);
          }).toList();

    if (filteredSpecialities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No specialities found matching "$_searchQuery"',
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredSpecialities.length,
      itemBuilder: (context, index) {
        final speciality = filteredSpecialities[index];
        final isSelected = selectedSpecialities.contains(speciality);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedSpecialities.remove(speciality);
              } else {
                selectedSpecialities.add(speciality);
              }
            });
            _emitFilterChange();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    speciality,
                    style: EcliniqTextStyles.responsiveTitleXLarge(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Color(0xff2372EC) : Color(0xff8E8E8E),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected ? Color(0xff2372EC) : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: EcliniqTextStyles.getResponsiveIconSize(context, 18),
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailabilityList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: availabilityOptions.length,
      itemBuilder: (context, index) {
        final option = availabilityOptions[index];
        final isSelected = selectedAvailability == option;
        return InkWell(
          onTap: () {
            setState(() {
              selectedAvailability = option;
            });
            _emitFilterChange();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: EcliniqTextStyles.responsiveTitleXLarge(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: genderOptions.length,
      itemBuilder: (context, index) {
        final option = genderOptions[index];
        final isSelected = selectedGender == option;
        return InkWell(
          onTap: () {
            setState(() {
              selectedGender = option;
            });
            _emitFilterChange();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: EcliniqTextStyles.responsiveTitleXLarge(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Color(0xff2372EC) : Color(0xff8E8E8E),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExperienceList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: experienceOptions.length,
      itemBuilder: (context, index) {
        final option = experienceOptions[index];
        final isSelected = selectedExperience == option;
        return InkWell(
          onTap: () {
            setState(() {
              selectedExperience = option;
            });
            _emitFilterChange();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: EcliniqTextStyles.responsiveTitleXLarge(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDistanceSlider() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Km Range',
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff626060), width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0',
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff424242),
                                ),
                          ),
                          Text(
                            'Km',
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff626060),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xff626060), width: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${distanceRange.toInt()}',
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff424242),
                                ),
                          ),
                          Text(
                            'Km',
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff626060),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Color(0xff2372EC),
              inactiveTrackColor: Color(0xffF9F9F9),
              thumbColor: Color(0xff2372EC),
              overlayColor: Color(0xff2372EC),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              trackHeight: 4,
            ),
            child: Slider(
              value: distanceRange,
              min: 0,
              max: 100,
              onChanged: (value) {
                setState(() {
                  distanceRange = value;
                });
                _emitFilterChange();
              },
            ),
          ),
        ],
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
    this.hintText = 'Search across filter',
    this.showBackButton = false,
    this.autofocus = false,
    this.onVoiceSearch,
  });

  final VoidCallback? onBack;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final VoidCallback? onVoiceSearch;
  final String hintText;
  final bool showBackButton;
  final bool autofocus;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  String query = '';
  final _controller = TextEditingController();
  Timer? _timer;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
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
    _controller.text = result.recognizedWords;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: result.recognizedWords.length),
    );

    setState(() {
      query = result.recognizedWords;
    });

    widget.onSearch(result.recognizedWords);

    if (result.finalResult) {
      _stopListening();
    }
  }

  void _handleVoiceSearch() {
    if (widget.onVoiceSearch != null) {
      widget.onVoiceSearch!();
    } else {
      if (_isListening) {
        _stopListening();
      } else {
        _startListening();
      }
    }
  }

  Future<void> search(String text) async {
    setState(() => query = text);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(text);
    });
  }


  @override
  Widget build(BuildContext context) {
    final outlinedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    );

    return Container(
      margin: EdgeInsets.only(top: 6, left: 16, right: 16, bottom: 16),

      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Color(0xff626060), width: 0.5),
      ),
      child: Animate(
        effects: const [
          FadeEffect(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ],
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SvgPicture.asset(
                EcliniqIcons.magnifierMyDoctor.assetPath,
                width: 24,
                height: 24,
              ),
            ),
            Expanded(
              child: TextField(
                autofocus: widget.autofocus,
                controller: _controller,
                decoration: InputDecoration(
                  enabledBorder: outlinedBorder,
                  focusedBorder: outlinedBorder,
                  border: outlinedBorder,
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  suffixIcon: query.isNotEmpty
                      ? Animate(
                          effects: const [
                            FadeEffect(
                              duration: Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            ),
                          ],
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              if (widget.onClear != null) {
                                widget.onClear!();
                              }
                              setState(() => query = '');
                              _controller.clear();
                              widget.onSearch('');
                            },
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              // decoration: _isListening
                              //     ? BoxDecoration(
                              //         shape: BoxShape.circle,
                              //         boxShadow: [
                              //           BoxShadow(
                              //             color: const Color(0xFF2372EC)
                              //                 .withOpacity(0.5),
                              //             blurRadius: 12,
                              //             spreadRadius: 2,
                              //           ),
                              //         ],
                              //       )
                              //     : null,
                              child: SvgPicture.asset(
                                EcliniqIcons.microphone.assetPath,
                                width: 24,
                                height: 24,
                                colorFilter: _isListening
                                    ? const ColorFilter.mode(
                                        Color(0xFF2372EC),
                                        BlendMode.srcIn,
                                      )
                                    : null,
                              ),
                            ),
                            onPressed: _handleVoiceSearch,
                          ),
                        ),
                  hintText: widget.hintText,
                  hintStyle: EcliniqTextStyles.responsiveHeadlineXMedium(
                    context,
                  ).copyWith(color: Color(0xffD6D6D6)),
                ),
                onChanged: search,
                textInputAction: TextInputAction.search,
                style: EcliniqTextStyles.responsiveTitleXLarge(
                  context,
                ).copyWith(color: Colors.black87),
                textAlignVertical: TextAlignVertical.center,
                cursorColor: Colors.blue,
                cursorWidth: 1.5,
                cursorHeight: 20,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
