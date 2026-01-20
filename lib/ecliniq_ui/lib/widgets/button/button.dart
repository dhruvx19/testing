import 'package:ecliniq/ecliniq_ui/lib/theme_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/shimmer/shimmer_loading.dart';
import 'package:flutter/material.dart';

enum EcliniqButtonType {
  brandPrimary,
  brandSecondary,
  brandTertiary,
  successPrimary,
  successSecondary,
  successTertiary,
  destructivePrimary,
  destructiveSecondary,
  destructiveTertiary,
  outlined,
  transparent;

  Color textColor(BuildContext context) {
    switch (this) {
      case EcliniqButtonType.brandPrimary:
      case EcliniqButtonType.successPrimary:
      case EcliniqButtonType.destructivePrimary:
        return context.colors.textFixedLight;
      case EcliniqButtonType.brandSecondary:
      case EcliniqButtonType.brandTertiary:
        return context.colors.textPrimary;
      case EcliniqButtonType.successSecondary:
      case EcliniqButtonType.successTertiary:
        return context.colors.textSuccess;
      case EcliniqButtonType.destructiveSecondary:
        return context.colors.textDestructive;
      case EcliniqButtonType.destructiveTertiary:
        return context.colors.textDestructiveBold;
      case EcliniqButtonType.outlined:
        return context.colors.strokeNeutral;
      case EcliniqButtonType.transparent:
        return context.colors.textPrimary;
    }
  }

  Color backgroundColor(BuildContext context) {
    switch (this) {
      case EcliniqButtonType.brandPrimary:
        return context.colors.bgContainerInteractiveBrand;
      case EcliniqButtonType.brandSecondary:
        return context.colors.bgContainerInteractiveBrandSubtle;
      case EcliniqButtonType.brandTertiary:
        return context.colors.bgContainerInteractiveBrandExtraSubtle;
      case EcliniqButtonType.successPrimary:
        return context.colors.bgContainerInteractiveSuccess;
      case EcliniqButtonType.successSecondary:
        return context.colors.bgContainerInteractiveSuccessSubtle;
      case EcliniqButtonType.successTertiary:
        return context.colors.bgContainerInteractiveSuccessExtraSubtle;
      case EcliniqButtonType.destructivePrimary:
        return context.colors.bgContainerInteractiveDestructive;
      case EcliniqButtonType.destructiveSecondary:
        return context.colors.bgContainerInteractiveDestructiveSubtle;
      case EcliniqButtonType.destructiveTertiary:
        return context.colors.bgContainerInteractiveDestructiveExtraSubtle;
      case EcliniqButtonType.outlined:
        return context.colors.bgBaseBase;
      case EcliniqButtonType.transparent:
        return Colors.transparent;
    }
  }

  Color pressedBackgroundColor(BuildContext context) {
    switch (this) {
      case EcliniqButtonType.brandPrimary:
        return context.colors.bgContainerInteractiveBrandPressed;
      case EcliniqButtonType.brandSecondary:
        return context.colors.bgContainerInteractiveBrandSubtlePressed;
      case EcliniqButtonType.brandTertiary:
        return context.colors.bgContainerInteractiveNeutralSubtlePressed;
      case EcliniqButtonType.successPrimary:
        return context.colors.bgContainerInteractiveSuccessPressed;
      case EcliniqButtonType.successSecondary:
        return context.colors.bgContainerInteractiveSuccessSubtlePressed;
      case EcliniqButtonType.successTertiary:
        return context.colors.bgContainerInteractiveNeutralSubtlePressed;
      case EcliniqButtonType.destructivePrimary:
        return context.colors.bgContainerInteractiveDestructivePressed;
      case EcliniqButtonType.destructiveSecondary:
        return context.colors.bgContainerInteractiveDestructiveSubtlePressed;
      case EcliniqButtonType.destructiveTertiary:
        return context.colors.bgContainerInteractiveNeutralSubtlePressed;
      case EcliniqButtonType.outlined:
        return context.colors.bgBaseOverlay;
      case EcliniqButtonType.transparent:
        return Colors.transparent;
    }
  }

