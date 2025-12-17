import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_hospital_list.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

class QuickActionsWidget extends StatelessWidget {
  final bool showShimmer;

  const QuickActionsWidget({super.key, this.showShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return _buildShimmer();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final itemWidth = isSmallScreen ? 160.0 : 192.0;
    final itemHeight = isSmallScreen ? 100.0 : 105.0;
 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w600,
                color: Color(0xff424242),
              ),
            ),
          ],
        ),

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  width: itemWidth,
                  height: itemHeight,
                  assetPath: EcliniqIcons.quick1.assetPath,
                  title: 'Consult Doctors',
                  onTap: () => EcliniqRouter.push(SpecialityDoctorsList()),
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                child: _buildQuickActionItem(
                  context,
                  width: itemWidth,
                  height: itemHeight,
                  assetPath: EcliniqIcons.hospitalBuilding.assetPath,
                  title: 'Visit Hospitals',
                  onTap: () => EcliniqRouter.push(SpecialityHospitalList()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context, {
    required double width,
    required double height,
    required String assetPath,
    required String title,
    required VoidCallback onTap,
  }) {
 

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(26.0),
                  border: Border.all(color: Color(0xFFE4EFFF), width: 0.5),
                ),
                child: Center(
                  child: SvgPicture.asset(assetPath, width: 32.0, height: 32.0),
                ),
              ),
              SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: EcliniqTextStyles.titleXLarge.copyWith(
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 24,
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(child: _buildCardShimmer()),
              const SizedBox(width: 10),
              Expanded(child: _buildCardShimmer()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 105,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }
}
