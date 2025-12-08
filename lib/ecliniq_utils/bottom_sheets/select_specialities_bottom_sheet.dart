import 'dart:async';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';

class SelectSpecialitiesBottomSheet extends StatefulWidget {
  const SelectSpecialitiesBottomSheet({super.key});

  @override
  State<SelectSpecialitiesBottomSheet> createState() =>
      _SelectSpecialitiesBottomSheetState();
}

class _SelectSpecialitiesBottomSheetState
    extends State<SelectSpecialitiesBottomSheet> {
  Set<String> selectedSpecialities = {};
  List<String> filteredSpecialities = [];
  String searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Specialities',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search bar
          SearchBarWidget(onSearch: _filterSpecialities, hintText: 'Search'),

          const SizedBox(height: 16),

          // List of specialities
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredSpecialities.length,
              itemBuilder: (context, index) {
                final speciality = filteredSpecialities[index];
                final isSelected = selectedSpecialities.contains(speciality);
                return _buildSpecialityItem(speciality, isSelected);
              },
            ),
          ),
          // Apply button
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedSpecialities.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context, selectedSpecialities.toList());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2372EC),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Apply (${selectedSpecialities.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
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
    final outlinedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Color(0xffD6D6D6)),
      ),
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
              ? IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                  onPressed: () {
                    setState(() => query = '');
                    _controller.clear();
                    widget.onSearch('');
                  },
                )
              : null,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Image.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: 20,
              height: 20,
            ),
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Color(0xffD6D6D6),
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
        cursorColor: Color(0xff2372EC),
        cursorWidth: 1.5,
        cursorHeight: 20,
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    );
  }
}
