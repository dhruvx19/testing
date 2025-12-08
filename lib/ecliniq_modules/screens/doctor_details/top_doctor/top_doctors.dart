
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/doctor_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/top_doctor/model/top_doctor_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_hospital_select_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctors/doctors_list.dart';
import 'package:shimmer/shimmer.dart';

class TopDoctorsWidget extends StatefulWidget {
  final bool showShimmer;
  final List<Doctor>? doctors;

  const TopDoctorsWidget({
    super.key,
    this.showShimmer = false,
    this.doctors,
  });

  @override
  State<TopDoctorsWidget> createState() => _TopDoctorsWidgetState();
}

class _TopDoctorsWidgetState extends State<TopDoctorsWidget> {
  final Set<String> _pressedButtons = {};

  void _bookClinicVisit(Doctor doctor) async {
    if (!doctor.hasLocations) {
      _showNoLocationDialog();
      return;
    }

    setState(() => _pressedButtons.add(doctor.id));

    try {
      final selectedLocation = await EcliniqBottomSheet.show<LocationData>(
        context: context,
        child: LocationBottomSheet(doctor: doctor),
      );

      if (selectedLocation != null && mounted) {
        // Handle the booking with selected location
        _handleBooking(doctor, selectedLocation);
      }
    } finally {
      if (mounted) {
        setState(() => _pressedButtons.remove(doctor.id));
      }
    }
  }

  void _handleBooking(Doctor doctor, LocationData location) {
    // Navigate to clinic visit slot screen
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicVisitSlotScreen(
          doctorId: doctor.id,
          hospitalId: location.type == LocationType.hospital ? location.id : null,
          clinicId: location.type == LocationType.clinic ? location.id : null,
          doctorName: doctor.name,
          doctorSpecialization: doctor.primarySpecialization,
        ),
      ),
    );
  }

  void _showNoLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Location Available'),
        content: const Text(
          'This doctor does not have any available locations at the moment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showShimmer) {
      return _DoctorListShimmer();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        _buildDoctorsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF96BFFF),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Doctors',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'At your location',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E8E),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            EcliniqRouter.push(const DoctorsListScreen());
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF2372EC),
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF2372EC),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsList() {
    if (widget.doctors == null || widget.doctors!.isEmpty) {
      return const _EmptyDoctorsState();
    }

    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: widget.doctors!.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final doctor = widget.doctors![index];
          return _DoctorCard(
            doctor: doctor,
            isPressed: _pressedButtons.contains(doctor.id),
            onTap: () => EcliniqRouter.push(
              DoctorDetailScreen(doctorId: doctor.id),
            ),
            onBookVisit: () => _bookClinicVisit(doctor),
          );
        },
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final bool isPressed;
  final VoidCallback onTap;
  final VoidCallback onBookVisit;

  const _DoctorCard({
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              const SizedBox(height: 16),
              _DoctorInfo(doctor: doctor),
              const SizedBox(height: 12),
              _DoctorStats(doctor: doctor),
              const SizedBox(height: 20),
              _BookButton(
                isPressed: isPressed,
                onPressed: onBookVisit,
              ),
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
          width: 80,
          height: 80,
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
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
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
            width: 24,
            height: 24,
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
          style: EcliniqTextStyles.headlineMedium.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          doctor.primarySpecialization,
          style: EcliniqTextStyles.bodyLarge.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          doctor.educationText,
          style: EcliniqTextStyles.bodyMedium.copyWith(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9E6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 18, color: Color(0xFFBE8B00)),
              const SizedBox(width: 2),
              Text(
                doctor.ratingText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFBE8B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '●',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            doctor.experienceText,
            style: EcliniqTextStyles.bodyMedium.copyWith(
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

  const _BookButton({
    required this.isPressed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPressed
              ? const Color(0xFF0E4395)
              : EcliniqButtonType.brandPrimary.backgroundColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
        ),
        child: Text(
          'Book Clinic Visit',
          style: EcliniqTextStyles.headlineMedium.copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _EmptyDoctorsState extends StatelessWidget {
  const _EmptyDoctorsState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No doctors available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

class _DoctorListShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 20,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 320,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: 3,
            itemBuilder: (_, __) => const _DoctorCardShimmer(),
          ),
        ),
      ],
    );
  }
}

class _DoctorCardShimmer extends StatelessWidget {
  const _DoctorCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 18,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}