import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:flutter/material.dart';

/// Shared bottom navigation bar widget used across main screens
/// Supports visual selection state and tap handling
///
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
      decoration: BoxDecoration(
        color: EcliniqScaffold.primaryBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(0),
                  behavior: HitTestBehavior.opaque,
                  child: _buildNavItem(
                    iconPath: EcliniqIcons.home.assetPath,
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
                    iconPath: EcliniqIcons.appointment.assetPath,
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
                    iconPath: EcliniqIcons.library.assetPath,
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
                    iconPath: EcliniqIcons.user.assetPath,
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
    required bool isSelected,
    required String label,
  }) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0E4395) : Colors.transparent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 90,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF96BFFF) : Colors.transparent,
            ),
          ),
          const SizedBox(height: 8),
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.7),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

