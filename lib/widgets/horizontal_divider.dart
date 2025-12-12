import 'package:flutter/material.dart';

class HorizontalDivider extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const HorizontalDivider({
    super.key,
    this.width = double.infinity,
    this.height = 0.5,
    this.color = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: color,
    );
  }
}