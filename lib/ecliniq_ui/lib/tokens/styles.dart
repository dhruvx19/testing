import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EcliniqTextStyles {
  EcliniqTextStyles._();

  static const fontFamily = 'Inter';

  /// Base design width (iPhone 12/13 width in logical pixels)
  static const double baseDesignWidth = 390.0;

  /// Minimum screen width that doesn't scale down
  /// Devices with width >= minNoScaleWidth will not scale down
  /// Set to 360px to include common Android devices and smaller iPhones
  static const double minNoScaleWidth = 380.0;

  /// Minimum scale factor to prevent fonts from becoming too small
  /// Reduced from 0.85 to 0.80 for more aggressive scaling on smaller devices
  static const double minScaleFactor = 0.85;

  /// Scaling intensity multiplier (0.0-1.0, lower = more aggressive scaling down)
  /// This makes fonts scale down more aggressively for smaller devices
  /// Lower values = more aggressive scaling (steeper curve)
  /// Current: 0.80 = very aggressive scaling (devices just below threshold scale down more)
  /// Previous: 0.88 = moderate aggressive, 0.95 = gentle scaling
  static const double scalingIntensity = 0.80;

  /// Enable/disable logging for responsive font scaling (default: true in debug mode)
  static bool enableLogging = kDebugMode;

  /// Cache to track logged screen sizes (to avoid duplicate logs)
  static final Map<String, bool> _loggedScreenSizes = {};

  /// Clear the logging cache (useful for testing or when screen size changes)
  static void clearLogCache() {
    _loggedScreenSizes.clear();
  }

  /// Print detailed screen size and scaling information
  /// Call this method manually to see current device scaling info
  /// Useful for debugging and fine-tuning responsive scaling
  static void printScreenInfo(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scaleFactor = getFontScaleFactor(context);

    // Calculate base factor before intensity adjustment
    final baseFactor = screenWidth >= minNoScaleWidth
        ? 1.0
        : (screenWidth / baseDesignWidth);
    final calculatedFactor = baseFactor * scalingIntensity;
    final uiScaleFactor = (scaleFactor * 0.92).clamp(0.88, 1.0);

    // Calculate example sizes manually
    final exampleButtonHeight = (52.0 * uiScaleFactor).clamp(44.0, 52.0 * 1.1);
    final exampleIconSize = 24.0 * scaleFactor;
    final examplePadding = 16.0 * uiScaleFactor;
    final exampleBorderRadius = 8.0 * uiScaleFactor;

    print('═══════════════════════════════════════════════════════════');
    print('📱 DEVICE SCREEN SIZE & SCALING INFORMATION');
    print('═══════════════════════════════════════════════════════════');
    print('Screen Dimensions:');
    print('   Width:  ${screenWidth.toStringAsFixed(1)}px');
    print('   Height: ${screenHeight.toStringAsFixed(1)}px');
    print('');
    print('Base Design Width: ${baseDesignWidth}px (iPhone 12/13)');
    print(
      'Min No-Scale Width: ${minNoScaleWidth}px (devices >= this don\'t scale)',
    );
    print('');
    print('Scaling Calculations:');
    print(
      '   Base Factor:        ${baseFactor.toStringAsFixed(4)} (${(baseFactor * 100).toStringAsFixed(2)}%)',
    );
    print('   Intensity Applied:  $scalingIntensity');
    print('   Calculated Factor:  ${calculatedFactor.toStringAsFixed(4)}');
    print(
      '   Final Font Factor:  ${scaleFactor.toStringAsFixed(4)} (${(scaleFactor * 100).toStringAsFixed(2)}%)',
    );
    print(
      '   UI Element Factor: ${uiScaleFactor.toStringAsFixed(4)} (${(uiScaleFactor * 100).toStringAsFixed(2)}%)',
    );
    print('');
    print('Example Scaled Sizes:');
    print(
      '   Button Height (52px):  ${exampleButtonHeight.toStringAsFixed(1)}px',
    );
    print('   Icon Size (24px):      ${exampleIconSize.toStringAsFixed(1)}px');
    print('   Padding (16px):        ${examplePadding.toStringAsFixed(1)}px');
    print(
      '   Border Radius (8px):   ${exampleBorderRadius.toStringAsFixed(1)}px',
    );
    print('');
    print(
      'Device Type: ${screenWidth >= minNoScaleWidth ? "✅ Standard/Large (no scaling)" : "📱 Small Device (scaled down)"}',
    );
    print('═══════════════════════════════════════════════════════════');
  }

  /// Calculate font scale factor based on screen width
  /// Returns 1.0 for devices >= minNoScaleWidth, scales down for smaller devices
  static double getFontScaleFactor(BuildContext context, {String? styleName}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    double scaleFactor;
    // Don't scale down for devices >= minNoScaleWidth (360px and above)
    if (screenWidth >= minNoScaleWidth) {
      scaleFactor = 1.0; // Keep original size for devices 360px and larger
    } else {
      // Scale down proportionally for smaller devices (below 360px)
      final baseFactor = screenWidth / baseDesignWidth;
      // Apply more aggressive scaling using intensity multiplier (makes fonts smaller)
      // Example: 359px device: 359/390 = 0.921, then 0.921 * 0.80 = 0.737 (very aggressive)
      // Example: 320px device: 320/390 = 0.821, then 0.821 * 0.80 = 0.657 (very aggressive)
      final calculatedFactor = baseFactor * scalingIntensity;
      // Ensure it doesn't go below minimum scale
      scaleFactor = calculatedFactor < minScaleFactor
          ? minScaleFactor
          : calculatedFactor;
    }

    // Log screen size and scale factor once per unique screen size (only in debug mode)
    if (enableLogging) {
      final screenKey =
          '${screenWidth.toStringAsFixed(0)}x${screenHeight.toStringAsFixed(0)}';
      if (!_loggedScreenSizes.containsKey(screenKey)) {
        _loggedScreenSizes[screenKey] = true;

        // Calculate base factor before intensity adjustment
        final baseFactor = screenWidth >= minNoScaleWidth
            ? 1.0
            : (screenWidth / baseDesignWidth);
        final calculatedFactor = baseFactor * scalingIntensity;
        final uiScaleFactor = (scaleFactor * 0.92).clamp(0.88, 1.0);

        // Calculate example sizes manually to avoid circular dependency
        final exampleButtonHeight = (52.0 * uiScaleFactor).clamp(
          44.0,
          52.0 * 1.1,
        );
        final exampleIconSize =
            24.0 * scaleFactor; // Icons use proportional scaling
        final examplePadding = 16.0 * uiScaleFactor;
        final exampleBorderRadius = 8.0 * uiScaleFactor;

        print('═══════════════════════════════════════════════════════════');
        print('📱 DEVICE SCREEN SIZE & SCALING INFORMATION');
        print('═══════════════════════════════════════════════════════════');
        print('Screen Dimensions:');
        print('   Width:  ${screenWidth.toStringAsFixed(1)}px');
        print('   Height: ${screenHeight.toStringAsFixed(1)}px');
        print('');
        print('Base Design Width: ${baseDesignWidth}px (iPhone 12/13)');
        print(
          'Min No-Scale Width: ${minNoScaleWidth}px (devices >= this don\'t scale)',
        );
        print('');
        print('Scaling Calculations:');
        print(
          '   Base Factor:        ${baseFactor.toStringAsFixed(4)} (${(baseFactor * 100).toStringAsFixed(2)}%)',
        );
        print('   Intensity Applied:  $scalingIntensity');
        print('   Calculated Factor:  ${calculatedFactor.toStringAsFixed(4)}');
        print(
          '   Final Font Factor:  ${scaleFactor.toStringAsFixed(4)} (${(scaleFactor * 100).toStringAsFixed(2)}%)',
        );
        print(
          '   UI Element Factor: ${uiScaleFactor.toStringAsFixed(4)} (${(uiScaleFactor * 100).toStringAsFixed(2)}%)',
        );
        print('');
        print('Example Scaled Sizes:');
        print(
          '   Button Height (52px):  ${exampleButtonHeight.toStringAsFixed(1)}px',
        );
        print(
          '   Icon Size (24px):      ${exampleIconSize.toStringAsFixed(1)}px',
        );
        print(
          '   Padding (16px):        ${examplePadding.toStringAsFixed(1)}px',
        );
        print(
          '   Border Radius (8px):   ${exampleBorderRadius.toStringAsFixed(1)}px',
        );
        print('');
        print(
          'Device Type: ${screenWidth >= minNoScaleWidth ? "✅ Standard/Large (no scaling)" : "📱 Small Device (scaled down)"}',
        );
        print('═══════════════════════════════════════════════════════════');

        developer.log(
          '📱 Responsive Font Scaling - Screen Detected:\n'
          '   Screen Size: ${screenWidth.toStringAsFixed(1)}x${screenHeight.toStringAsFixed(1)}px\n'
          '   Base Width: ${baseDesignWidth}px\n'
          '   Min No-Scale: ${minNoScaleWidth}px\n'
          '   Scale Factor: ${scaleFactor.toStringAsFixed(3)} (${(scaleFactor * 100).toStringAsFixed(1)}%)\n'
          '   Device Type: ${screenWidth >= minNoScaleWidth ? "Standard/Large (no scaling)" : "Small (scaled down)"}',
          name: 'EcliniqTextStyles',
        );
      }
    }

    return scaleFactor;
  }

  /// Get responsive font size based on screen width
  /// @param baseFontSize - Original font size designed for iPhone 12/13
  /// @param context - BuildContext to access screen dimensions
  /// @param styleName - Optional style name for logging purposes
  /// @returns Scaled font size for smaller devices, original size for larger devices
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize, {
    String? styleName,
  }) {
    final scaleFactor = getFontScaleFactor(context, styleName: styleName);
    final scaledFontSize = (baseFontSize * scaleFactor).roundToDouble();

    // Log font size calculation for first occurrence of each style (only in debug mode)
    if (enableLogging && styleName != null) {
      final logKey = '${styleName}_$baseFontSize';
      if (!_loggedScreenSizes.containsKey(logKey)) {
        _loggedScreenSizes[logKey] = true;
        developer.log(
          '🔤 Font Size Calculation ($styleName):\n'
          '   Original Size: ${baseFontSize}px\n'
          '   Scaled Size: ${scaledFontSize}px\n'
          '   Difference: ${(scaledFontSize - baseFontSize).toStringAsFixed(1)}px',
          name: 'EcliniqTextStyles',
        );
      }
    }

    return scaledFontSize;
  }

  /// Apply responsive scaling to a TextStyle
  /// @param baseStyle - Original TextStyle designed for iPhone 12/13
  /// @param context - BuildContext to access screen dimensions
  /// @param styleName - Optional style name for logging purposes
  /// @returns TextStyle with scaled font size
  static TextStyle getResponsiveStyle(
    BuildContext context,
    TextStyle baseStyle, {
    String? styleName,
  }) {
    if (baseStyle.fontSize == null) {
      if (enableLogging) {
        developer.log(
          '⚠️  TextStyle has no fontSize, skipping responsive scaling${styleName != null ? " ($styleName)" : ""}',
          name: 'EcliniqTextStyles',
        );
      }
      return baseStyle;
    }

    final responsiveFontSize = getResponsiveFontSize(
      context,
      baseStyle.fontSize!,
      styleName: styleName,
    );

    return baseStyle.copyWith(fontSize: responsiveFontSize);
  }

  // ============================================
  // Responsive Sizing Utilities
  // Use these methods for responsive dimensions, spacing, and sizing
  // ============================================

  /// Get responsive size (height, width, padding, margin, etc.) based on screen width
  /// Uses the same scaling logic as font sizes for consistency
  /// @param baseSize - Original size designed for iPhone 12/13 (390px width)
  /// @param context - BuildContext to access screen dimensions
  /// @param minSize - Optional minimum size to prevent elements from becoming too small
  /// @param maxSize - Optional maximum size to prevent elements from becoming too large
  /// @param useProportionalScaling - If true, uses proportional scaling. If false, uses less aggressive scaling for UI elements
  /// @returns Scaled size for smaller devices, original size for larger devices
  static double getResponsiveSize(
    BuildContext context,
    double baseSize, {
    double? minSize,
    double? maxSize,
    bool useProportionalScaling = false,
  }) {
    final scaleFactor = getFontScaleFactor(context);

    // For UI elements like buttons and containers, use slightly less aggressive scaling
    // to maintain better touch targets and visual balance
    final uiScaleFactor = useProportionalScaling
        ? scaleFactor
        : (scaleFactor * 0.92).clamp(
            0.88,
            1.0,
          ); // Slightly less aggressive for UI elements

    double scaledSize = baseSize * uiScaleFactor;

    if (minSize != null && scaledSize < minSize) {
      scaledSize = minSize;
    }
    if (maxSize != null && scaledSize > maxSize) {
      scaledSize = maxSize;
    }

    return scaledSize.roundToDouble();
  }

  /// Get responsive button height
  /// @param baseHeight - Base button height (default: 52px for primary buttons, 46px for standard)
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive button height
  static double getResponsiveButtonHeight(
    BuildContext context, {
    double baseHeight = 52.0,
  }) {
    // Buttons should maintain good touch targets (minimum 44px recommended by Material Design)
    return getResponsiveSize(
      context,
      baseHeight,
      minSize: 44.0, // Minimum touch target size
      maxSize: baseHeight * 0.85, // Don't make buttons too large
    );
  }

  /// Get responsive padding value
  /// @param basePadding - Base padding value
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive padding value
  static double getResponsivePadding(BuildContext context, double basePadding) {
    return getResponsiveSize(context, basePadding);
  }

  /// Get responsive EdgeInsets (all sides)
  /// @param basePadding - Base padding for all sides
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive EdgeInsets
  static EdgeInsets getResponsiveEdgeInsetsAll(
    BuildContext context,
    double basePadding,
  ) {
    final padding = getResponsivePadding(context, basePadding);
    return EdgeInsets.all(padding);
  }

  /// Get responsive EdgeInsets (symmetric)
  /// @param horizontal - Base horizontal padding
  /// @param vertical - Base vertical padding
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive EdgeInsets
  static EdgeInsets getResponsiveEdgeInsetsSymmetric(
    BuildContext context, {
    required double horizontal,
    required double vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getResponsivePadding(context, horizontal),
      vertical: getResponsivePadding(context, vertical),
    );
  }

  /// Get responsive EdgeInsets (only)
  /// @param left - Base left padding
  /// @param top - Base top padding
  /// @param right - Base right padding
  /// @param bottom - Base bottom padding
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive EdgeInsets
  static EdgeInsets getResponsiveEdgeInsetsOnly(
    BuildContext context, {
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) {
    return EdgeInsets.only(
      left: getResponsivePadding(context, left),
      top: getResponsivePadding(context, top),
      right: getResponsivePadding(context, right),
      bottom: getResponsivePadding(context, bottom),
    );
  }

  /// Get responsive icon size
  /// @param baseSize - Base icon size
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    // Icons scale proportionally with fonts
    return getResponsiveSize(context, baseSize, useProportionalScaling: true);
  }

  /// Get responsive border radius
  /// @param baseRadius - Base border radius
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive border radius
  static double getResponsiveBorderRadius(
    BuildContext context,
    double baseRadius,
  ) {
    return getResponsiveSize(context, baseRadius);
  }

  /// Get responsive spacing (SizedBox height/width)
  /// @param baseSpacing - Base spacing value
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive spacing value
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    return getResponsiveSize(context, baseSpacing);
  }

  /// Get responsive container width
  /// @param baseWidth - Base container width
  /// @param context - BuildContext to access screen dimensions
  /// @param maxWidth - Optional maximum width
  /// @returns Responsive container width
  static double getResponsiveWidth(
    BuildContext context,
    double baseWidth, {
    double? maxWidth,
  }) {
    return getResponsiveSize(context, baseWidth, maxSize: maxWidth);
  }

  /// Get responsive container height
  /// @param baseHeight - Base container height
  /// @param context - BuildContext to access screen dimensions
  /// @param minHeight - Optional minimum height
  /// @param maxHeight - Optional maximum height
  /// @returns Responsive container height
  static double getResponsiveHeight(
    BuildContext context,
    double baseHeight, {
    double? minHeight,
    double? maxHeight,
  }) {
    return getResponsiveSize(
      context,
      baseHeight,
      minSize: minHeight,
      maxSize: maxHeight,
    );
  }

  /// Get responsive size (width and height)
  /// @param baseWidth - Base width
  /// @param baseHeight - Base height
  /// @param context - BuildContext to access screen dimensions
  /// @returns Responsive Size object
  static Size getResponsiveSizeObject(
    BuildContext context, {
    required double baseWidth,
    required double baseHeight,
  }) {
    return Size(
      getResponsiveWidth(context, baseWidth),
      getResponsiveHeight(context, baseHeight),
    );
  }

