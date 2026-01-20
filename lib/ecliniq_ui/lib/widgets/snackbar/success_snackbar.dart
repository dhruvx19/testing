import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSuccessSnackBar {
  static void show({
    required BuildContext context,
    required String title,
    required String subtitle,
    Duration? duration,
  }) {
    final overlayState = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _SuccessSnackBarOverlay(
        title: title,
        subtitle: subtitle,
        duration: duration ?? const Duration(seconds: 15),
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto-remove after duration
    Future.delayed(duration ?? const Duration(seconds: 15), () {
      overlayEntry.remove();
    });
  }
}

class _SuccessSnackBarOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration duration;

  const _SuccessSnackBarOverlay({
    required this.title,
    required this.subtitle,
    required this.duration,
  });

  @override
  State<_SuccessSnackBarOverlay> createState() =>
      _SuccessSnackBarOverlayState();
}

class _SuccessSnackBarOverlayState extends State<_SuccessSnackBarOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Slide animation (entrance)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Progress bar animation
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _slideController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaTop = MediaQuery.of(context).padding.top;

    return Positioned(
      top: safeAreaTop + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              // Swipe to dismiss
              if (details.primaryVelocity!.abs() > 500) {
                _slideController.reverse().then((_) {
                  if (mounted) {
                    (context as Element).markNeedsBuild();
                  }
                });
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      SvgPicture.asset(
                        EcliniqIcons.snackbar.assetPath,
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: EcliniqTextStyles.responsiveTitleXLarge(context)
                                  .copyWith(
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3EAF3F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.subtitle,
                              style: EcliniqTextStyles.responsiveBodySmall(context)
                                  .copyWith(
                                fontWeight: FontWeight.w400,
                                color: const Color(0xff8E8E8E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: SizedBox(
                      height: 6,
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    color: Colors.transparent,
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: constraints.maxWidth *
                                          _progressAnimation.value,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF6DDB72),
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}