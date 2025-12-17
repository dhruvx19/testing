import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/search_specialities/search_specialities_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

class MostSearchedSpecialities extends StatelessWidget {
  final bool showShimmer;

  const MostSearchedSpecialities({super.key, this.showShimmer = false});

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return _buildShimmer();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        'Most Searched Specialties',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff424242),
                        ),
                      ),
               
                      Text(
                        'Near you',
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
            SizedBox(height: isSmallScreen ? 12.0 : 16.0),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2),
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
                          onTap: () => EcliniqRouter(),
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
                          onTap: () => EcliniqRouter(),
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
                          onTap: () => EcliniqRouter(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSpecialtyCard(
                          context,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          iconPath: EcliniqIcons.dentist.assetPath,

                          title: 'Dental\nCare',
                          onTap: () => EcliniqRouter(),
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
                          onTap: () => EcliniqRouter(),
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
                          onTap: () => EcliniqRouter(),
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
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 150,
          height: 130,
          padding: EdgeInsets.all(isSmallScreen ? 6.0 : 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Color(0xffB8B8B8), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(99.0),
                ),
                child: Center(
                  child: Image.asset(iconPath, width: 52, height: 52),
                ),
              ),
              SizedBox(height: isSmallScreen ? 6.0 : 8.0),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
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
                      height: 18,
                      width: 200,
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
                      width: 100,
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
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSpecialtyCardShimmer()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
