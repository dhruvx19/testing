import 'package:flutter/material.dart';

class EcliniqBottomSheet with WidgetsBindingObserver {
  static BuildContext? _bottomSheetContext;
  static bool closeWhenAppPaused = false;

  const EcliniqBottomSheet();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? horizontalPadding = 8,
    double? bottomPadding = 22,
    Color? barrierColor,
    Color? backgroundColor,
    VoidCallback? onClosing,
    bool? closeWhenAppPaused,
    bool? isDismissible = true,
    double borderRadius = 16,
  }) {
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
              top: 16,
              left: horizontalPadding ?? 12,
              right: horizontalPadding ?? 12,
              bottom: bottomPadding ?? 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor ?? Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      if (isDismissible ?? true)
                        Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E8E8E),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
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
