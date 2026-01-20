import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';


class EcliniqText extends StatelessWidget {
  const EcliniqText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.isSelectable = false,
    this.overflow,
    this.useResponsiveScaling = false,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool isSelectable;
  final TextOverflow? overflow;
  
  /// If true, automatically applies responsive font scaling based on screen size
  /// This scales down fonts for smaller devices while keeping original size for iPhone 12/13+
  final bool useResponsiveScaling;

  @override
  Widget build(BuildContext context) {
    TextStyle? finalStyle = style;
    
    // Apply responsive scaling if enabled and style has fontSize
    if (useResponsiveScaling && style != null && style!.fontSize != null) {
      finalStyle = EcliniqTextStyles.getResponsiveStyle(context, style!);
    }
    
    return isSelectable
        ? SelectionArea(
            child: Text(
              data,
              style: finalStyle,
              textAlign: textAlign,
              maxLines: maxLines,
              overflow: overflow,
            ),
          )
        : Text(
            data,
            style: finalStyle,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
  }
}
