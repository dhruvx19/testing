import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/search_specialities_page.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/speciality_doctors_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class MostSearchedSpecialities extends StatelessWidget {
  final bool showShimmer;

  const MostSearchedSpecialities({super.key, this.showShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return _buildShimmer(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;
        final cardSpacing = isSmallScreen ? 8.0 : 18.0;
        final cardHeight = isSmallScreen ? 85.0 : 100.0;
        final cardWidth = (screenWidth - (isSmallScreen ? 40 : 48)) / 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
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
                          topRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                          bottomRight: Radius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                        ),
                      ),
                    ),
                    SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
                    Expanded(
                      child: EcliniqText(
                        'Most Searched Specialties',
                        style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                          color: Color(0xff424242),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        EcliniqRouter.push(SearchSpecialities());
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
                          EcliniqText(
                            'View All',
                            style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                              color: Color(0xFF2372EC),
                            ),
                          ),
                          SvgPicture.asset(
                            EcliniqIcons.arrowRightBlue.assetPath,
                            width: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
                            height: EcliniqTextStyles.getResponsiveIconSize(context, 24.0),
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
                 Padding(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                    context,
                    left: 20.0,
                  ),
                  child: EcliniqText(
                    'Near you',
                    style: EcliniqTextStyles.responsiveBodyMediumProminent(context).copyWith(
                      color: Color(0xff8E8E8E),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12.0 : 16.0),

            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 16.0,
                vertical: 2.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.generalPhysician.assetPath,
                          title: 'General\nPhysician',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(initialSpeciality: 'General Physician'),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.gynaecologist.assetPath,
                          title: 'Women\'s\nHealth',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(initialSpeciality: 'Gynaecologist'),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.ophthalmologist.assetPath,
                          title: 'Eye\nCare',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(initialSpeciality: 'Ophthalmologist'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.dentist.assetPath,
                          title: 'Dental\nCare',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(initialSpeciality: 'Dentist'),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.pediatrician.assetPath,
                          title: 'Child\nSpecialist',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(initialSpeciality: 'Pediatrician'),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: cardSpacing),
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.ent.assetPath,
                          title: 'Ear, Nose\n& Throat',
                          onTap: () {
                            EcliniqRouter.push(
                              SpecialityDoctorsList(initialSpeciality: 'ENT'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: cardSpacing),
          ],
        );
      },
    );
  }

  Widget _buildSpecialtyCard(
    BuildContext context, {
    required double cardWidth,
    required double cardHeight,
    required String iconPath,

    required String title,
    required VoidCallback onTap,
  }) {
    final isSmallScreen = cardWidth < 130;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0)),
        child: Container(
          width: EcliniqTextStyles.getResponsiveWidth(context, 150.0),
          height: EcliniqTextStyles.getResponsiveHeight(context, 130.0),
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
            context,
            isSmallScreen ? 6.0 : 12.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0)),
            border: Border.all(color: Color(0xffB8B8B8), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: EcliniqTextStyles.getResponsiveSize(context, 52.0),
                height: EcliniqTextStyles.getResponsiveSize(context, 52.0),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 99.0)),
                ),
                child: Center(
                  child: Image.asset(
                    iconPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 52.0),
                    height: EcliniqTextStyles.getResponsiveIconSize(context, 52.0),
                  ),
                ),
              ),
              SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, isSmallScreen ? 6.0 : 8.0)),
              Flexible(
                child: EcliniqText(
                  title,
                  textAlign: TextAlign.center,
                  style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                    color: Color(0xff424242),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: EcliniqTextStyles.getResponsiveSize(context, 18.0),
                      width: EcliniqTextStyles.getResponsiveWidth(context, 200.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                      ),
                    ),
                  ),
                  SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 4.0)),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: EcliniqTextStyles.getResponsiveSize(context, 14.0),
                      width: EcliniqTextStyles.getResponsiveWidth(context, 100.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),

        Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 10.0,
            vertical: 0,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSpecialtyCardShimmer(context)),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
                  Expanded(child: _buildSpecialtyCardShimmer(context)),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
                  Expanded(child: _buildSpecialtyCardShimmer(context)),
                ],
              ),
              SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0)),
              Row(
                children: [
                  Expanded(child: _buildSpecialtyCardShimmer(context)),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
                  Expanded(child: _buildSpecialtyCardShimmer(context)),
                  SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),
                  Expanded(child: _buildSpecialtyCardShimmer(context)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyCardShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: EcliniqTextStyles.getResponsiveHeight(context, 128.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0)),
          border: Border.all(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
