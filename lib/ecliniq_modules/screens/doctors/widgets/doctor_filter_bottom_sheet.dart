import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';

class DoctorFilterBottomSheet extends StatefulWidget {
  final FilterDoctorsRequest currentFilter;
  final ValueChanged<FilterDoctorsRequest> onChanged;

  const DoctorFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onChanged,
  });

  @override
  State<DoctorFilterBottomSheet> createState() =>
      _DoctorFilterBottomSheetState();
}

class _DoctorFilterBottomSheetState extends State<DoctorFilterBottomSheet> {
  late TextEditingController _cityController;
  late TextEditingController _distanceController;
  late TextEditingController _experienceController;
  late TextEditingController _specialityController;
  late TextEditingController _languageController;
  String? _selectedGender;
  String? _selectedAvailability;
  DateTime? _selectedDate;

  final List<String> _genders = ['MALE', 'FEMALE', 'OTHER'];
  final List<String> _availabilities = ['TODAY', 'TOMORROW', 'DATE'];

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.currentFilter.city);
    _distanceController = TextEditingController(
        text: widget.currentFilter.distance?.toString() ?? '');
    _experienceController =
        TextEditingController(text: widget.currentFilter.workExperience);
    _specialityController = TextEditingController(
        text: widget.currentFilter.speciality?.join(', '));
    _languageController =
        TextEditingController(text: widget.currentFilter.languages?.join(', '));
    _selectedGender = widget.currentFilter.gender;
    _selectedAvailability = widget.currentFilter.availability;
    if (widget.currentFilter.date != null) {
      try {
        _selectedDate = DateTime.parse(widget.currentFilter.date!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    _distanceController.dispose();
    _experienceController.dispose();
    _specialityController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Doctors',
                style: EcliniqTextStyles.responsiveHeadlineMedium(context),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _resetFilters,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Reset',
                        style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                            .copyWith(
                              fontWeight: FontWeight.w400,
                              color: Color(0xff2372EC),
                            ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      hintText: 'Enter City',
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distanceController,
                    decoration: const InputDecoration(
                      hintText: 'Distance (km)',
                      labelText: 'Distance',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Consultation'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _specialityController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Cardiology, Dermatology',
                      labelText: 'Speciality (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _experienceController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. any, 5',
                      labelText: 'Work Experience',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Preferences'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: _genders
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedGender = val);
                      _applyAndEmit();
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _languageController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. English, Hindi',
                      labelText: 'Languages (comma separated)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Availability'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _availabilities.map((avail) {
                      final isSelected = _selectedAvailability == avail;
                      return ChoiceChip(
                        label: Text(avail),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedAvailability = selected ? avail : null;
                          });
                          _applyAndEmit();
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedAvailability == 'DATE') ...[
                    const SizedBox(height: 12),
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
                          _applyAndEmit();
                        }
                      },
                      child: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : _selectedDate!.toIso8601String().split('T')[0],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
     
        fontWeight: FontWeight.w600,
        color: Color(0xFF424242),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _cityController.clear();
      _distanceController.clear();
      _experienceController.clear();
      _specialityController.clear();
      _languageController.clear();
      _selectedGender = null;
      _selectedAvailability = null;
      _selectedDate = null;
    });
    // Emit empty filter state to clear active filters in parent
    final emptyFilter = FilterDoctorsRequest(
      latitude: widget.currentFilter.latitude,
      longitude: widget.currentFilter.longitude,
      city: null,
      distance: null,
      workExperience: null,
      speciality: null,
      languages: null,
      gender: null,
      availability: null,
      date: null,
      page: 1,
    );
    widget.onChanged(emptyFilter);
  }

  void _applyAndEmit() {
    final city = _cityController.text.trim();
    final distance = double.tryParse(_distanceController.text.trim());
    final experience = _experienceController.text.trim();
    final specialities = _specialityController.text.isNotEmpty
        ? _specialityController.text.split(',').map((e) => e.trim()).toList()
        : null;
    final languages = _languageController.text.isNotEmpty
        ? _languageController.text.split(',').map((e) => e.trim()).toList()
        : null;
    
    final dateStr = _selectedDate?.toIso8601String().split('T')[0];

    final newFilter = FilterDoctorsRequest(
      latitude: widget.currentFilter.latitude,
      longitude: widget.currentFilter.longitude,
      city: city.isEmpty ? null : city,
      distance: distance,
      workExperience: experience.isEmpty ? null : experience,
      speciality: specialities,
      languages: languages,
      gender: _selectedGender,
      availability: _selectedAvailability,
      date: _selectedAvailability == 'DATE' ? dateStr : null,
      page: 1, // Reset to page 1 on new filter
    );

    widget.onChanged(newFilter);
  }
}