static const TextStyle headlineXLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle titleInitial = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineLargeBold = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineZMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineBMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );
  static const TextStyle headlineXMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );
  static const TextStyle headlineXLMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w300,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,

    decoration: TextDecoration.none,
  );

  static const TextStyle bodyMediumProminent = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle bodySmallProminent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle bodyXSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle bodyXSmallProminent = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle body2xSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle body2xSmallProminent = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle body2xSmallRegular = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle titleXBLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle titleXLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    letterSpacing: 0.01,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle buttonXLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle buttonXLargeProminent = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle buttonMediumProminent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelMediumProminent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelSmallProminent = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelXSmall = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelXSmallProminent = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineXXLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineXXLargeBold = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  static const TextStyle headlineXXXLarge = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    fontFamily: fontFamily,
    fontStyle: FontStyle.normal,
    decoration: TextDecoration.none,
  );

  // ============================================
  // Responsive Text Style Methods
  // Use these methods when you need responsive font scaling
  // ============================================

  /// Get responsive headlineXLarge style
  static TextStyle responsiveHeadlineXLarge(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineXLarge,
      styleName: 'headlineXLarge',
    );
  }

  /// Get responsive titleInitial style
  static TextStyle responsiveTitleInitial(BuildContext context) {
    return getResponsiveStyle(context, titleInitial, styleName: 'titleInitial');
  }

  /// Get responsive headlineLarge style
  static TextStyle responsiveHeadlineLarge(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineLarge,
      styleName: 'headlineLarge',
    );
  }

  /// Get responsive headlineLargeBold style
  static TextStyle responsiveHeadlineLargeBold(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineLargeBold,
      styleName: 'headlineLargeBold',
    );
  }

  /// Get responsive headlineZMedium style
  static TextStyle responsiveHeadlineZMedium(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineZMedium,
      styleName: 'headlineZMedium',
    );
  }

  /// Get responsive headlineBMedium style
  static TextStyle responsiveHeadlineBMedium(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineBMedium,
      styleName: 'headlineBMedium',
    );
  }

  /// Get responsive headlineMedium style
  static TextStyle responsiveHeadlineMedium(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineMedium,
      styleName: 'headlineMedium',
    );
  }

  /// Get responsive headlineXMedium style
  static TextStyle responsiveHeadlineXMedium(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineXMedium,
      styleName: 'headlineXMedium',
    );
  }

  /// Get responsive headlineXLMedium style
  static TextStyle responsiveHeadlineXLMedium(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineXLMedium,
      styleName: 'headlineXLMedium',
    );
  }

  /// Get responsive headlineSmall style
  static TextStyle responsiveHeadlineSmall(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineSmall,
      styleName: 'headlineSmall',
    );
  }

  /// Get responsive bodyLarge style
  static TextStyle responsiveBodyLarge(BuildContext context) {
    return getResponsiveStyle(context, bodyLarge, styleName: 'bodyLarge');
  }

  /// Get responsive bodyMedium style
  static TextStyle responsiveBodyMedium(BuildContext context) {
    return getResponsiveStyle(context, bodyMedium, styleName: 'bodyMedium');
  }

  /// Get responsive bodyMediumProminent style
  static TextStyle responsiveBodyMediumProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      bodyMediumProminent,
      styleName: 'bodyMediumProminent',
    );
  }

  /// Get responsive bodySmall style
  static TextStyle responsiveBodySmall(BuildContext context) {
    return getResponsiveStyle(context, bodySmall, styleName: 'bodySmall');
  }

  /// Get responsive bodySmallProminent style
  static TextStyle responsiveBodySmallProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      bodySmallProminent,
      styleName: 'bodySmallProminent',
    );
  }

  /// Get responsive bodyXSmall style
  static TextStyle responsiveBodyXSmall(BuildContext context) {
    return getResponsiveStyle(context, bodyXSmall, styleName: 'bodyXSmall');
  }

  /// Get responsive bodyXSmallProminent style
  static TextStyle responsiveBodyXSmallProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      bodyXSmallProminent,
      styleName: 'bodyXSmallProminent',
    );
  }

  /// Get responsive body2xSmall style
  static TextStyle responsiveBody2xSmall(BuildContext context) {
    return getResponsiveStyle(context, body2xSmall, styleName: 'body2xSmall');
  }

  /// Get responsive body2xSmallProminent style
  static TextStyle responsiveBody2xSmallProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      body2xSmallProminent,
      styleName: 'body2xSmallProminent',
    );
  }

  /// Get responsive body2xSmallRegular style
  static TextStyle responsiveBody2xSmallRegular(BuildContext context) {
    return getResponsiveStyle(
      context,
      body2xSmallRegular,
      styleName: 'body2xSmallRegular',
    );
  }

  /// Get responsive titleXBLarge style
  static TextStyle responsiveTitleXBLarge(BuildContext context) {
    return getResponsiveStyle(context, titleXBLarge, styleName: 'titleXBLarge');
  }

  /// Get responsive titleXLarge style
  static TextStyle responsiveTitleXLarge(BuildContext context) {
    return getResponsiveStyle(context, titleXLarge, styleName: 'titleXLarge');
  }

  /// Get responsive titleMedium style
  static TextStyle responsiveTitleMedium(BuildContext context) {
    return getResponsiveStyle(context, titleMedium, styleName: 'titleMedium');
  }

  /// Get responsive titleSmall style
  static TextStyle responsiveTitleSmall(BuildContext context) {
    return getResponsiveStyle(context, titleSmall, styleName: 'titleSmall');
  }

  /// Get responsive buttonXLarge style
  static TextStyle responsiveButtonXLarge(BuildContext context) {
    return getResponsiveStyle(context, buttonXLarge, styleName: 'buttonXLarge');
  }

  /// Get responsive buttonXLargeProminent style
  static TextStyle responsiveButtonXLargeProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      buttonXLargeProminent,
      styleName: 'buttonXLargeProminent',
    );
  }

  /// Get responsive buttonLarge style
  static TextStyle responsiveButtonLarge(BuildContext context) {
    return getResponsiveStyle(context, buttonLarge, styleName: 'buttonLarge');
  }

  /// Get responsive buttonMedium style
  static TextStyle responsiveButtonMedium(BuildContext context) {
    return getResponsiveStyle(context, buttonMedium, styleName: 'buttonMedium');
  }

  /// Get responsive buttonMediumProminent style
  static TextStyle responsiveButtonMediumProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      buttonMediumProminent,
      styleName: 'buttonMediumProminent',
    );
  }

  /// Get responsive buttonSmall style
  static TextStyle responsiveButtonSmall(BuildContext context) {
    return getResponsiveStyle(context, buttonSmall, styleName: 'buttonSmall');
  }

  /// Get responsive labelMedium style
  static TextStyle responsiveLabelMedium(BuildContext context) {
    return getResponsiveStyle(context, labelMedium, styleName: 'labelMedium');
  }

  /// Get responsive labelMediumProminent style
  static TextStyle responsiveLabelMediumProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      labelMediumProminent,
      styleName: 'labelMediumProminent',
    );
  }

  /// Get responsive labelSmall style
  static TextStyle responsiveLabelSmall(BuildContext context) {
    return getResponsiveStyle(context, labelSmall, styleName: 'labelSmall');
  }

  /// Get responsive labelSmallProminent style
  static TextStyle responsiveLabelSmallProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      labelSmallProminent,
      styleName: 'labelSmallProminent',
    );
  }

  /// Get responsive labelXSmall style
  static TextStyle responsiveLabelXSmall(BuildContext context) {
    return getResponsiveStyle(context, labelXSmall, styleName: 'labelXSmall');
  }

  /// Get responsive labelXSmallProminent style
  static TextStyle responsiveLabelXSmallProminent(BuildContext context) {
    return getResponsiveStyle(
      context,
      labelXSmallProminent,
      styleName: 'labelXSmallProminent',
    );
  }

  /// Get responsive headlineXXLarge style
  static TextStyle responsiveHeadlineXXLarge(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineXXLarge,
      styleName: 'headlineXXLarge',
    );
  }

  /// Get responsive headlineXXLargeBold style
  static TextStyle responsiveHeadlineXXLargeBold(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineXXLargeBold,
      styleName: 'headlineXXLargeBold',
    );
  }

  /// Get responsive headlineXXXLarge style
  static TextStyle responsiveHeadlineXXXLarge(BuildContext context) {
    return getResponsiveStyle(
      context,
      headlineXXXLarge,
      styleName: 'headlineXXXLarge',
    );
  }
}
