import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/upchar_Q_coin/upchar_q_coin_page.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _InfoCard(
          path: EcliniqIcons.userHeartRounded.assetPath,
          label: "Age",
          value: age,
        ),
        DashedVerticalDivider(height: 80, color: Color(0xffB8B8B8)),
        _InfoCard(
          path: EcliniqIcons.gender.assetPath,
          label: "Gender",
          value: gender,
        ),
        DashedVerticalDivider(height: 80, color: Color(0xffB8B8B8)),
        _InfoCard(
          path: EcliniqIcons.dropperMinimalistic.assetPath,
          label: "Blood Group",
          value: bloodGroup,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String path;
  final String label;
  final String value;

  const _InfoCard({
    required this.path,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(path, height: 26, width: 26),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    void onWalletPressed() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UpcharCoin()),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 18, top: 10),
              child: InkWell(
                onTap: onWalletPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xffFFF4B8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.upcharCoinSmall.assetPath,
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '20',
                        style: EcliniqTextStyles.bodyMedium.copyWith(
                          color: Color(0xff626060),
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 2),
                      SvgPicture.asset(
                        EcliniqIcons.angleRight.assetPath,
                        height: 20,
                        width: 20,
                        colorFilter: const ColorFilter.mode(
                          Color(0xff626060),
                          BlendMode.srcIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                    Colors.white.withOpacity(1.0),
                    Colors.white.withOpacity(0.0),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 74,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Option 1: Custom Widget
class DashedVerticalDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashHeight;
  final double dashGap;

  const DashedVerticalDivider({
    super.key,
    this.height = 60,
    this.color = const Color(0xFFE0E0E0),
    this.dashHeight = 4,
    this.dashGap = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 0.5,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color,
          dashHeight: dashHeight,
          dashGap: dashGap,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double dashGap;

  _DashedLinePainter({
    required this.color,
    required this.dashHeight,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedHorizontallDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashHeight;
  final double dashGap;

  const DashedHorizontallDivider({
    super.key,
    this.height = 60,
    this.color = const Color(0xFFE0E0E0),
    this.dashHeight = 4,
    this.dashGap = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: 0.5,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color,
          dashHeight: dashHeight,
          dashGap: dashGap,
        ),
      ),
    );
  }
}
