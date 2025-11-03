import 'package:flutter/cupertino.dart';

import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:flutter/material.dart';

import '../../../../../ecliniq_ui/lib/tokens/styles.dart';

class AddProfilePhoto extends StatelessWidget {
  const AddProfilePhoto({super.key});

  @override
  Widget build(BuildContext context) {
    void _chooseFromGallery() {}
    void _takePhoto() {}
    return Container(
      decoration: BoxDecoration(
        color: EcliniqColors.light.bgBaseOverlay,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EcliniqColors.light.strokeNeutralSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 15),
            child: Text(
              'Add Profile Photo',
              style: EcliniqTextStyles.headlineBMedium.copyWith(
                color: EcliniqColors.light.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: EcliniqColors.light.strokeNeutralSubtle,
                width: 1,
              )
            ),
            child: TextButton(
              onPressed: _takePhoto,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Take photo',
                style: EcliniqTextStyles.bodyMedium.copyWith(
                  color: EcliniqColors.light.textPrimary,
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 15, left: 15, right: 15),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: EcliniqColors.light.strokeNeutralSubtle,
                  width: 1,
                )
            ),
            child: TextButton(
              onPressed: _chooseFromGallery,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.center,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Upload Photo',
                style: EcliniqTextStyles.bodyMedium.copyWith(
                  color: EcliniqColors.light.textPrimary,
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          )

        ],
      ),
    );
  }
}
