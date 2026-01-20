import 'dart:async';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SelectSpecialitiesBottomSheet extends StatefulWidget {
  final List<String>? initialSelection;
  final Function(List<String>)? onSelectionChanged;

  const SelectSpecialitiesBottomSheet({
    super.key,
    this.initialSelection,
    this.onSelectionChanged,
  });

  @override
  State<SelectSpecialitiesBottomSheet> createState() =>
      _SelectSpecialitiesBottomSheetState();
}

class _SelectSpecialitiesBottomSheetState
    extends State<SelectSpecialitiesBottomSheet> {
  Set<String> selectedSpecialities = {};
  List<String> filteredSpecialities = [];
  String searchQuery = '';
  Timer? _debounceTimer;

  final List<String> allSpecialities = [
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
    'Pulmonologist (Lung/Chest Specialist)',
  ];

  @override
  void initState() {
    super.initState();
    filteredSpecialities = allSpecialities;
    if (widget.initialSelection != null) {
      selectedSpecialities = widget.initialSelection!.toSet();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _filterSpecialities(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredSpecialities = allSpecialities;
      } else {
        filteredSpecialities = allSpecialities
            .where(
              (speciality) =>
                  speciality.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  void _onSelectionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (widget.onSelectionChanged != null) {
        widget.onSelectionChanged!(selectedSpecialities.toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
          // Title
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
              child: Text(
                'Select Specialities',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
       
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),

          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 6),
          ),

          // Search bar
          SearchBarWidget(onSearch: _filterSpecialities, hintText: 'Search'),

          // List of specialities
          Expanded(
            child: ListView.builder(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                left: 16,
                right: 16,
                top: 0,
                bottom: 0,
              ),
              itemCount: filteredSpecialities.length,
              itemBuilder: (context, index) {
                final speciality = filteredSpecialities[index];
                final isSelected = selectedSpecialities.contains(speciality);
                return _buildSpecialityItem(speciality, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialityItem(String speciality, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedSpecialities.remove(speciality);
          } else {
            selectedSpecialities.add(speciality);
          }
        });
        _onSelectionChanged();
      },
      child: Padding(
        padding: EdgeInsets.only(top: 16, bottom: 8),
        child: Row(
          children: [
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
                      size: EcliniqTextStyles.getResponsiveIconSize(context, 16),
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                speciality,
                style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              
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

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.hintText = 'Search',
    this.autofocus = false,
  });

  final ValueChanged<String> onSearch;
  final String hintText;
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
    return Container(
      margin: EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xff626060), width: 0.5),
      ),
      child: Row(
        spacing: 10,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SvgPicture.asset(
            EcliniqIcons.magnifierMyDoctor.assetPath,
            height: 24,
            width: 24,
          ),
          Expanded(
            child: TextField(
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
          if (query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                search('');
              },
              child: Icon(Icons.close, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
