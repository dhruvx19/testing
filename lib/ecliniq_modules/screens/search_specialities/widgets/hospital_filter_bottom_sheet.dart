import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';

class HospitalFilterParams {
  final String? city;
  final String? state;
  final String? type;
  final double? maxDistance;
  final int? minDoctors;
  final int? minBeds;

  HospitalFilterParams({
    this.city,
    this.state,
    this.type,
    this.maxDistance,
    this.minDoctors,
    this.minBeds,
  });

  bool get hasFilters =>
      city != null ||
      state != null ||
      type != null ||
      maxDistance != null ||
      minDoctors != null ||
      minBeds != null;

  HospitalFilterParams copyWith({
    String? city,
    String? state,
    String? type,
    double? maxDistance,
    int? minDoctors,
    int? minBeds,
  }) {
    return HospitalFilterParams(
      city: city ?? this.city,
      state: state ?? this.state,
      type: type ?? this.type,
      maxDistance: maxDistance ?? this.maxDistance,
      minDoctors: minDoctors ?? this.minDoctors,
      minBeds: minBeds ?? this.minBeds,
    );
  }
}

class HospitalFilterBottomSheet extends StatefulWidget {
  final HospitalFilterParams? currentFilter;
  final ValueChanged<HospitalFilterParams> onFilterChanged;

  const HospitalFilterBottomSheet({
    super.key,
    this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<HospitalFilterBottomSheet> createState() =>
      _HospitalFilterBottomSheetState();
}

class _HospitalFilterBottomSheetState
    extends State<HospitalFilterBottomSheet> {
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _distanceController;
  late TextEditingController _doctorsController;
  late TextEditingController _bedsController;
  String? _selectedType;

  final List<String> _hospitalTypes = [
    'Multispeciality',
    'Super Speciality',
    'Eye Care',
    'Dental Care',
    'Orthopaedic',
    'Cardiac Care',
    'Maternity',
    'Children',
    'Cancer Care',
  ];

  @override
  void initState() {
    super.initState();
    final filter = widget.currentFilter;
    _cityController = TextEditingController(text: filter?.city ?? '');
    _stateController = TextEditingController(text: filter?.state ?? '');
    _distanceController = TextEditingController(
        text: filter?.maxDistance?.toString() ?? '');
    _doctorsController = TextEditingController(
        text: filter?.minDoctors?.toString() ?? '');
    _bedsController = TextEditingController(
        text: filter?.minBeds?.toString() ?? '');
    _selectedType = filter?.type;
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    _distanceController.dispose();
    _doctorsController.dispose();
    _bedsController.dispose();
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
                'Filter Hospitals',
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
                    controller: _stateController,
                    decoration: const InputDecoration(
                      hintText: 'Enter State',
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distanceController,
                    decoration: const InputDecoration(
                      hintText: 'Maximum Distance (km)',
                      labelText: 'Max Distance',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Hospital Type'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Hospital Type',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Types'),
                      ),
                      ..._hospitalTypes.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedType = val);
                      _applyAndEmit();
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Capacity'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _doctorsController,
                    decoration: const InputDecoration(
                      hintText: 'Minimum number of doctors',
                      labelText: 'Min Doctors',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bedsController,
                    decoration: const InputDecoration(
                      hintText: 'Minimum number of beds',
                      labelText: 'Min Beds',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _applyAndEmit(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyAndEmit();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2372EC),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF424242),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _cityController.clear();
      _stateController.clear();
      _distanceController.clear();
      _doctorsController.clear();
      _bedsController.clear();
      _selectedType = null;
    });
    _applyAndEmit();
  }

  void _applyAndEmit() {
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final distance = double.tryParse(_distanceController.text.trim());
    final doctors = int.tryParse(_doctorsController.text.trim());
    final beds = int.tryParse(_bedsController.text.trim());

    final filter = HospitalFilterParams(
      city: city.isEmpty ? null : city,
      state: state.isEmpty ? null : state,
      type: _selectedType,
      maxDistance: distance,
      minDoctors: doctors,
      minBeds: beds,
    );

    widget.onFilterChanged(filter);
  }
}

