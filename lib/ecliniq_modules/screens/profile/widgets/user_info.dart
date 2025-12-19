import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../ecliniq_utils/responsive_helper.dart';

class UserInfoSection extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final bool isPhoneVerified;

  const UserInfoSection({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    this.isPhoneVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);
    final colors = Theme.of(context).brightness == Brightness.light
        ? EcliniqColors.light
        : EcliniqColors.dark;

    return Column(
      children: [
        Text(
          name,
          style: EcliniqTextStyles.headlineLarge.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xff424242),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              phone,
              style: EcliniqTextStyles.bodyMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xff626060),
              ),
            ),
            if (isPhoneVerified) ...[
              SizedBox(
                width: screenSize.getResponsiveValue(
                  mobile: 5,
                  mobileSmall: 4,
                  mobileMedium: 5,
                  mobileLarge: 6,
                ),
              ),
              SvgPicture.asset(
                EcliniqIcons.verifiedGreen.assetPath,
                width: 24,
                height: 24,
              ),
            ],
          ],
        ),
        if (email.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            email,
            style: EcliniqTextStyles.bodyMedium.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xff626060),
            ),
          ),
        ],
      ],
    );
  }
}

class BasicInfoCards extends StatelessWidget {
  final String age;
  final String gender;
  final String bloodGroup;

  const BasicInfoCards({
    super.key,
    required this.age,
    required this.gender,
    required this.bloodGroup,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);
    final colors = Theme.of(context).brightness == Brightness.light
        ? EcliniqColors.light
        : EcliniqColors.dark;

    return ResponsivePadding(
      mobile: const EdgeInsets.symmetric(horizontal: 16),
      mobileSmall: const EdgeInsets.symmetric(horizontal: 12),
      mobileMedium: const EdgeInsets.symmetric(horizontal: 14),
      mobileLarge: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _InfoCard(
              icon: Icons.cake_outlined,
              label: "Age",
              value: age,
              iconColor: colors.textBrand,
              screenSize: screenSize,
              colors: colors,
            ),
          ),
          Container(
            width: 1,
            height: screenSize.getResponsiveValue(
              mobile: 60,
              mobileSmall: 55,
              mobileMedium: 58,
              mobileLarge: 62,
            ),
            color: colors.strokeNeutralExtraSubtle,
          ),
          Expanded(
            child: _InfoCard(
              icon: Icons.person_outline,
              label: "Gender",
              value: gender,
              iconColor: colors.textBrand,
              screenSize: screenSize,
              colors: colors,
            ),
          ),
          Container(
            width: 1,
            height: screenSize.getResponsiveValue(
              mobile: 60,
              mobileSmall: 55,
              mobileMedium: 58,
              mobileLarge: 62,
            ),
            color: colors.strokeNeutralExtraSubtle,
          ),
          Expanded(
            child: _InfoCard(
              icon: Icons.bloodtype_outlined,
              label: "Blood Group",
              value: bloodGroup,
              iconColor: colors.textDestructive,
              screenSize: screenSize,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final ScreenSize screenSize;
  final EcliniqColors colors;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.screenSize,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = screenSize.getResponsiveValue(
      mobile: 28,
      mobileSmall: 24,
      mobileMedium: 26,
      mobileLarge: 30,
    );

    final spacing = screenSize.getResponsiveValue(
      mobile: 8,
      mobileSmall: 6,
      mobileMedium: 7,
      mobileLarge: 9,
    );

    return Column(
      children: [
        Icon(icon, color: iconColor, size: iconSize),
        SizedBox(height: spacing),
        Text(
          label,
          style: EcliniqTextStyles.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 62,
          ),
        ),
        SizedBox(height: spacing / 2),
        Text(
          value,
          style: EcliniqTextStyles.headlineMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: screenSize.getResponsiveValue(
              mobile: 18,
              mobileSmall: 16,
              mobileMedium: 17,
              mobileLarge: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final VoidCallback? onSettingsPressed;
  final String? profileImageUrl;

  const ProfileHeader({
    super.key,
    this.onSettingsPressed,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);
    final colors = Theme.of(context).brightness == Brightness.light
        ? EcliniqColors.light
        : EcliniqColors.dark;

    final topPadding = screenSize.getResponsiveValue(
      mobile: 10,
      mobileSmall: 8,
      mobileMedium: 9,
      mobileLarge: 12,
    );

    final rightPadding = screenSize.getResponsiveValue(
      mobile: 20,
      mobileSmall: 16,
      mobileMedium: 18,
      mobileLarge: 22,
    );

    final iconSize = screenSize.getResponsiveValue(
      mobile: 24,
      mobileSmall: 22,
      mobileMedium: 23,
      mobileLarge: 26,
    );

    final titleFontSize = screenSize.getResponsiveValue(
      mobile: 64,
      mobileSmall: 56,
      mobileMedium: 60,
      mobileLarge: 70,
    );

    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(right: rightPadding, top: topPadding),
              child: IconButton(
                icon: Icon(
                  Icons.my_location_outlined,
                  color: colors.textFixedLight,
                  size: iconSize,
                ),
                onPressed: onSettingsPressed,
              ),
            ),
          ),
          SizedBox(
            height: screenSize.getResponsiveValue(
              mobile: 20,
              mobileSmall: 16,
              mobileMedium: 18,
              mobileLarge: 24,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.textFixedLight.withOpacity(1.0),
                    colors.textFixedLight.withOpacity(0.0),
                  ],
                ).createShader(bounds);
              },
              child: Text(
                "Profile",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: screenSize.getResponsiveValue(
                    mobile: 1,
                    mobileSmall: 0.8,
                    mobileMedium: 0.9,
                    mobileLarge: 1.2,
                  ),
                  color: colors.textFixedLight,
                  fontFamily: EcliniqTextStyles.fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
