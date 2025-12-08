import 'dart:async';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DoctorFilterBottomSheet extends StatefulWidget {
  const DoctorFilterBottomSheet({super.key});

  @override
  State<DoctorFilterBottomSheet> createState() =>
      _DoctorFilterBottomSheetState();
}

class _DoctorFilterBottomSheetState extends State<DoctorFilterBottomSheet> {
  String selectedTab = 'Specialities';
  Set<String> selectedSpecialities = {};
  String? selectedAvailability;
  String? selectedGender;
  String? selectedExperience;
  double distanceRange = 50;

  final List<String> filterTabs = [
    'Specialities',
    'Availability',
    'Gender',
    'Distance',
    'Fees',
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),
          SearchBarWidget(onSearch: (String value) {}),
          SizedBox(height: 20),
          Container(height: 0.5, color: Color(0xffD6D6D6)),
          SizedBox(height: 10),
          // Content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Filter categories
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
                            style: TextStyle(
                              color: isSelected
                                  ? Color(0xff2372EC)
                                  : Colors.grey[700],
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
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
          // Apply and Clear buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedSpecialities.clear();
                        selectedAvailability = null;
                        selectedGender = null;
                        selectedExperience = null;
                        distanceRange = 50;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF2372EC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                        color: Color(0xFF2372EC),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Return filter data
                      Navigator.pop(context, {
                        'specialities': selectedSpecialities.toList(),
                        'availability': selectedAvailability,
                        'gender': selectedGender,
                        'experience': selectedExperience,
                        'distance': distanceRange,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2372EC),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: specialities.length,
      itemBuilder: (context, index) {
        final speciality = specialities[index];
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
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    speciality,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(width: 12),
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
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
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
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xff2372EC) : Colors.grey[400]!,
                      width: 2,
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
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
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
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
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
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xff2372EC) : Colors.grey[400]!,
                      width: 2,
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
          const Text(
            'Select Km Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xff424242),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      '0 Km',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff626060),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${distanceRange.toInt()} Km',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xff626060),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Color(0xff2372EC),
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Color(0xff2372EC),
              overlayColor: Color(0xff2372EC).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
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

  Future<void> search(String text) async {
    setState(() => query = text);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(text);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outlinedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide.none,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Color(0xff626060)),
      ),
      child: Animate(
        effects: const [
          FadeEffect(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        ],
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
                      },
                    ),
                  )
                : SizedBox(),
            prefixIcon: Image.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: 2,
              height: 2,
            ),
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 14.0,
            ),
          ),
          onChanged: search,
          textInputAction: TextInputAction.search,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          textAlignVertical: TextAlignVertical.center,
          cursorColor: Colors.blue,
          cursorWidth: 1.5,
          cursorHeight: 20,
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ),
    );
  }
}
