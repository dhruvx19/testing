import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';

class ProfilePhotoSelector extends StatelessWidget {
  const ProfilePhotoSelector({super.key, required this.hasPhoto});

  final bool hasPhoto;

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EcliniqText(
                hasPhoto ? 'Change Profile Photo' : 'Add Profile Photo',
                style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                  fontWeight: FontWeight.w500,
                  color: Color(0xff424242),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _buildPhotoOption(
            context: context,
            title: 'Take Photo',
            onTap: () => Navigator.pop(context, 'take_photo'),
          ),

          const SizedBox(height: 12),

          _buildPhotoOption(
            context: context,
            title: 'Upload Photo',
            onTap: () => Navigator.pop(context, 'upload_photo'),
          ),

          if (hasPhoto) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context, 'delete_photo'),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F8),
                  border: Border.all(color: const Color(0xffEB8B85), width: 0.5),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Delete Photo',
                      style: EcliniqTextStyles.responsiveHeadlineBMedium(
                        context,
                      ).copyWith(
                        color: const Color(0xffF04248),
                        fontWeight: FontWeight.w500,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoOption({
    required BuildContext context,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xff8E8E8E), width: 0.5),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: EcliniqTextStyles.responsiveHeadlineBMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w500, color: const Color(0xff424242)),
            ),
          ],
        ),
      ),
    );
  }
}
