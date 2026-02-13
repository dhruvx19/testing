import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DoctorLocationOption {
  final String id;
  final String name;
  final String address;
  final String type; 
  final String? distance;
  final String? hours;

  DoctorLocationOption({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    this.distance,
    this.hours,
  });
}

class DoctorLocationChangeSheet extends StatefulWidget {
  final String doctorName;
  final List<DoctorLocationOption> locations;
  final String? selectedLocationId;

  const DoctorLocationChangeSheet({
    super.key,
    required this.doctorName,
    required this.locations,
    this.selectedLocationId,
  });

  @override
  State<DoctorLocationChangeSheet> createState() =>
      _DoctorLocationChangeSheetState();
}

class _DoctorLocationChangeSheetState extends State<DoctorLocationChangeSheet> {
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.selectedLocationId;
  }

  void _onLocationTap(String locationId) {
    setState(() {
      _selectedLocationId = locationId;
    });
    
    final selected = widget.locations.firstWhere((loc) => loc.id == locationId);
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
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Switch Profile',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Text(
                  _buildDescription(),
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF626060),
                  ),
                ),
                const SizedBox(height: 22),

                
                if (widget.locations.isEmpty)
                  const _EmptyLocationState()
                else
                  ...widget.locations.map(
                    (location) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
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
    if (widget.locations.isEmpty) {
      return 'No locations available for ${widget.doctorName}.';
    } else if (widget.locations.length == 1) {
      return '${widget.doctorName} is available at this location.';
    } else {
      return '${widget.doctorName} is available at multiple location select for which location you want see profile';
    }
  }
}

class _LocationCard extends StatelessWidget {
  final DoctorLocationOption location;
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
            color: isSelected ? const Color(0xFF96BFFF) : Colors.grey[200]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            _RadioButton(isSelected: isSelected),
            const SizedBox(width: 12),
            _LocationIcon(),
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
  final DoctorLocationOption location;

  const _LocationDetails({required this.location});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          location.name,
          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(
              EcliniqIcons.mapPointBlack.assetPath,
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                location.address,
                style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF626060),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (location.distance != null) ...[
              SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
              Container(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0xffF9F9F9),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                  border: Border.all(color: Color(0xffB8B8B8), width: 0.5),
                ),
                child: Text(
                  '${location.distance} Km',
                  style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                    color: Color(0xff424242),
                  ),
                ),
              ),
            ],
          ],
          
        ),
      ],
    );
  }
}

class _EmptyLocationState extends StatelessWidget {
  const _EmptyLocationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No locations available',
          style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(color: Color(0xFF9E9E9E)),
        ),
      ),
    );
  }
}
