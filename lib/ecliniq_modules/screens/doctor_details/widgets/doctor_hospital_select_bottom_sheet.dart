import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_api/top_doctor_model.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
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
    final selected = _locations.firstWhere((loc) => loc.id == locationId);
    // Automatically navigate when location is selected
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
               Text(
                'Select Location',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 2),

              // Description
              Text(
                _buildDescription(),
                style:  EcliniqTextStyles.responsiveButtonXLargeProminent(context).copyWith(
               
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF626060),
                ),
              ),
              const SizedBox(height: 10),

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFF) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF96BFFF) : Colors.white,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _RadioButton(isSelected: isSelected),
            const SizedBox(width: 8),
            _LocationIcon(type: location.type),
            const SizedBox(width: 8),
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
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF8E8E8E),
          width: 1,
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
        color: const Color(0xFFFFF7F0),
        borderRadius: BorderRadius.circular(54),
        border: Border.all(color: const Color(0xFFEC7600), width: 0.5),
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
          style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
        
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
                icon: EcliniqIcons.mapPointBlack.assetPath,
                text: location.area,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFFB8B8B8),
                  width: 0.5,
                ),
              ),
              child: Text(
                location.distance,
                style:  EcliniqTextStyles.responsiveBodySmall(context).copyWith(
             
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF424242),
                ),
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
        SvgPicture.asset(
          icon,
          width: EcliniqTextStyles.getResponsiveIconSize(context, 20),
          height: EcliniqTextStyles.getResponsiveIconSize(context, 20),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            style:  EcliniqTextStyles.responsiveBodySmall(context).copyWith(
           
              fontWeight: FontWeight.w400,
              color: Color(0xFF626060),
           
            ),
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
    return  Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No locations available',
          style: EcliniqTextStyles.responsiveBodySmall(context).copyWith( color: Color(0xFF9E9E9E)),
        ),
      ),
    );
  }
}
