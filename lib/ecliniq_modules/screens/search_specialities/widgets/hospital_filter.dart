import 'dart:async';
import 'dart:developer' as developer;

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:ecliniq/ecliniq_utils/speech_helper.dart';

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
  Set<String> selectedSymptoms = {};
  String? selectedAvailability;
  DateTime? _selectedDate;
  String? selectedGender;
  String? selectedExperience;
  double distanceRange = 50;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
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

      if (filters['date'] != null) {
        try {
          _selectedDate = DateTime.parse(filters['date'] as String);
        } catch (_) {}
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
      selectedSymptoms.clear();
      selectedAvailability = null;
      _selectedDate = null;
      selectedGender = null;
      selectedExperience = null;
      distanceRange = 50;
      selectedTab = 'Specialities';
    });
    
    widget.onFilterChanged({
      'specialities': <String>[],
      'symptoms': <String>[],
      'availability': null,
      'date': null,
      'gender': null,
      'experience': null,
      'distance': 50,
    });
  }

  void _emitFilterChange() {
    // Map symptoms to specialties and combine with manually selected specialties
    final Set<String> allSpecialities = Set<String>.from(selectedSpecialities);
    
    // Add specialties from selected symptoms
    for (final symptom in selectedSymptoms) {
      if (_symptomSpecialtyMap.containsKey(symptom)) {
        final specialtiesStr = _symptomSpecialtyMap[symptom]!;
        final specialitiesList = specialtiesStr.split(',').map((e) => e.trim()).toList();
        allSpecialities.addAll(specialitiesList);
      }
    }
    
    final dateStr = _selectedDate?.toIso8601String().split('T')[0];
    
    // Check if all filters are empty (manually cleared)
    final bool allFiltersEmpty = allSpecialities.isEmpty &&
        selectedAvailability == null &&
        selectedGender == null &&
        selectedExperience == null &&
        distanceRange == 50;
    
    if (allFiltersEmpty) {
      // If all filters are manually removed, behave same as reset
      widget.onFilterChanged({
        'specialities': <String>[],
        'symptoms': <String>[],
        'availability': null,
        'date': null,
        'gender': null,
        'experience': null,
        'distance': 50,
      });
    } else {
      widget.onFilterChanged({
        'specialities': allSpecialities.toList(),
        'symptoms': selectedSymptoms.toList(),
        'availability': selectedAvailability,
        'date': selectedAvailability == 'DATE' ? dateStr : null,
        'gender': selectedGender,
        'experience': selectedExperience,
        'distance': distanceRange,
      });
    }
  }

  final List<String> filterTabs = [
    'Specialities',
    'Availability',
    'Gender',
    'Distance',
    'Symptoms',
    'Experience',
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

  // Common symptoms
  final List<String> commonSymptoms = [
    'Fever/Chills',
    'Headache',
    'Stomach Pain',
    'Cold & Cough',
    'Body Pain',
    'Back Pain',
    'Breathing Difficulty',
    'Skin Rash /Itching',
    'Periods Problem',
    'Sleep Problem',
    'Hair Related Problem',
    'Pregnancy Related',
    'Dental Care',
    'Joint Pain',
    'Blood Pressure',
  ];

  // Symptom to specialty mapping
  final Map<String, String> _symptomSpecialtyMap = {
    'Fever / Chills': 'General Physician, Pediatrician',
    'Fever/Chills': 'General Physician, Pediatrician',
    'Cold & Cough': 'General Physician, Pediatrician, Pulmonologist',
    'Sore Throat': 'General Physician, ENT',
    'Body Pain': 'General Physician, Orthopedic',
    'Weakness / Fatigue': 'General Physician, Diabetologist, Endocrinologist',
    'Headache': 'General Physician, Neurologist',
    'Stomach Pain': 'Gastroenterologist',
    'Back Pain': 'Orthopedic',
    'Dizziness / Fainting': 'General Physician, Cardiologist, Neurologist',
    'Viral Infection Symptoms': 'General Physician',
    'High or Low Blood Pressure': 'General Physician, Cardiologist',
    'Blood Pressure': 'General Physician, Cardiologist',
    'General Health Check-up': 'General Physician',
    'Periods Problem': 'Gynaecologist',
    'Pregnancy Related': 'Gynaecologist',
    'Dental Care': 'Dentist',
    'Skin Rash /Itching': 'Dermatologist',
    'Hair Related Problem': 'Dermatologist',
    'Breathing Difficulty': 'Pulmonologist',
    'Joint Pain': 'Orthopedic',
    'Sleep Problem': 'Psychiatrist',
  };

  final List<String> availabilityOptions = [
    'TODAY',
    'TOMORROW',
    'DATE',
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
         SizedBox(height: EcliniqTextStyles.getResponsiveSize(context, 18)),
       Container(height: 0.5, color: Color(0xffD6D6D6)),
          SizedBox(height: EcliniqTextStyles.getResponsiveSize(context, 8)),
          
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
      case 'Symptoms':
        return _buildSymptomsList();
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availabilityOptions.map((avail) {
              final isSelected = selectedAvailability == avail;
              return ChoiceChip(
                label: Text(avail),
                selected: isSelected,
                selectedColor: Color(0xFF2372EC).withOpacity(0.2),
                backgroundColor: Colors.grey[200],
                labelStyle: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: isSelected ? Color(0xFF2372EC) : Color(0xff424242),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected ? Color(0xFF2372EC) : Colors.grey[400]!,
                  width: isSelected ? 2 : 1,
                ),
                onSelected: (selected) {
                  setState(() {
                    selectedAvailability = selected ? avail : null;
                    if (avail != 'DATE') {
                      _selectedDate = null;
                    }
                  });
                  _emitFilterChange();
                },
              );
            }).toList(),
          ),
          if (selectedAvailability == 'DATE') ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                  _emitFilterChange();
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF2372EC)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : _selectedDate!.toIso8601String().split('T')[0],
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Color(0xFF2372EC),
                ),
              ),
            ),
          ],
        ],
      ),
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
              // Toggle selection - deselect if already selected
              selectedGender = isSelected ? null : option;
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
              // Toggle selection - deselect if already selected
              selectedExperience = isSelected ? null : option;
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

  Widget _buildSymptomsList() {
    // Filter symptoms based on search query
    final filteredSymptoms = _searchQuery.isEmpty
        ? commonSymptoms
        : commonSymptoms.where((symptom) {
            return symptom.toLowerCase().contains(_searchQuery);
          }).toList();

    if (filteredSymptoms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No symptoms found matching "$_searchQuery"',
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
      itemCount: filteredSymptoms.length,
      itemBuilder: (context, index) {
        final symptom = filteredSymptoms[index];
        final isSelected = selectedSymptoms.contains(symptom);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedSymptoms.remove(symptom);
              } else {
                selectedSymptoms.add(symptom);
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
                    symptom,
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
  final SpeechHelper _speechHelper = SpeechHelper();
  bool get _isListening => _speechHelper.isListening;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
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
           margin: EdgeInsets.only(top: 10, left: 16, right: 16,),

    height: EcliniqTextStyles.getResponsiveSize(context, 52.0),
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
