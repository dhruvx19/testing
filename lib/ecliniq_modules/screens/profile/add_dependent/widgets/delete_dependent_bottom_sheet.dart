import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DeleteDependentBottomSheet extends StatelessWidget {
  final String dependentName;

  const DeleteDependentBottomSheet({super.key, required this.dependentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(16),
        ),
      ),
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 22, bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Delete icon
          SizedBox(
            width: 115,
            height: 115,

            child: Image.asset(EcliniqIcons.deleteImage.assetPath),
          ),
          const SizedBox(height: 12),

          // Title
          EcliniqText(
            'Are you sure you want delete dependent?',
            style: EcliniqTextStyles.responsiveHeadlineXMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w500, color: Color(0xFF424242)),
            textAlign: TextAlign.center,
          ),


          // Confirmation message
          EcliniqText(
            'Once deleted can’t we recovered.',
            style: EcliniqTextStyles.responsiveTitleXBLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w400, color: Color(0xFF626060)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0),
            child: Row(
              children: [
                // Delete button
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, true); // Return true for delete
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xffEB8B85),
                          width: 0.5,
                        ),
                        color: Color(0xffFFF8F8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Delete',
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
                const SizedBox(width: 12),

                // No/Cancel button
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context, false); // Return false for cancel
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xff8E8E8E),
                          width: 0.5,
                        ),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
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
