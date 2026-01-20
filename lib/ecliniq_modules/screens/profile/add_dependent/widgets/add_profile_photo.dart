import 'dart:io';

import 'package:ecliniq/ecliniq_modules/screens/profile/add_dependent/provider/dependent_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddProfilePhoto extends StatelessWidget {
  const AddProfilePhoto({super.key});

  @override
  Widget build(BuildContext context) {
    void chooseFromGallery() async {
      Navigator.pop(context);
      final ImagePicker picker = ImagePicker();
      try {
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (pickedFile != null) {
          final provider = Provider.of<AddDependentProvider>(
            context,
            listen: false,
          );
          provider.setSelectedProfilePhoto(File(pickedFile.path));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
        }
      }
    }

    void takePhoto() async {
      Navigator.pop(context);
      final ImagePicker picker = ImagePicker();
      try {
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (pickedFile != null) {
          final provider = Provider.of<AddDependentProvider>(
            context,
            listen: false,
          );
          provider.setSelectedProfilePhoto(File(pickedFile.path));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
        }
      }
    }

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
              style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                color: EcliniqColors.light.textPrimary,
                fontWeight: FontWeight.w500,
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
              ),
            ),
            child: TextButton(
              onPressed: takePhoto,
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
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                  color: EcliniqColors.light.textPrimary,
                  fontWeight: FontWeight.w400,
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
              ),
            ),
            child: TextButton(
              onPressed: chooseFromGallery,
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
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                  color: EcliniqColors.light.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
