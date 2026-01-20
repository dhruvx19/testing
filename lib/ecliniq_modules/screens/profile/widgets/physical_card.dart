import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';

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
        color: Color(0xffF8FAFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xffF2F7FF), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Physical Health Info',
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              color: Color(0xff626060),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          _BMIVisualization(bmi: bmi),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _InfoBox(label: 'Height', value: height),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBox(label: 'Weight', value: weight),
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
    if (bmi < 18.5) return Color(0xff96BFFF);
    if (bmi < 25) return Color(0xff3EAF3F);
    if (bmi < 30) return Color(0xffE7AC09);
    return Color(0xffF04248);
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
        const bmiValueWidth = 45.0; // Reduced from 60.0
        final barWidth =
            totalWidth - bmiValueWidth - 8; // Reduced spacing from 16
        final position = _calculatePosition();

        const indicatorWidth = 80.0;

        final rawPosition = (barWidth * position);
        final indicatorPosition = (rawPosition - (indicatorWidth / 2)).clamp(
          0.0,
          barWidth - indicatorWidth,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'BMI',
                    style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                
                      fontWeight: FontWeight.w400,
                      color: Color(0xff424242),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _BMIBar(),
                      Positioned(
                        left: indicatorPosition,
                        top: -24,
                        child: _TriangleIndicator(
                          color: _getBMIColor(),
                          status: _getStatus(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '22.3',
                    style: EcliniqTextStyles.responsiveHeadlineXLarge(context).copyWith(
                     
                      fontWeight: FontWeight.w700,
                      color: _getBMIColor(),
                      height: 1,
                    ),
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
      height: 20,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        child: Row(
          children: [
            ..._buildBarSection(16, Color(0xff96BFFF)),
            const SizedBox(width: 1),
            ..._buildBarSection(16, Color(0xff3EAF3F)),
            const SizedBox(width: 1),
            ..._buildBarSection(16, Color(0xffE7AC09)),
            const SizedBox(width: 1),
            ..._buildBarSection(16, Color(0xffF04248)),
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
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
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
          width: 80,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0.3),
            child: Center(
              child: FittedBox(
                child: EcliniqText(
                  status,
                  style: EcliniqTextStyles.responsiveBodyXSmall(context).copyWith(
                    color: Colors.white,

                    fontWeight: FontWeight.w500,
                  ),
                ),
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
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,

        border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
              color: Color(0xff626060),

              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              color: Color(0xff424242),

              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
