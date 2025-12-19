import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:flutter/material.dart';

class ProfilePhotoSelector extends StatelessWidget {
  const ProfilePhotoSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(16)),
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              EcliniqText(
                'Add Profile Photo',
                style: EcliniqTextStyles.titleXLarge.copyWith(
                  fontSize: 18,
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

          const SizedBox(height: 10),
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
          border: Border.all(color: Color(0xff8E8E8E)),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: EcliniqTextStyles.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xff424242),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