  Color borderColor(BuildContext context) {
    switch (this) {
      case EcliniqButtonType.brandPrimary:
        return context.colors.bgContainerInteractiveBrand;
      case EcliniqButtonType.brandSecondary:
        return context.colors.strokeBrand;
      case EcliniqButtonType.brandTertiary:
        return context.colors.bgContainerInteractiveBrandExtraSubtle;
      case EcliniqButtonType.successPrimary:
        return context.colors.bgContainerInteractiveSuccess;
      case EcliniqButtonType.successSecondary:
        return context.colors.textSuccess;
      case EcliniqButtonType.successTertiary:
        return context.colors.bgContainerInteractiveSuccessExtraSubtle;
      case EcliniqButtonType.destructivePrimary:
        return context.colors.bgContainerInteractiveDestructive;
      case EcliniqButtonType.destructiveSecondary:
        return context.colors.textDestructive;
      case EcliniqButtonType.destructiveTertiary:
        return context.colors.bgContainerInteractiveDestructiveExtraSubtle;
      case EcliniqButtonType.outlined:
        return context.colors.strokeNeutral;
      case EcliniqButtonType.transparent:
        return Colors.transparent;
    }
  }

  Color pressedBorderColor(BuildContext context) {
    switch (this) {
      case EcliniqButtonType.brandPrimary:
        return context.colors.bgContainerInteractiveBrandPressed;
      case EcliniqButtonType.brandSecondary:
        return context.colors.strokeBrand;
      case EcliniqButtonType.brandTertiary:
        return context.colors.bgContainerInteractiveNeutralSubtlePressed;
      case EcliniqButtonType.successPrimary:
        return context.colors.bgContainerInteractiveSuccessPressed;
      case EcliniqButtonType.successSecondary:
        return context.colors.textSuccess;
      case EcliniqButtonType.successTertiary:
        return context.colors.bgContainerInteractiveNeutralSubtlePressed;
      case EcliniqButtonType.destructivePrimary:
        return context.colors.bgContainerInteractiveDestructivePressed;
      case EcliniqButtonType.destructiveSecondary:
        return context.colors.textDestructive;
      case EcliniqButtonType.destructiveTertiary:
        return context.colors.bgContainerInteractiveNeutralSubtlePressed;
      case EcliniqButtonType.outlined:
        return context.colors.strokeNeutral;
      case EcliniqButtonType.transparent:
        return Colors.transparent;
    }
  }

  Color disabledBackgroundColor(BuildContext context) {
    switch (this) {
      case EcliniqButtonType.brandPrimary:
      case EcliniqButtonType.successPrimary:
      case EcliniqButtonType.destructivePrimary:
        return context.colors.bgContainerInteractiveDisabled;
      case EcliniqButtonType.brandSecondary:
      case EcliniqButtonType.successSecondary:
      case EcliniqButtonType.destructiveSecondary:
        return context.colors.bgContainerInteractiveDisabledSubtle;
      case EcliniqButtonType.brandTertiary:
      case EcliniqButtonType.successTertiary:
      case EcliniqButtonType.destructiveTertiary:
      case EcliniqButtonType.outlined:
        return Colors.transparent;
      case EcliniqButtonType.transparent:
        return Colors.transparent;
    }
  }
}

class EcliniqButton extends StatelessWidget {
  final String label;
  final Widget? leading;
  final EcliniqButtonType type;
  final Widget? child;
  final VoidCallback? onPressed;
  final Size? size;
  final bool isLoading;
  final Color? borderColor;
  final Color? textColor;
  final OutlinedBorder? shape;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final Color? overlayColor;

