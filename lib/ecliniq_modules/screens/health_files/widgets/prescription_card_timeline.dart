import 'dart:io';

import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class PrescriptionCardTimeline extends StatelessWidget {
  final HealthFile file;
  final bool isOlder;
  final bool showShadow;
  final double headingFontSize;
  final double subheadingFontSize;

  const PrescriptionCardTimeline({
    super.key,
    required this.file,
    this.isOlder = false,
    this.showShadow = true,
    this.headingFontSize = 18,
    this.subheadingFontSize = 14,
  });

  String _formatDay(DateTime date) {
    return date.day.toString().padLeft(2, '0');
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  String _getFileTypeDisplayName() {
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
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
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
                  SizedBox(width: 2),
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

  @override
  Widget build(BuildContext context) {
    final displayDate = file.fileDate ?? file.createdAt;
    final day = _formatDay(displayDate);
    final month = _formatMonth(displayDate);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffD6D6D6)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0x33000000),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                      .copyWith(
                        color: isOlder
                            ? Colors.grey[400]
                            : const Color(0xff424242),
                      ),
                ),
                Text(
                  month,
                  style: EcliniqTextStyles.responsiveBodySmallProminent(context)
                      .copyWith(
                        color: isOlder ? Colors.grey[400] : Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 2),
          _buildThumbnail(context),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: TextStyle(
                    fontSize: headingFontSize,
                    fontWeight: FontWeight.w500,
                    color: isOlder ? Colors.grey[500] : const Color(0xff424242),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileTypeDisplayName(),
                  style: TextStyle(
                    fontSize: subheadingFontSize,
                    fontWeight: FontWeight.w400,
                    color: isOlder ? Colors.grey[400] : const Color(0xff8E8E8E),
                  ),
                ),
              ],
            ),
          ),
          SvgPicture.asset(
            EcliniqIcons.healthIcon.assetPath,
            width: 32,
            height: 32,
          ),
        ],
      ),
    );
  }
}
