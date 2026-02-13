import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/prescription_card_timeline.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class UploadTimeline extends StatefulWidget {
  const UploadTimeline({super.key});

  @override
  State<UploadTimeline> createState() => _UploadTimelineState();
}

class _UploadTimelineState extends State<UploadTimeline> {
  bool _isExpanded = false;

  double _getExpandTimelineTopPadding(int fileCount) {
    return 8.0;
  }

  double _getStackHeight(int fileCount) {
    switch (fileCount) {
      case 1:
        return 100.0;
      case 2:
        return 165.0;
      case 3:
        return 230.0;
      default:
        return 100.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthFilesProvider>(
      builder: (context, provider, child) {
        final recentFiles = provider.getRecentlyUploadedFiles(limit: 10);

        if (recentFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayFiles = _isExpanded
            ? recentFiles
            : recentFiles.take(3).toList();
        final showExpandButton = recentFiles.length >= 3;

        return Container(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
            context,
            left: 16,
            right: 16,
            top: 24,
            bottom: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upload Timeline',
                    style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          color: Color(0xff424242),
                        ),
                  ),
                  if (_isExpanded)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = false;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            'Collapse',
                            style: EcliniqTextStyles.responsiveHeadlineXMedium(
                              context,
                            ).copyWith(color: Color(0xff2372EC),fontWeight: FontWeight.w400),
                          ),
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              8,
                            ),
                          ),
                          Container(
                            width: 0.5,
                            height: EcliniqTextStyles.getResponsiveSize(
                              context,
                              20,
                            ),
                            color: Color(0xff96BFFF),
                          ),
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveSpacing(
                              context,
                              8,
                            ),
                          ),
                          SvgPicture.asset(
                            EcliniqIcons.arrowUp.assetPath,
                            width: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              20,
                            ),
                            height: EcliniqTextStyles.getResponsiveIconSize(
                              context,
                              20,
                            ),
                            color: Color(0xff2372EC),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
              ),

              // Show stacked cards or timeline list based on expansion state
              if (!_isExpanded)
                // Stacked cards view (original design)
                SizedBox(
                  height: _getStackHeight(displayFiles.length),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (displayFiles.length >= 3)
                        Positioned(
                          top: 130,
                          left: 20,
                          right: 20,
                          child: Opacity(
                            opacity: 0.65,
                            child: Transform.scale(
                              scale: 0.95,
                              child: PrescriptionCardTimeline(
                                file: displayFiles[2],
                                isOlder: true,
                                showShadow: false,
                                headingFontSize: 16,
                                subheadingFontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      if (displayFiles.length >= 2)
                        Positioned(
                          top: 65,
                          left: 12,
                          right: 12,
                          child: Transform.scale(
                            scale: 0.97,
                            child: PrescriptionCardTimeline(
                              file: displayFiles[1],
                              headingFontSize: 17,
                              subheadingFontSize: 13,
                            ),
                          ),
                        ),
                      if (displayFiles.isNotEmpty)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: PrescriptionCardTimeline(
                            file: displayFiles[0],
                            headingFontSize: 18,
                            subheadingFontSize: 14,
                          ),
                        ),
                    ],
                  ),
                )
              else
                // Expanded timeline view with vertical line
                Column(
                  children: [
                    for (int i = 0; i < displayFiles.length; i++)
                      TimelineItemWithLine(
                        file: displayFiles[i],
                        isFirst: i == 0,
                        isLast: i == displayFiles.length - 1,
                      ),
                  ],
                ),

              if (!_isExpanded && showExpandButton) ...[
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(
                    context,
                    _getExpandTimelineTopPadding(displayFiles.length),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Expand Timeline',
                        style: EcliniqTextStyles.responsiveHeadlineXMedium(
                          context,
                        ).copyWith(color: EcliniqScaffold.darkBlue),
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          8,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: EcliniqTextStyles.getResponsiveSize(
                          context,
                          20,
                        ),
                        color: EcliniqScaffold.darkBlue,
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          8,
                        ),
                      ),
                      SvgPicture.asset(
                        EcliniqIcons.arrowDown.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          20,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          20,
                        ),
                        color: EcliniqScaffold.darkBlue,
                      ),
                    ],
                  ),
                ),
              ],

              if (_isExpanded && recentFiles.length > 10) ...[
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                ),
                GestureDetector(
                  onTap: () {
                    // Load more functionality
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Load More',
                        style: EcliniqTextStyles.responsiveHeadlineXMedium(
                          context,
                        ).copyWith(color: EcliniqScaffold.darkBlue),
                      ),
                      SizedBox(
                        width: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          8,
                        ),
                      ),
                      SvgPicture.asset(
                        EcliniqIcons.arrowDown.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          20,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          20,
                        ),
                        color: EcliniqScaffold.darkBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class TimelineItemWithLine extends StatelessWidget {
  final dynamic file;
  final bool isFirst;
  final bool isLast;

  const TimelineItemWithLine({
    super.key,
    required this.file,
    this.isFirst = false,
    this.isLast = false,
  });

  String _formatDay(DateTime date) {
    return date.day.toString().padLeft(2, '0');
  }

  String _formatMonth(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = file.fileDate ?? file.createdAt;
    final day = _formatDay(displayDate);
    final month = _formatMonth(displayDate);

    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column (left side)
          SizedBox(
            width: EcliniqTextStyles.getResponsiveWidth(context, 40),
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                top: 20,
                left: 0,
                right: 0,
                bottom: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: EcliniqTextStyles.responsiveHeadlineMedium(context)
                        .copyWith(
                          color: Color(0xff424242),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    month,
                    style: EcliniqTextStyles.responsiveBodySmallProminent(
                      context,
                    ).copyWith(color: Color(0xff8E8E8E)),
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              // Top line (always show, including for first item)
              Container(
                width: 1,
                height: EcliniqTextStyles.getResponsiveSize(context, 32),
                color: Color(0xffD6D6D6),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 5),
              ),
              // Dot
              Container(
                width: EcliniqTextStyles.getResponsiveSize(context, 12),
                height: EcliniqTextStyles.getResponsiveSize(context, 12),
                decoration: BoxDecoration(
                  color: Color(0xffD6D6D6),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 5),
              ),

              // Bottom line (always show, including for last item)
              Expanded(child: Container(width: 1, color: Color(0xffD6D6D6))),
            ],
          ),

          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8)),

          // Card (right side)
          Expanded(
            child: Padding(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                context,
                bottom: 12,
                left: 0,
                right: 0,
                top: 0,
              ),
              child: PrescriptionCardTimeline(
                file: file,
                headingFontSize: 18,
                subheadingFontSize: 14,
                showTimeline: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
