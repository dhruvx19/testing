import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_hospital_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
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
      return _buildShimmer( context);
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
              width: EcliniqTextStyles.getResponsiveSize(context, 8.0),
              height: EcliniqTextStyles.getResponsiveSize(context, 24.0),
              decoration: BoxDecoration(
                color: Color(0xFF96BFFF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                  bottomRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                ),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
            EcliniqText(
              'Quick Actions',
              style: EcliniqTextStyles.responsiveHeadlineLargeBold(context).copyWith(
                fontWeight: FontWeight.w600,
                color: Color(0xff424242),
              ),
            ),
          ],
        ),

        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
            context,
            left: 16.0,
            right: 16.0,
            bottom: 16.0,
            top: 12.0,
          ),
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
              SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 24.0)),
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
        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0)),
        child: Container(
          width: width,
          height: height,
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 6.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0)),
            border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: EcliniqTextStyles.getResponsiveWidth(context, 52),
                height: EcliniqTextStyles.getResponsiveHeight(context, 52),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 26.0),
                  ),
                  border: Border.all(color: Color(0xFFE4EFFF), width: 0.5),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 2),
              ),
              EcliniqText(
                title,
                textAlign: TextAlign.center,
                style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
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
                  topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                  bottomRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                ),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),

        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 12.0),
          child: Row(
            children: [
              Expanded(child: _buildCardShimmer(context)),
              SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 10.0)),
              Expanded(child: _buildCardShimmer(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: EcliniqTextStyles.getResponsiveHeight(context, 105.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0)),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }
}
