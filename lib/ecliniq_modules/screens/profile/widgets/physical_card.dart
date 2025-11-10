import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';

class PhysicalHealthCard extends StatelessWidget {
  final String status;
  final double bmi;
  final String height;
  final String weight;

  const PhysicalHealthCard({
    super.key,
    required this.status,
    required this.bmi,
    required this.height,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcliniqColors.light.bgLightblue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: EcliniqColors.light.strokeNeutralExtraSubtle),
          bottom: BorderSide(color: EcliniqColors.light.strokeNeutralExtraSubtle),
          left: BorderSide(color: EcliniqColors.light.strokeNeutralExtraSubtle),
          right: BorderSide(color: EcliniqColors.light.strokeNeutralExtraSubtle),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Physical Health Info',
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: EcliniqColors.light.textSecondary,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 30),
          _BMIVisualization(bmi: bmi),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoBox(
                  label: 'Height',
                  value: height,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBox(
                  label: 'Weight',
                  value: weight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BMIVisualization extends StatelessWidget {
  final double bmi;

  const _BMIVisualization({required this.bmi});

  String _getStatus() {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor() {
    if (bmi < 18.5) return Primitives.brightBlue;
    if (bmi < 25) return EcliniqColors.light.textSuccess;
    if (bmi < 30) return EcliniqColors.light.textWarning;
    return EcliniqColors.light.textDestructive;
  }

  double _calculatePosition() {
    const double minBMI = 15.0;
    const double maxBMI = 35.0;
    double position = (bmi - minBMI) / (maxBMI - minBMI);
    return position.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const bmiValueWidth = 60.0;
        final barWidth = totalWidth - bmiValueWidth - 16;
        final position = _calculatePosition();

        // Fixed indicator width
        const indicatorWidth = 80.0;

        // Calculate position and ensure indicator stays within bounds
        final rawPosition = (barWidth * position);
        final indicatorPosition = (rawPosition - (indicatorWidth / 2))
            .clamp(0.0, barWidth - indicatorWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _BMIBar(),
                      // Positioned indicator with fixed width
                      Positioned(
                        left: indicatorPosition,
                        top: -23, // Fixed distance above the bar
                        child: _TriangleIndicator(
                          color: _getBMIColor(),
                          status: _getStatus(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: bmiValueWidth,
                  child: Text(
                    bmi.toStringAsFixed(1),
                    style: EcliniqTextStyles.headlineLarge.copyWith(
                      fontSize: (MediaQuery.of(context).size.height*0.027),
                      fontWeight: FontWeight.w700,
                      color: _getBMIColor(),
                      height: 1,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BMIBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        child: Row(
          children: [
            ..._buildBarSection(16, Primitives.brightBlue),
            ..._buildBarSection(16, EcliniqColors.light.textSuccess),
            ..._buildBarSection(16, EcliniqColors.light.textWarning),
            ..._buildBarSection(16, EcliniqColors.light.textDestructive),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBarSection(int count, Color color) {
    return List.generate(
      count,
          (i) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _TriangleIndicator extends StatelessWidget {
  final Color color;
  final String status;

  const _TriangleIndicator({required this.color, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: EcliniqText(
              status,
              style: EcliniqTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 7),
          painter: _TrianglePainter(color: color),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: EcliniqColors.light.bgBaseBase,
        border: Border.all(
          color: EcliniqColors.light.strokeNeutralExtraSubtle,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: EcliniqTextStyles.bodyXSmall.copyWith(
              color: EcliniqColors.light.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: EcliniqColors.light.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}