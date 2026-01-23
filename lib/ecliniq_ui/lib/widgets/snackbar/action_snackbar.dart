import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomActionSnackBar {
  static void show({
    required BuildContext context,
    required String title,
    required String subtitle,
    Duration? duration,
  }) {
    final overlayState = Overlay.of(context);
    late final OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _ActionSnackBarOverlay(
        title: title,
        subtitle: subtitle,
        duration: duration ?? const Duration(seconds: 15),
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);

    // Auto-remove after duration
    Future.delayed(duration ?? const Duration(seconds: 15), () {
      overlayEntry.remove();
    });
  }
}

class _ActionSnackBarOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ActionSnackBarOverlay({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ActionSnackBarOverlay> createState() => _ActionSnackBarOverlayState();
}

class _ActionSnackBarOverlayState extends State<_ActionSnackBarOverlay>
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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Progress bar animation
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    _slideController.forward();
    _progressController.forward();
  }

  void _dismiss() {
    _progressController.stop(); // Stop progress animation
    _slideController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
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
              // Swipe to dismiss horizontally (left or right)
              if (details.primaryVelocity != null &&
                  details.primaryVelocity!.abs() > 300) {
                _dismiss();
              }
            },
            onVerticalDragEnd: (details) {
              // Swipe to dismiss vertically (up or down)
              if (details.primaryVelocity != null &&
                  details.primaryVelocity!.abs() > 300) {
                _dismiss();
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
                        EcliniqIcons.actionIcon.assetPath,
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
                              style:
                                  EcliniqTextStyles.responsiveTitleXLarge(
                                    context,
                                  ).copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFBE8B00),
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.subtitle,
                              style:
                                  EcliniqTextStyles.responsiveBodySmall(
                                    context,
                                  ).copyWith(
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
                                      width:
                                          constraints.maxWidth *
                                          _progressAnimation.value,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFBE8B00),
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
