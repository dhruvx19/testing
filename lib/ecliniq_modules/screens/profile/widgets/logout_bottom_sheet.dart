import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';

class LogoutBottomSheet extends StatelessWidget {
  const LogoutBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 20.0),
          ),
          bottom: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 16.0),
          ),
        ),
      ),
      width: double.infinity,
      padding: EdgeInsets.only(
        left: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
        right: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
        top: EcliniqTextStyles.getResponsiveSpacing(context, 22.0),
        bottom: EcliniqTextStyles.getResponsiveSpacing(context, 40.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logout icon
          SizedBox(
            width: EcliniqTextStyles.getResponsiveSize(context, 100.0),
            height: EcliniqTextStyles.getResponsiveSize(context, 100.0),
            child: Image.asset(EcliniqIcons.logoutImage.assetPath),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),

          // Title
          EcliniqText(
            'Are you sure you want to logout?',
            style: EcliniqTextStyles.responsiveHeadlineXMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w500, color: Color(0xFF424242)),
            textAlign: TextAlign.center,
          ),

          // Confirmation message
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 22.0)),
          // Action buttons
          Padding(
            padding: EdgeInsets.only(
              left: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
              right: EcliniqTextStyles.getResponsiveSpacing(context, 4.0),
            ),
            child: Row(
              children: [
                // Logout button
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, true); // Return true for logout
                    },
                    child: Container(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 8.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xffEB8B85),
                          width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                        ),
                        color: Color(0xffFFF8F8),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Yes',
                            style:
                                EcliniqTextStyles.responsiveHeadlineMedium(
                                  context,
                                ).copyWith(
                                  color: Color(0xffF04248),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 12.0)),

                // No/Cancel button
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, false); // Return false for cancel
                    },
                    child: Container(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 8.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xff8E8E8E),
                          width: EcliniqTextStyles.getResponsiveSize(context, 0.5),
                        ),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No',
                            style: EcliniqTextStyles.responsiveHeadlineMedium(
                              context,
                            ).copyWith(color: Color(0xff424242)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
