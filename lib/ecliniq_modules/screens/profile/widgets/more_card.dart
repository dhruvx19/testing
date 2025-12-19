import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MoreSettingsMenuWidget extends StatelessWidget {
  final VoidCallback? onReferEarnPressed;
  final VoidCallback? onHelpSupportPressed;
  final VoidCallback? onTermsPressed;
  final VoidCallback? onPrivacyPressed;
  final VoidCallback? onFaqPressed;
  final VoidCallback? onAboutPressed;
  final VoidCallback? onLogoutPressed;
  final VoidCallback? onFeedbackPressed;
  final VoidCallback? onDeleteAccountPressed;
  final String appVersion;
  final String supportEmail;

  const MoreSettingsMenuWidget({
    super.key,
    this.onReferEarnPressed,
    this.onHelpSupportPressed,
    this.onTermsPressed,
    this.onPrivacyPressed,
    this.onFaqPressed,
    this.onAboutPressed,
    this.onLogoutPressed,
    this.onDeleteAccountPressed,
    this.onFeedbackPressed,
    this.appVersion = 'v1.0.0',
    this.supportEmail = 'Support@eclinicq.com',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'More',
              style: EcliniqTextStyles.headlineLarge.copyWith(
                color: Color(0xff8E8E8E),
              ),
            ),
          ),

          _ReferEarnMenuItem(
            icon: EcliniqIcons.whatsapp.assetPath,
            title: 'Refer & Earn',
            subtitle: 'Invite Friends and Family',
            onTap: onReferEarnPressed,
          ),

          _buildDivider(),

          _MoreMenuItem(
            icon: EcliniqIcons.questionMark.assetPath,
            title: 'Help & Support',
            subtitle: 'Send us Email on : $supportEmail',
            onTap: onHelpSupportPressed,
          ),

          _buildDivider(),

          _MoreMenuItem(
            icon: EcliniqIcons.clipboard.assetPath,
            title: 'Terms & Conditions',
            onTap: onTermsPressed,
          ),

          _buildDivider(),

          _MoreMenuItem(
            icon: EcliniqIcons.shieldStar.assetPath,
            title: 'Privacy Policy',
            onTap: onPrivacyPressed,
          ),

          _buildDivider(),

          _MoreMenuItem(
            icon: EcliniqIcons.taskType.assetPath,
            title: "FAQ's and Grievances",
            onTap: onFaqPressed,
          ),

          _buildDivider(),

          _MoreMenuItem(
            icon: EcliniqIcons.infoCircle.assetPath,
            title: 'About e-Clinic Q',
            onTap: onAboutPressed,
          ),

          _buildDivider(),

          _MoreMenuItem(
            icon: EcliniqIcons.like.assetPath,
            title: 'Send feedback',
            onTap: onFeedbackPressed,
          ),

          _buildDivider(),
          _MoreMenuItem(
            icon: EcliniqIcons.logout.assetPath,
            title: 'Logout',
            onTap: onLogoutPressed,
          ),

          const SizedBox(height: 20),

          const SizedBox(height: 30),

          Center(
            child: Column(
              children: [
                SvgPicture.asset(
                  EcliniqIcons.ecliniqLogo.assetPath,
                  width: 116,
                  height: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  appVersion,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xffB8B8B8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xffD6D6D6),
      indent: 8,
      endIndent: 8,
    );
  }
}

// Special widget for Refer & Earn with share icons
class _ReferEarnMenuItem extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _ReferEarnMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(icon, width: 24, height: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EcliniqTextStyles.headlineXMedium.copyWith(
                      color: Color(0xff424242),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: EcliniqTextStyles.bodySmall.copyWith(
                        color: Color(0xff8E8E8E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Share icons with divider
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  EcliniqIcons.copy.assetPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Color(0xff424242),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 0.5, height: 20, color: Color(0xffD6D6D6)),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  EcliniqIcons.share.assetPath,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Color(0xff424242),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Regular menu item with arrow
class _MoreMenuItem extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(icon, width: 24, height: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EcliniqTextStyles.headlineXMedium.copyWith(
                      color: Color(0xff424242),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: EcliniqTextStyles.bodySmall.copyWith(
                        color: Color(0xff8E8E8E),
                      ),
                    ),
                  ],
                ],
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
}
