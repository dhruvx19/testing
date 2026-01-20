import 'dart:async';
import 'package:ecliniq/ecliniq_api/doctor_service.dart';
import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/doctor_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctors/widgets/doctor_filter_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_hospital_select_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_api/top_doctor_model.dart'
    show LocationData, LocationType;
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart'
    as ecliniq_sheet;
import 'package:ecliniq/ecliniq_utils/bottom_sheets/sort_by_filter_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:ecliniq/ecliniq_core/location/location_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:ecliniq/ecliniq_icons/assets/home/provider/doctor_provider.dart'
    as doctor_provider;

class DoctorsListScreen extends StatefulWidget {
  final FilterDoctorsRequest? initialFilter;

  const DoctorsListScreen({super.key, this.initialFilter});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final DoctorService _doctorService = DoctorService();
  late FilterDoctorsRequest _currentFilter;
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _pressedButtons = {};
  Timer? _debounce;
  String? _selectedSortOption;

  @override
  void initState() {
    super.initState();
    _initializeFilter();
  }

  Future<void> _initializeFilter() async {
    // Hardcoded location values
    const double latitude = 12.9173;
    const double longitude = 77.6377;

    // Use stored/provider location or fallback to defaults
    setState(() {
      _currentFilter =
          widget.initialFilter ??
          FilterDoctorsRequest(
            latitude: 12.9173, // Hardcoded latitude
            longitude: 77.6377, // Hardcoded longitude
          );
    });
    _fetchDoctors();
  }

  void _openSort() {
    ecliniq_sheet.EcliniqBottomSheet.show(
      context: context,
      child: SortByBottomSheet(
        initialSortOption: _selectedSortOption,
        onChanged: (option) {
          setState(() {
            // Handle reset (empty string) - clear sort
            if (option.isEmpty) {
              _selectedSortOption = null;
            } else {
              _selectedSortOption = option;
            }
            _applySort();
          });
        },
      ),
    );
  }

  void _applySort() {
    if (_doctors.isEmpty || _selectedSortOption == null) return;
    final option = _selectedSortOption!;
    int safeCompare<T extends Comparable>(T? a, T? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    double? _computeFee(Doctor d) {
      if (d.fee != null) return d.fee;
      double? minFee;
      for (final h in d.hospitals) {
        final val = h.consultationFee;
        if (val != null) {
          if (minFee == null || val < minFee) minFee = val;
        }
      }
      for (final c in d.clinics) {
        final val = c.consultationFee;
        if (val != null) {
          if (minFee == null || val < minFee) minFee = val;
        }
      }
      return minFee;
    }

    double? _computeDistance(Doctor d) {
      double? minDist;
      for (final h in d.hospitals) {
        final val = h.distance;
        if (val != null) {
          if (minDist == null || val < minDist) minDist = val;
        }
      }
      for (final c in d.clinics) {
        final val = c.distance;
        if (val != null) {
          if (minDist == null || val < minDist) minDist = val;
        }
      }
      return minDist;
    }

    setState(() {
      switch (option) {
        case 'Price: Low - High':
          _doctors.sort((a, b) => safeCompare(_computeFee(a), _computeFee(b)));
          break;
        case 'Price: High - Low':
          _doctors.sort((a, b) => safeCompare(_computeFee(b), _computeFee(a)));
          break;
        case 'Experience - Most Experience first':
          _doctors.sort((a, b) => safeCompare(b.experience, a.experience));
          break;
        case 'Distance - Nearest First':
          _doctors.sort(
            (a, b) => safeCompare(_computeDistance(a), _computeDistance(b)),
          );
          break;
        case 'Order A-Z':
          _doctors.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case 'Order Z-A':
          _doctors.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
        case 'Rating High - low':
          _doctors.sort((a, b) => safeCompare(b.rating, a.rating));
          break;
        case 'Rating Low - High':
          _doctors.sort((a, b) => safeCompare(a.rating, b.rating));
          break;
        case 'Relevance':
        default:
          // no-op
          break;
      }
    });
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _doctorService.getFilteredDoctors(_currentFilter);
      if (response.success && response.data != null) {
        setState(() {
          _doctors = response.data!.doctors;
          _isLoading = false;
        });
        _applySort();
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openFilter() async {
    ecliniq_sheet.EcliniqBottomSheet.show(
      context: context,
      child: DoctorFilterBottomSheet(
        currentFilter: _currentFilter,
        onChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 600), _fetchDoctors);
        },
      ),
    );
  }

