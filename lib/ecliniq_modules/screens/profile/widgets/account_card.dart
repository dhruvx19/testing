import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountSettingsMenu extends StatelessWidget {
  final VoidCallback? onPersonalDetailsPressed;
  final VoidCallback? onMyDoctorsPressed;
  final VoidCallback? onSecuritySettingsPressed;

  const AccountSettingsMenu({
    super.key,
    this.onPersonalDetailsPressed,
    this.onSecuritySettingsPressed,
    this.onMyDoctorsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Account',
              style: EcliniqTextStyles.headlineLarge.copyWith(
                color: Color(0xff8E8E8E),
              ),
            ),
          ),
          _buildMenuItem(
            iconPath: 'lib/ecliniq_icons/assets/user_circle.svg',
            iconColor: Colors.blue,
            title: 'Personal Details',
            onTap: onPersonalDetailsPressed,
          ),
          _buildDivider(),
          _buildMenuItem(
            iconPath: 'lib/ecliniq_icons/assets/Stethoscope.svg',
            iconColor: Colors.blue,
            title: 'My Doctors',
            onTap: onMyDoctorsPressed,
          ),
          _buildDivider(),
          _buildMenuItem(
            iconPath: 'lib/ecliniq_icons/assets/lock_key_hole_minimalistic.svg',
            iconColor: Colors.blue,
            title: 'Security Settings',
            onTap: onSecuritySettingsPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String iconPath,
    required Color iconColor,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(iconPath, height: 24, width: 24),
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: EcliniqTextStyles.headlineXMedium.copyWith(
                  color: Colors.black87,
                ),
              ),
            ),
            SvgPicture.asset(
              EcliniqIcons.angleRight.assetPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(Color(0xff424242), BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 0.5, color: Color(0xffD6D6D6)),
    );
  }
}
