import 'package:ecliniq/ecliniq_api/storage_service.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/booking/clinic_visit_slot_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/doctor_details.dart';
import 'package:ecliniq/ecliniq_api/top_doctor_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/doctor_details/widgets/doctor_hospital_select_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/button/button.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/widgets.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class TopDoctorsWidget extends StatefulWidget {
  final bool showShimmer;
  final List<Doctor>? doctors;

  const TopDoctorsWidget({super.key, this.showShimmer = false, this.doctors});

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
          hospitalId: location.type == LocationType.hospital
              ? location.id
              : null,
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
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
        _buildDoctorsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                  bottomRight: Radius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
            ),
            Expanded(
              child: Text(
                'Top Doctors',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                EcliniqRouter.push(SpecialityDoctorsList());
              },
              style: TextButton.styleFrom(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 8.0,
                  vertical: 0.0,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          color: Color(0xFF2372EC),
                          fontWeight: FontWeight.w400,
                        ),
                  ),

                  SvgPicture.asset(
                    EcliniqIcons.arrowRightBlue.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(
                      context,
                      24.0,
                    ),
                    height: EcliniqTextStyles.getResponsiveIconSize(
                      context,
                      24.0,
                    ),
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF2372EC),
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 20.0,
            ),
            child: Text(
              'Near you',
              style: EcliniqTextStyles.responsiveLabelSmall(
                context,
              ).copyWith(color: Color(0xFF8E8E8E), fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsList() {
    if (widget.doctors == null || widget.doctors!.isEmpty) {
      return const _EmptyDoctorsState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 16.0,
        vertical: 0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.doctors!.asMap().entries.map((entry) {
            final index = entry.key;
            final doctor = entry.value;
            return Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                right: index < widget.doctors!.length - 1
                    ? EcliniqTextStyles.getResponsiveSpacing(context, 16.0)
                    : 0,
              ),
              child: _DoctorCard(
                doctor: doctor,
                isPressed: _pressedButtons.contains(doctor.id),
                onTap: () =>
                    EcliniqRouter.push(DoctorDetailScreen(doctorId: doctor.id)),
                onBookVisit: () => _bookClinicVisit(doctor),
              ),
            );
          }).toList(),
        ),
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
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
        ),
        child: Container(
          width: EcliniqTextStyles.getResponsiveWidth(context, 300.0),
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
            ),
            border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorAvatar(doctor: doctor),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
              ),
              _DoctorInfo(doctor: doctor),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
              ),
              _DoctorStats(doctor: doctor),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
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
  final Doctor doctor;
  final StorageService _storageService = StorageService();

   _DoctorAvatar({required this.doctor});

  @override
  Widget build(BuildContext context) {
    
    return Stack(
      children: [
        Container(
          width: EcliniqTextStyles.getResponsiveSize(context, 80.0),
          height: EcliniqTextStyles.getResponsiveSize(context, 80.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xff96BFFF), width: 0.5),
          ),
          child: FutureBuilder<String?>(
            
            future: doctor.getProfilePhotoUrl(_storageService),
            builder: (context, snapshot) {
              final imageUrl = snapshot.data;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                return ClipOval(
                  child: Image.network(
                    imageUrl,
                    width: EcliniqTextStyles.getResponsiveSize(context, 80.0),
                    height: EcliniqTextStyles.getResponsiveSize(context, 80.0),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          doctor.initial,
                          style: EcliniqTextStyles.responsiveTitleInitial(
                            context,
                          ).copyWith(color: Color(0xFF2372EC)),
                        ),
                      );
                    },
                  ),
                );
              }
              return Center(
                child: Text(
                  doctor.initial,
                  style: EcliniqTextStyles.responsiveTitleInitial(
                    context,
                  ).copyWith(color: Color(0xFF2372EC)),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: -2,
          right: 0,
          child: SvgPicture.asset(
            EcliniqIcons.verified.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
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
          style: EcliniqTextStyles.responsiveHeadlineLarge(
            context,
          ).copyWith(color: Color(0xff424242), fontWeight: FontWeight.w600),
        ),

        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
        Text(
          doctor.primarySpecialization,
          style: EcliniqTextStyles.responsiveTitleXLarge(
            context,
          ).copyWith(color: Color(0xff424242)),
        ),
        if (doctor.educationText.isNotEmpty) ...[
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
          ),
          Text(
            doctor.educationText,
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ],
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
            horizontal: 8.0,
            vertical: 4.0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9E6),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 6.0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                EcliniqIcons.star.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 18.0),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 18.0),
              ),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 2.0),
              ),
              Text(
                doctor.ratingText,
                style: EcliniqTextStyles.responsiveTitleXLarge(context)
                    .copyWith(
                      color: Color(0xFFBE8B00),
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
        Container(
          width: EcliniqTextStyles.getResponsiveSize(context, 6.0),
          height: EcliniqTextStyles.getResponsiveSize(context, 6.0),
          decoration: BoxDecoration(
            color: const Color(0xFF8E8E8E),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
        FittedBox(
          child: Text(
            doctor.experienceText,
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
        ),
        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
        Container(
          width: EcliniqTextStyles.getResponsiveSize(context, 6.0),
          height: EcliniqTextStyles.getResponsiveSize(context, 6.0),
          decoration: BoxDecoration(
            color: const Color(0xFF8E8E8E),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
        Expanded(
          child: Text(
            '₹500',
            style: EcliniqTextStyles.responsiveTitleXLarge(
              context,
            ).copyWith(color: Color(0xff424242)),
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
    return Container(
      width: double.infinity,
      height: EcliniqTextStyles.getResponsiveButtonHeight(
        context,
        baseHeight: 52.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D2372EC),
            offset: Offset(2, 2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPressed
              ? const Color(0xFF0E4395)
              : EcliniqButtonType.brandPrimary.backgroundColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
            ),
          ),
          elevation: 0,
        ),
        child: Text(
          'Book Clinic Visit',
          style: EcliniqTextStyles.responsiveHeadlineMedium(
            context,
          ).copyWith(color: Colors.white),
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
      height: EcliniqTextStyles.getResponsiveHeight(context, 320.0),
      child: Center(
        child: Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
          child: Text(
            'No doctors available',
            style: EcliniqTextStyles.responsiveBodySmall(
              context,
            ).copyWith(color: Colors.grey.shade600),
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
              width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                  bottomRight: Radius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: EcliniqTextStyles.getResponsiveSize(
                        context,
                        20.0,
                      ),
                      width: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        120.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            4.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: EcliniqTextStyles.getResponsiveSize(
                        context,
                        16.0,
                      ),
                      width: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        80.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(
                            context,
                            4.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 20.0)),
        SizedBox(
          height: EcliniqTextStyles.getResponsiveHeight(context, 320.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 12.0,
              vertical: 0,
            ),
            separatorBuilder: (_, __) => SizedBox(
              width: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            ),
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
        width: EcliniqTextStyles.getResponsiveWidth(context, 300.0),
        padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
          ),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: EcliniqTextStyles.getResponsiveSize(context, 80.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 80.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            ),
            Container(
              height: EcliniqTextStyles.getResponsiveSize(context, 18.0),
              width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                ),
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
            ),
            Container(
              height: EcliniqTextStyles.getResponsiveSize(context, 14.0),
              width: EcliniqTextStyles.getResponsiveWidth(context, 120.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                ),
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
            ),
            Container(
              height: EcliniqTextStyles.getResponsiveSize(context, 14.0),
              width: EcliniqTextStyles.getResponsiveWidth(context, 180.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                ),
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            ),
            Container(
              height: EcliniqTextStyles.getResponsiveSize(context, 16.0),
              width: EcliniqTextStyles.getResponsiveWidth(context, 100.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                ),
              ),
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 20.0),
            ),
            Container(
              height: EcliniqTextStyles.getResponsiveButtonHeight(
                context,
                baseHeight: 52.0,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
