import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class DeleteFileBottomSheet extends StatelessWidget {
  const DeleteFileBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        EcliniqTextStyles.getResponsivePadding(context, 16),
        EcliniqTextStyles.getResponsivePadding(context, 16),
        EcliniqTextStyles.getResponsivePadding(context, 16),
        MediaQuery.of(context).viewInsets.bottom + EcliniqTextStyles.getResponsivePadding(context, 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: EcliniqTextStyles.getResponsiveWidth(context, 142),
            height: EcliniqTextStyles.getResponsiveHeight(context, 110),
            child: SvgPicture.asset(EcliniqIcons.deleteFile.assetPath),
          ),

          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          ),
          Text(
            'Are you sure you want delete Selected files?',
            textAlign: TextAlign.center,
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
          Text(
            'Once file is deleted can\'t be restored',
            style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
            
              fontWeight: FontWeight.w400,
              color: Color(0xFF626060),
            ),
          ),

          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
          ),
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              left: 4.0,
              right: 4.0,
              top: 0,
              bottom: 0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: false).pop(true);
                    },
                    child: Container(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFEB8B85),
                          width: 0.5,
                        ),
                        color: const Color(0xFFFFF8F8),
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                        ),
                      ),
                      child:  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Yes',
                            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                  
                              fontWeight: FontWeight.w500,
                              color: Color(0xffF04248),
                            ),
                          ),
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: EcliniqTextStyles.getResponsiveSpacing(context, 12),
                ),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context, rootNavigator: false).pop(false);
                    },
                    child: Container(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                        context,
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xff8E8E8E),
                          width: 0.5,
                        ),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                        ),
                      ),
                      child:  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No',
                            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                            
                              fontWeight: FontWeight.w500,
                              color: Color(0xff424242),
                            ),
                          ),
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
