import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/top_doctor/model/top_doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LocationBottomSheet extends StatefulWidget {
  final Doctor doctor;

  const LocationBottomSheet({super.key, required this.doctor});

  @override
  State<LocationBottomSheet> createState() => _LocationBottomSheetState();
}

class _LocationBottomSheetState extends State<LocationBottomSheet> {
  String? _selectedLocationId;
  late final List<LocationData> _locations;

  @override
  void initState() {
    super.initState();
    _locations = widget.doctor.locations;
    // Keep default state unselected
    _selectedLocationId = null;
  }

  void _onLocationTap(String locationId) {
    final selected = _locations.firstWhere(
      (loc) => loc.id == locationId,
    );
    // Automatically navigate when location is selected
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Select Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  _buildDescription(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF626060),
                  ),
                ),
                const SizedBox(height: 20),

                // Location options
                if (_locations.isEmpty)
                  const _EmptyLocationState()
                else
                  ..._locations.map(
                    (location) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LocationCard(
                        location: location,
                        isSelected: _selectedLocationId == location.id,
                        onTap: () => _onLocationTap(location.id),
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

  String _buildDescription() {
    if (_locations.isEmpty) {
      return 'No locations available for ${widget.doctor.name}.';
    } else if (_locations.length == 1) {
      return '${widget.doctor.name} is available at this location.';
    } else {
      return '${widget.doctor.name} is available at multiple locations. Select where you want to book an appointment.';
    }
  }
}

class _LocationCard extends StatelessWidget {
  final LocationData location;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF96BFFF)
                :  Colors.white,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _RadioButton(isSelected: isSelected),
            const SizedBox(width: 12),
            _LocationIcon(type: location.type),
            const SizedBox(width: 12),
            Expanded(child: _LocationDetails(location: location)),
          ],
        ),
      ),
    );
  }
}

class _RadioButton extends StatelessWidget {
  final bool isSelected;

  const _RadioButton({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
          width: 2,
        ),
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFF2563EB) : Colors.white,
      ),
      child: isSelected
          ? Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

class _LocationIcon extends StatelessWidget {
  final LocationType type;

  const _LocationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:  const Color(0xFFFFF7F0) ,
        borderRadius: BorderRadius.circular(54),
        border: Border.all(
          color: const Color(0xFFEC7600) ,
          width: 0.5,
        ),
      ),
      child: Center(
        child: SvgPicture.asset(
          EcliniqIcons.hospitalorange.assetPath,
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}

class _LocationDetails extends StatelessWidget {
  final LocationData location;

  const _LocationDetails({required this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          location.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 6),
        _IconTextRow(
          icon: EcliniqIcons.appointmentRemindar.assetPath,
          text: location.hours,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _IconTextRow(
                icon: EcliniqIcons.map.assetPath,
                text: location.area,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '•',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 4),
            Text(
              location.distance,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IconTextRow extends StatelessWidget {
  final String icon;
  final String text;

  const _IconTextRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: 20, height: 20),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF626060),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyLocationState extends StatelessWidget {
  const _EmptyLocationState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No locations available',
          style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
        ),
      ),
    );
  }
}
