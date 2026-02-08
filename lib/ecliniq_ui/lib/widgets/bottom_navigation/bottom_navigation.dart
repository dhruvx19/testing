import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EcliniqBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const EcliniqBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Color(0xff0D47A1)),
      child: SafeArea(
        top: false,
        child: Container(
          height: EcliniqTextStyles.getResponsiveHeight(context, 70.0),
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
            context,
            horizontal: 8.0,
            vertical: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(0),
                  behavior: HitTestBehavior.opaque,
                  child: _buildNavItem(
                    context: context,
                    iconPath: EcliniqIcons.explore.assetPath,
                    selectedIconPath: EcliniqIcons.homeFilled.assetPath,
                    isSelected: currentIndex == 0,
                    label: 'Explore',
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(1),
                  behavior: HitTestBehavior.opaque,
                  child: _buildNavItem(
                    context: context,
                    iconPath: EcliniqIcons.myVisits.assetPath,
                    selectedIconPath: EcliniqIcons.myVisitsFilled.assetPath,
                    isSelected: currentIndex == 1,
                    label: 'My Visits',
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  behavior: HitTestBehavior.opaque,
                  child: _buildNavItem(
                    context: context,
                    iconPath: EcliniqIcons.healthfile.assetPath,
                    selectedIconPath: EcliniqIcons.filesFilled.assetPath,
                    isSelected: currentIndex == 2,
                    label: 'Health Files',
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(3),
                  behavior: HitTestBehavior.opaque,
                  child: _buildNavItem(
                    context: context,
                    iconPath: EcliniqIcons.profile.assetPath,
                    selectedIconPath: EcliniqIcons.userSelected.assetPath,
                    isSelected: currentIndex == 3,
                    label: 'Profile',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String iconPath,
    required String selectedIconPath,
    required bool isSelected,
    required String label,
    required BuildContext context,
  }) {
    const selectedTextColor = Color(0xFFF2F7FF);
    const unselectedTextColor = Colors.white;

    return Container(
      width: EcliniqTextStyles.getResponsiveWidth(context, 80.0),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0E4395) : Colors.transparent,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
          ),
          bottomRight: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: EcliniqTextStyles.getResponsiveSize(context, 3.0),
            width: EcliniqTextStyles.getResponsiveWidth(context, 90.0),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFf96BFFF) : Colors.transparent,
            ),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 8.0),
          ),

          SizedBox(
            height: EcliniqTextStyles.getResponsiveIconSize(context, 30.0),
            child: Center(
              child: SvgPicture.asset(
                isSelected ? selectedIconPath : iconPath,
                width: EcliniqTextStyles.getResponsiveIconSize(
                  context,
                  isSelected ? 26.0 : 30.0,
                ),
                height: EcliniqTextStyles.getResponsiveIconSize(
                  context,
                  isSelected ? 26.0 : 30.0,
                ),
              ),
            ),
          ),
          Text(
            label,
            style: EcliniqTextStyles.responsiveBodyXSmall(context).copyWith(
              color: isSelected ? selectedTextColor : unselectedTextColor,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}