  void _bookClinicVisit(Doctor doctor) async {
    if (!doctor.hasLocations) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No locations available for this doctor')),
      );
      return;
    }

    setState(() => _pressedButtons.add(doctor.id));

    try {
      final selectedLocation =
          await ecliniq_sheet.EcliniqBottomSheet.show<LocationData>(
            context: context,
            child: _DoctorLocationBottomSheet(doctor: doctor),
          );

      if (selectedLocation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClinicVisitSlotScreen(
              doctorId: doctor.id,
              hospitalId: selectedLocation.type == LocationType.hospital
                  ? selectedLocation.id
                  : null,
              clinicId: selectedLocation.type == LocationType.clinic
                  ? selectedLocation.id
                  : null,
              doctorName: doctor.name,
              doctorSpecialization: doctor.primarySpecialization,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _pressedButtons.remove(doctor.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors'),
        actions: [
          IconButton(onPressed: _openSort, icon: const Icon(Icons.sort)),
          IconButton(
            onPressed: _openFilter,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: EcliniqLoader())
          : _errorMessage != null
          ? Center(child: Text('Error: $_errorMessage'))
          : _doctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(EcliniqIcons.noDoctor.assetPath),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
                  Text(
                    'No Doctor Match Found',
                    style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
                      color: Color(0xff424242),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchDoctors,
              child: ListView.separated(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
                itemCount: _doctors.length,
                separatorBuilder: (_, __) => SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                ),
                itemBuilder: (context, index) {
                  final doctor = _doctors[index];
                  return _DoctorListItem(
                    doctor: doctor,
                    isPressed: _pressedButtons.contains(doctor.id),
                    onTap: () => EcliniqRouter.push(
                      DoctorDetailScreen(doctorId: doctor.id),
                    ),
                    onBookVisit: () => _bookClinicVisit(doctor),
                  );
                },
              ),
            ),
    );
  }
}

class _DoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final bool isPressed;
  final VoidCallback onTap;
  final VoidCallback onBookVisit;

  const _DoctorListItem({
    required this.doctor,
    required this.isPressed,
    required this.onTap,
    required this.onBookVisit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
        ),
        child: Container(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 16),
            ),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorAvatar(initial: doctor.initial),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
              ),
              _DoctorInfo(doctor: doctor),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
              ),
              _DoctorStats(doctor: doctor),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 20),
              ),
              _BookButton(isPressed: isPressed, onPressed: onBookVisit),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  final String initial;

  const _DoctorAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: EcliniqTextStyles.getResponsiveWidth(context, 80),
          height: EcliniqTextStyles.getResponsiveHeight(context, 80),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              initial,
              style: EcliniqTextStyles.responsiveHeadlineXXLargeBold(context).copyWith(
                color: Color(0xFF2196F3),
              ),
            ),
          ),
        ),
        Positioned(
          top: -2,
          right: 0,
          child: SvgPicture.asset(
            EcliniqIcons.verified.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
          ),
        ),
      ],
    );
  }
}

class _DoctorInfo extends StatelessWidget {
  final Doctor doctor;

