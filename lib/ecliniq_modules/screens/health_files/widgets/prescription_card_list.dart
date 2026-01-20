import 'dart:io';

import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class PrescriptionCardList extends StatelessWidget {
  final HealthFile file;
  final bool isOlder;
  final double headingFontSize;
  final double subheadingFontSize;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  // Selection mode properties
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const PrescriptionCardList({
    super.key,
    required this.file,
    this.isOlder = false,
    this.headingFontSize = 18,
    this.subheadingFontSize = 14,
    this.onTap,
    this.onMenuTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  String _formatDay(DateTime date) {
    return date.day.toString().padLeft(2, '0');
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }


  String _getRecordForDisplay() {
    // Show "Uploaded for: [Name]" if recordFor exists, otherwise show file type
    if (file.recordFor != null && file.recordFor!.isNotEmpty) {
      return '${file.recordFor}';
    }
    return file.fileType.displayName;
  }

  Widget _buildThumbnail(BuildContext context) {
    final fileExists = File(file.filePath).existsSync();

    if (fileExists && file.isImage) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Color(0xffF69800), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(file.filePath),
            width: 50,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderThumbnail(context);
            },
          ),
        ),
      );
    }

    return _buildPlaceholderThumbnail(context);
  }

  Widget _buildPlaceholderThumbnail(BuildContext context) {
    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.abc,
                    size: EcliniqTextStyles.getResponsiveIconSize(context, 10),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Container(
                  height: 2,
                  width: double.infinity,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateColumn(String day, String month, BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            day,
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242)),
          ),
          Text(
            month,
            style: EcliniqTextStyles.responsiveBodySmall(
              context,
            ).copyWith(color: isOlder ? Colors.grey[400] : Colors.grey[600]),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final displayDate = file.fileDate ?? file.createdAt;
    final day = _formatDay(displayDate);
    final month = _formatMonth(displayDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xffD6D6D6), width: 0.5),
        ),
        child: Row(
          children: [
            // Show checkbox in selection mode, otherwise show date
            if (isSelectionMode)
              GestureDetector(
                onTap: onSelectionToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2372EC) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2372EC)
                          : const Color(0xFF8E8E8E),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: isSelected
                        ? SvgPicture.asset(
                            EcliniqIcons.vectorTicked.assetPath,
                            width: 10,
                            height: 10,
                          )
                        : null,
                  ),
                ),
              )
            else
              _buildDateColumn(day, month, context),

            const SizedBox(width: 12),
            _buildThumbnail(context),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
                          fontWeight: FontWeight.w500,
                          color: Color(0xff424242),
                        ),
                    maxLines: 1,
                    //overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    _getRecordForDisplay(),
                    style: EcliniqTextStyles.responsiveBodySmall(
                      context,
                    ).copyWith(color: Color(0xff8E8E8E)),
                  ),
                ],
              ),
            ),

            // Hide menu button in selection mode
            if (!isSelectionMode && onMenuTap != null)
              GestureDetector(
                onTap: onMenuTap,
                child: RotatedBox(
                  quarterTurns: 1,
                  child: SvgPicture.asset(
                    EcliniqIcons.threeDots.assetPath,
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
