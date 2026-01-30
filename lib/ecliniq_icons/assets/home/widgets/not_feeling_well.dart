import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/search_specialities_page.dart';
import 'package:ecliniq/ecliniq_modules/screens/symptoms/symptoms_page.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class NotFeelingWell extends StatelessWidget {
  final bool showShimmer;

  const NotFeelingWell({super.key, this.showShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return _buildShimmer(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;

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
                      height: EcliniqTextStyles.getResponsiveSize(
                        context,
                        24.0,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFF96BFFF),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              4.0,
                            ),
                          ),
                          bottomRight: Radius.circular(
                            EcliniqTextStyles.getResponsiveBorderRadius(
                              context,
                              4.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        12.0,
                      ),
                    ),
                    Expanded(
                      child: EcliniqText(
                        'Not Feeling Well?',
                        style: EcliniqTextStyles.responsiveHeadlineLarge(
                          context,
                        ).copyWith(color: Color(0xff424242)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        EcliniqRouter.push(SymptomsPage());
                      },
                      style: TextButton.styleFrom(
                        padding:
                            EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
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
                            style: EcliniqTextStyles.responsiveHeadlineXMedium(
                              context,
                            ).copyWith(color: Color(0xFF2372EC)),
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
                Padding(
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                    context,
                    left: 20.0,
                  ),
                  child: EcliniqText(
                    'Select the symptom you are experiencing',
                    style:
                        EcliniqTextStyles.responsiveBodyMediumProminent(
                          context,
                        ).copyWith(
                          color: Color(0xff8E8E8E),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ],
            ),

            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
            ),
            Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                context,
                16.0,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSymptomButton(
                      context,
                      'Fever/Chills',
                      EcliniqIcons.fever,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Headache',
                      EcliniqIcons.headache,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Stomach Pain',
                      EcliniqIcons.stomachPain,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Cold & Cough',
                      EcliniqIcons.coughCold,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Body Pain',
                      EcliniqIcons.bodyPain,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Back Pain',
                      EcliniqIcons.backPain,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Breathing Difficulty',
                      EcliniqIcons.breathingProblem,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Skin Rash /Itching',
                      EcliniqIcons.itchingOrSkinProblem,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Periods Problem',
                      EcliniqIcons.periodsProblem,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                    _buildSymptomButton(
                      context,
                      'Sleep Problem',
                      EcliniqIcons.sleepProblem,
                      () {},
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        16.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16.0 : 24.0),
          ],
        );
      },
    );
  }

  Widget _buildSymptomButton(
    BuildContext context,
    String title,
    EcliniqIcons icon, // Add this parameter
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: EcliniqTextStyles.getResponsiveWidth(context, 120.0),
          height: EcliniqTextStyles.getResponsiveHeight(context, 124.0),
          decoration: BoxDecoration(
            color: Color(0xFfF8FAFF),
            borderRadius: BorderRadius.circular(
              EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
            ),
          ),
          child: Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
              context,
              10.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: EcliniqTextStyles.getResponsiveSize(context, 48.0),
                  height: EcliniqTextStyles.getResponsiveSize(context, 48.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF2372EC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      // Changed from Image.asset to SvgPicture.asset
                      icon.assetPath,
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        48.0,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        48.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
                ),
                Flexible(
                  child: EcliniqText(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EcliniqTextStyles.responsiveTitleXLarge(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ],
            ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        150.0,
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
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(
                      context,
                      4.0,
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: EcliniqTextStyles.getResponsiveSize(
                        context,
                        14.0,
                      ),
                      width: EcliniqTextStyles.getResponsiveWidth(
                        context,
                        200.0,
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

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSymptomButtonShimmer(context),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              _buildSymptomButtonShimmer(context),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              _buildSymptomButtonShimmer(context),
              SizedBox(
                width: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              ),
              _buildSymptomButtonShimmer(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomButtonShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: EcliniqTextStyles.getResponsiveWidth(context, 120.0),
        height: EcliniqTextStyles.getResponsiveHeight(context, 100.0),
        decoration: BoxDecoration(
          color: Color(0xFfF8FAFF),
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
          ),
        ),
      ),
    );
  }
}
