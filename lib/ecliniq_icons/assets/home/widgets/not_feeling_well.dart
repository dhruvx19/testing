import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/search_specialities_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class NotFeelingWell extends StatelessWidget {
  final bool showShimmer;

  const NotFeelingWell({super.key, this.showShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return _buildShimmer();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 360;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not Feeling Well?',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff424242),
                        ),
                      ),

                      Text(
                        'Select the symptom you are experiencing',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Color(0xff8E8E8E),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    EcliniqRouter.push(SearchSpecialities());
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF2372EC),
                          fontWeight: FontWeight.w400,
                          fontSize: 18.0,
                        ),
                      ),

                      SvgPicture.asset(
                        EcliniqIcons.arrowRightBlue.assetPath,
                        width: 24,
                        height: 24,
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

            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSymptomButton(context, 'Fever', () {}),
                    SizedBox(width: 16),
                    _buildSymptomButton(context, 'Headache', () {}),
                    SizedBox(width: 16),
                    _buildSymptomButton(context, 'Stomach Pain', () {}),
                    SizedBox(width: 16),
                    _buildSymptomButton(context, 'Cold & Cough', () {}),
                    SizedBox(width: 16),
                    _buildSymptomButton(context, 'Join Pain', () {}),
                    SizedBox(width: 16),
                    _buildSymptomButton(context, 'Acidity', () {}),
                    SizedBox(width: 16),
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

    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,

        child: Container(
          width: 120,
          height: 110,
          decoration: BoxDecoration(
            color: Color(0xFfF8FAFF),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Color(0xFF2372EC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      EcliniqIcons.generalPhysician.assetPath,
                      width: 52,
                      height: 52,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                FittedBox(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xff424242),
                      fontSize: 16.0,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 4),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 14,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSymptomButtonShimmer(),
              const SizedBox(width: 16),
              _buildSymptomButtonShimmer(),
              const SizedBox(width: 16),
              _buildSymptomButtonShimmer(),
              const SizedBox(width: 16),
              _buildSymptomButtonShimmer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomButtonShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: Color(0xFfF8FAFF),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}
