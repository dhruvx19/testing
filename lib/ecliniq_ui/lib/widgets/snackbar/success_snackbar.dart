import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSuccessSnackBar extends SnackBar {
  CustomSuccessSnackBar._({
    super.key,
    required String title,
    required String subtitle,
    Duration? duration,
    required EdgeInsets margin,
  }) : super(
         content: _SuccessSnackBarContent(
           title: title,
           subtitle: subtitle,
           duration: duration ?? const Duration(seconds: 15),
         ),
         backgroundColor: Colors.transparent,
         behavior: SnackBarBehavior.floating,
         margin: margin,
         padding: EdgeInsets.zero,
         elevation: 8,
         duration: duration ?? const Duration(seconds: 15),
       );

  factory CustomSuccessSnackBar({
    Key? key,
    required String title,
    required String subtitle,
    Duration? duration,
    required BuildContext context,
  }) {
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    // Position at top: small top margin, very large bottom margin to push it to top
    return CustomSuccessSnackBar._(
      key: key,
      title: title,
      subtitle: subtitle,
      duration: duration,
      margin: EdgeInsets.only(
        top: safeAreaTop + 7,
        left: 16,
        right: 16,
        bottom: screenHeight * 0.8, // Large bottom margin to position at top
      ),
    );
  }
}

class _SuccessSnackBarContent extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration duration;

  const _SuccessSnackBarContent({
    required this.title,
    required this.subtitle,
    required this.duration,
  });

  @override
  State<_SuccessSnackBarContent> createState() =>
      _SuccessSnackBarContentState();
}

class _SuccessSnackBarContentState extends State<_SuccessSnackBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    // Animation goes from 1.0 (right) to 0.0 (left)
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.1),
        //     blurRadius: 10,
        //     offset: const Offset(0, 4),
        //   ),
        // ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 16),
              // Icon Container
              SvgPicture.asset(
                EcliniqIcons.snackbar.assetPath,
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3EAF3F), // Green
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff8E8E8E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 8),
          // Animated green progress indicator at the bottom
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 4,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Background (transparent/grey if needed)
                          Container(
                            width: double.infinity,
                            color: Colors.transparent,
                          ),
                          // Animated progress bar from right to left
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth * _animation.value,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6DDB72), // Green
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
