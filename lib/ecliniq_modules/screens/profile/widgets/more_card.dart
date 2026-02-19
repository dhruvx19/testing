import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';

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

  void _showCopyFeedback(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Invite URL Copied',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    const String referralLink = "https://upcharq.com/invite/RANDOM123";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(2),
            child: Text(
              'More',
              style: EcliniqTextStyles.responsiveHeadlineLarge(
                context,
              ).copyWith(color: Color(0xff8E8E8E)),
            ),
          ),

          _ReferEarnMenuItem(
            icon: EcliniqIcons.whatsapp.assetPath,
            title: 'Refer & Earn',
            subtitle: 'Invite and Care for Friends and Family',
            onCopy: () {
              Clipboard.setData(const ClipboardData(text: referralLink));
              _showCopyFeedback(context);
            },
            onShare: () {
              Share.share('Check out Upchar-Q: $referralLink');
            },
          ),

          _buildDivider(),

          _MoreMenuItem(
            icon: EcliniqIcons.questionMark.assetPath,
            title: 'Help & Support',
            subtitle: 'Send us Email on : Support@upcharq.com',
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

          const SizedBox(height: 26),
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

class _ReferEarnMenuItem extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const _ReferEarnMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                icon,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: EcliniqTextStyles.responsiveBodySmall(
                        context,
                      ).copyWith(color: Color(0xff8E8E8E)),
                    ),
                  ],
                ],
              ),
            ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onCopy,
                  child: SvgPicture.asset(
                    EcliniqIcons.copy.assetPath,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xff424242),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(width: 0.5, height: 20, color: Color(0xffD6D6D6)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onShare,
                  child: SvgPicture.asset(
                    EcliniqIcons.share.assetPath,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xff424242),
                      BlendMode.srcIn,
                    ),
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
              child: SvgPicture.asset(
                icon,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xff424242)),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: EcliniqTextStyles.responsiveBodySmall(
                        context,
                      ).copyWith(color: Color(0xff8E8E8E)),
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