  const EcliniqButton({
    super.key,
    this.label = '',
    this.leading,
    required this.type,
    this.onPressed,
    this.size,
    this.child,
    this.isLoading = false,
    this.borderColor,
    this.textColor,
    this.shape,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    // Get responsive button height (default 46px for standard buttons)
    final responsiveHeight = size?.height ?? 
        EcliniqTextStyles.getResponsiveButtonHeight(context, baseHeight: 46.0);
    
    // Get responsive border radius
    final responsiveBorderRadius = EcliniqTextStyles.getResponsiveBorderRadius(context, 8);
    
    // Get responsive padding
    final responsiveVerticalPadding = EcliniqTextStyles.getResponsivePadding(context, 10);
    final responsiveLoadingPadding = EcliniqTextStyles.getResponsivePadding(context, 16);
    
    // Get responsive spacing for leading icon
    final responsiveIconSpacing = EcliniqTextStyles.getResponsiveSpacing(context, 10);
    
    // Get responsive icon size for loading indicator
    final responsiveLoadingIconSize = EcliniqTextStyles.getResponsiveIconSize(context, 20);

    if (isLoading) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: responsiveLoadingPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
          ),
          elevation: 0,
          fixedSize: size ?? Size(
            MediaQuery.sizeOf(context).width,
            responsiveHeight,
          ),
          shadowColor: Colors.transparent,
          overlayColor: overlayColor,
        ),
        child: SizedBox(
          height: responsiveLoadingIconSize,
          width: responsiveLoadingIconSize,
          child: ShimmerLoading(
            width: responsiveLoadingIconSize,
            height: responsiveLoadingIconSize,
            borderRadius: BorderRadius.all(
              Radius.circular(responsiveLoadingIconSize / 2),
            ),
          ),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: responsiveVerticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
        ),
        side: onPressed == null
            ? null
            : BorderSide(
                color: borderColor ?? type.borderColor(context),
                width: 0.33,
              ),
        elevation: 0,
        backgroundColor: backgroundColor ?? type.backgroundColor(context),
        fixedSize: size ?? Size(
          MediaQuery.sizeOf(context).width,
          responsiveHeight,
        ),
        disabledBackgroundColor:
            disabledBackgroundColor ?? type.disabledBackgroundColor(context),
        shadowColor: Colors.transparent,
      ),
      child:
          child ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) leading!,
              if (leading != null) SizedBox(width: responsiveIconSpacing),
              Text(
                label,
                style: EcliniqTextStyles.responsiveButtonXLargeProminent(context).copyWith(
                  color: onPressed == null
                      ? context.colors.textDisabled
                      : textColor ?? type.textColor(context),
                ),
              ),
            ],
          ),
    );
  }
}



// // Add this property to your EcliniqButton class
// class EcliniqButton extends StatelessWidget {
//   final String label;
//   final Widget? leading;
//   final EcliniqButtonType type;
//   final Widget? child;
//   final VoidCallback? onPressed;
//   final Size? size;
//   final bool isLoading;
//   final Color? borderColor;
//   final Color? textColor;
//   final OutlinedBorder? shape;
//   final Color? backgroundColor;
//   final Color? disabledBackgroundColor;
//   final Color? overlayColor; // Add this line

//   const EcliniqButton({
//     super.key,
//     this.label = '',
//     this.leading,
//     required this.type,
//     this.onPressed,
//     this.size,
//     this.child,
//     this.isLoading = false,
//     this.borderColor,
//     this.textColor,
//     this.shape,
//     this.backgroundColor,
//     this.disabledBackgroundColor,
//     this.overlayColor, // Add this line
//   });

//   @override
//   Widget build(BuildContext context) {
//     // ... existing loading code ...
    
//     return ElevatedButton(
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//         side: onPressed == null
//             ? null
//             : BorderSide(
//                 color: borderColor ?? type.borderColor(context),
//                 width: 0.33,
//               ),
//         elevation: 0,
//         backgroundColor: backgroundColor ?? type.backgroundColor(context),
//         fixedSize: size ?? Size(MediaQuery.sizeOf(context).width, 46),
//         disabledBackgroundColor:
//             disabledBackgroundColor ?? type.disabledBackgroundColor(context),
//         shadowColor: Colors.transparent,
//         overlayColor: overlayColor != null 
//             ? WidgetStateProperty.all(overlayColor) 
//             : null, // Add this line
//       ),
//       child: // ... rest of your child code
//     );
//   }
// }
