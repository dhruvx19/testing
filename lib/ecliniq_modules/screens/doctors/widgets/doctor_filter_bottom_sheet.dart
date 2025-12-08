import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/input/input.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';

class DoctorFilterBottomSheet extends StatefulWidget {
  final FilterDoctorsRequest currentFilter;

  const DoctorFilterBottomSheet({
    super.key,
    required this.currentFilter,
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
                style: EcliniqTextStyles.headlineMedium,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
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
                  EcliniqInput(
                    controller: _cityController,
                    hintText: 'Enter City',
                    label: 'City',
                  ),
                  const SizedBox(height: 12),
                  EcliniqInput(
                    controller: _distanceController,
                    hintText: 'Distance (km)',
                    label: 'Distance',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Consultation'),
                  const SizedBox(height: 8),
                  EcliniqInput(
                    controller: _specialityController,
                    hintText: 'e.g. Cardiology, Dermatology',
                    label: 'Speciality (comma separated)',
                  ),
                  const SizedBox(height: 12),
                  EcliniqInput(
                    controller: _experienceController,
                    hintText: 'e.g. any, 5',
                    label: 'Work Experience',
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
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                  const SizedBox(height: 12),
                  EcliniqInput(
                    controller: _languageController,
                    hintText: 'e.g. English, Hindi',
                    label: 'Languages (comma separated)',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EcliniqButton(
                  type: EcliniqButtonType.brandSecondary,
                  label: 'Clear',
                  onPressed: () {
                    Navigator.pop(context, FilterDoctorsRequest(
                      latitude: widget.currentFilter.latitude,
                      longitude: widget.currentFilter.longitude,
                    ));
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: EcliniqButton(
                  type: EcliniqButtonType.brandPrimary,
                  label: 'Apply',
                  onPressed: _applyFilters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF424242),
      ),
    );
  }

  void _applyFilters() {
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

    Navigator.pop(context, newFilter);
  }
}
