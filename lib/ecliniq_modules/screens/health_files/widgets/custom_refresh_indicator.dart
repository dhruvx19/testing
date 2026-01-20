import 'package:flutter/material.dart';

/// Custom RefreshIndicator wrapper that uses styled RefreshIndicator
/// Note: Flutter's RefreshIndicator doesn't support custom indicator widgets,
/// but we can style it to match EcliniqLoader colors
class CustomRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double displacement;
  final double edgeOffset;

  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.edgeOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? const Color(0xFF2372EC),
      backgroundColor: backgroundColor ?? Colors.white,
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