  const _DoctorInfo({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          doctor.name,
          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 4),
        ),
        Text(
          doctor.primarySpecialization,
          style: EcliniqTextStyles.responsiveBodyLarge(context).copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveSpacing(context, 2),
        ),
        Text(
          doctor.educationText,
          style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _DoctorStats extends StatelessWidget {
  final Doctor doctor;

  const _DoctorStats({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9E6),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: EcliniqTextStyles.getResponsiveIconSize(context, 18),
                color: Color(0xFFBE8B00),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 2),
              ),
              Text(
                doctor.ratingText,
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Color(0xFFBE8B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
        ),
        Text(
          '●',
          style: EcliniqTextStyles.responsiveBody2xSmallRegular(context).copyWith(
            color: Colors.grey.shade400,
          ),
        ),
        SizedBox(
          width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
        ),
        Expanded(
          child: Text(
            doctor.experienceText,
            style: EcliniqTextStyles.responsiveBodyMedium(context).copyWith(
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BookButton extends StatelessWidget {
  final bool isPressed;
  final VoidCallback onPressed;

  const _BookButton({required this.isPressed, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPressed
              ? const Color(0xFF0E4395)
              : const Color(0xFF2372EC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
            ),
          ),
          elevation: 0,
        ),
        child: Text(
          'Book Clinic Visit',
          style: EcliniqTextStyles.responsiveHeadlineMedium(context).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _DoctorLocationBottomSheet extends StatefulWidget {
  final Doctor doctor;

  const _DoctorLocationBottomSheet({required this.doctor});

  @override
  State<_DoctorLocationBottomSheet> createState() =>
      _DoctorLocationBottomSheetState();
}

class _DoctorLocationBottomSheetState
    extends State<_DoctorLocationBottomSheet> {
  String? _selectedLocationId;
  late final List<LocationData> _locations;

  @override
  void initState() {
    super.initState();
    _locations = _getLocations(widget.doctor);
    _selectedLocationId = null;
  }

  List<LocationData> _getLocations(Doctor doctor) {
    final List<LocationData> locs = [];

    for (var hospital in doctor.hospitals) {
      locs.add(
        LocationData(
          id: hospital.id,
          name: hospital.name,
          hours: 'Contact for timings',
          area: '${hospital.city ?? ''}, ${hospital.state ?? ''}',
          distance: '${hospital.distance?.toStringAsFixed(1) ?? '0.0'} Km',
          type: LocationType.hospital,
          latitude: hospital.latitude ?? 0.0,
          longitude: hospital.longitude ?? 0.0,
        ),
      );
    }

    for (var clinic in doctor.clinics) {
      locs.add(
        LocationData(
          id: clinic.id,
          name: clinic.name,
          hours: 'Contact for timings',
          area: '${clinic.city ?? ''}, ${clinic.state ?? ''}',
          distance: '${clinic.distance?.toStringAsFixed(1) ?? '0.0'} Km',
          type: LocationType.clinic,
          latitude: clinic.latitude ?? 0.0,
          longitude: clinic.longitude ?? 0.0,
        ),
      );
    }

    return locs;
  }

  void _onLocationTap(String locationId) {
    final selected = _locations.firstWhere((loc) => loc.id == locationId);
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Location',
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildDescription(),
                  style:  EcliniqTextStyles.responsiveButtonXLarge(context).copyWith(
               
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF626060),
                  ),
                ),
                const SizedBox(height: 20),
                if (_locations.isEmpty)
                  const Center(child: Text('No locations available'))
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
            color: isSelected ? const Color(0xFF96BFFF) : Colors.white,
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
          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
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
             Text(
              '•',
              style: EcliniqTextStyles.responsiveBodyXSmall(context).copyWith( color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 4),
            Text(
              location.distance,
              style:  EcliniqTextStyles.responsiveBodyXSmall(context).copyWith(
             
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
        SvgPicture.asset(
          icon,
          width: EcliniqTextStyles.getResponsiveIconSize(context, 20),
          height: EcliniqTextStyles.getResponsiveIconSize(context, 20),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: EcliniqTextStyles.responsiveBodySmall(context).copyWith(
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
