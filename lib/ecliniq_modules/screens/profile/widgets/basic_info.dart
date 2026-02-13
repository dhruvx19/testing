import 'package:ecliniq/ecliniq_api/wallet_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/upchar_Q_coin/upchar_q_coin_page.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

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
      children: [
        Expanded(
          child: _InfoCard(
            path: EcliniqIcons.userHeartRounded.assetPath,
            label: "Age",
            value: age,
          ),
        ),
        DashedVerticalDivider(height: 80, color: Color(0xffB8B8B8)),
        Expanded(
          child: _InfoCard(
            path: EcliniqIcons.gender.assetPath,
            label: "Gender",
            value: gender,
          ),
        ),
        DashedVerticalDivider(height: 80, color: Color(0xffB8B8B8)),
        Expanded(
          child: _InfoCard(
            path: EcliniqIcons.dropperMinimalistic.assetPath,
            label: "Blood Group",
            value: bloodGroup,
          ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          path,
          height: EcliniqTextStyles.getResponsiveIconSize(context, 26),
          width: EcliniqTextStyles.getResponsiveIconSize(context, 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class ProfileHeader extends StatefulWidget {
  final VoidCallback? onSettingsPressed;
  final String? profileImageUrl;

  const ProfileHeader({
    super.key,
    this.onSettingsPressed,
    this.profileImageUrl,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  final WalletService _walletService = WalletService();
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final authToken = authProvider.authToken;

    if (authToken == null) {
      setState(() {
        _isLoadingBalance = false;
      });
      return;
    }

    try {
      final response = await _walletService.getBalance(authToken: authToken);
      if (mounted) {
        setState(() {
          if (response.success && response.data != null) {
            _walletBalance = response.data!.balance;
          }
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

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
                        height: 22,
                        width: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isLoadingBalance
                            ? '...'
                            : _walletBalance.toStringAsFixed(0),
                        style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                          color: Color(0xff626060),
                          fontWeight: FontWeight.w500,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 2),
                      SvgPicture.asset(
                        EcliniqIcons.arrowRightCoin.assetPath,
                        height: 16,
                        width: 10,
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
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF), 
                    Color(0x00FFFFFF), 
                  ],
                  stops: [0.0, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
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
