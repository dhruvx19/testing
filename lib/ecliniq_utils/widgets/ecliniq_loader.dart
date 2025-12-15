import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../ecliniq_icons/icons.dart';

class EcliniqLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const EcliniqLoader({super.key, this.size = 24.0, this.color});

  @override
  _EcliniqLoaderState createState() => _EcliniqLoaderState();
}

class _EcliniqLoaderState extends State<EcliniqLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        EcliniqIcons.progressIndicator.assetPath,
        width: widget.size,
        height: widget.size,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
      ),
    );
  }
}
