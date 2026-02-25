import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';

class EcliniqBottomSheet with WidgetsBindingObserver {
  static BuildContext? _bottomSheetContext;
  static bool closeWhenAppPaused = false;

  const EcliniqBottomSheet();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? horizontalPadding,
    double? bottomPadding,
    Color? barrierColor,
    Color? backgroundColor,
    VoidCallback? onClosing,
    bool? closeWhenAppPaused,
    bool? isDismissible = true,
    double? borderRadius,
  }) {
    
    final responsiveHorizontalPadding = horizontalPadding != null
        ? horizontalPadding
        : EcliniqTextStyles.getResponsiveSpacing(context, 12.0);
    final responsiveBottomPadding = bottomPadding != null
        ? bottomPadding
        : EcliniqTextStyles.getResponsiveSpacing(context, 16.0);
    final responsiveBorderRadius = borderRadius != null
        ? borderRadius
        : EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0);
    const bottomSheet = EcliniqBottomSheet();
    if (closeWhenAppPaused != null) {
      EcliniqBottomSheet.closeWhenAppPaused = closeWhenAppPaused;
    }
    WidgetsBinding.instance.addObserver(bottomSheet);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
        reverseDuration: const Duration(milliseconds: 300),
      ),
      isDismissible: isDismissible ?? true,
      enableDrag: isDismissible ?? true,
      builder: (bottomSheetContext) {
        _bottomSheetContext = bottomSheetContext;
        return PopScope(
          canPop: isDismissible ?? true,
          child: Padding(
            padding: EdgeInsets.only(
              top: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
              left: responsiveHorizontalPadding,
              right: responsiveHorizontalPadding,
              bottom: responsiveBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(responsiveBorderRadius),
                  ),
                  clipBehavior: responsiveBorderRadius > 0
                      ? Clip.antiAlias
                      : Clip.none,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      
                      if (isDismissible ?? true)
                        Container(
                          height: EcliniqTextStyles.getResponsiveSize(context, 4.0),
                          width: EcliniqTextStyles.getResponsiveSize(context, 40.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E8E8E),
                            borderRadius: BorderRadius.circular(
                              EcliniqTextStyles.getResponsiveBorderRadius(
                                context,
                                100.0,
                              ),
                            ),
                          ),
                          margin: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                            context,
                            top: 12.0,
                            bottom: 8.0,
                          ),
                        ),
                      Flexible(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      WidgetsBinding.instance.removeObserver(bottomSheet);
      _bottomSheetContext = null;
      onClosing?.call();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        _bottomSheetContext != null &&
        closeWhenAppPaused) {
      Navigator.of(_bottomSheetContext!).pop();
    }
  }
}
