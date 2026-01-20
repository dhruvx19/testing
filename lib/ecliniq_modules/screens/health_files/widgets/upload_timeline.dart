import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/file_type_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/prescription_card_timeline.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class UploadTimeline extends StatelessWidget {
  const UploadTimeline({super.key});

  /// Calculate the spacing between the last file and expand timeline
  /// Returns 16px spacing as requested
  double _getExpandTimelineTopPadding(int fileCount) {
    // Always return 16px spacing between files and expand timeline
    return 16.0;
  }
  
  /// Calculate the stack height based on number of files
  /// Ensures expand timeline is positioned correctly below the last file
  double _getStackHeight(int fileCount) {
    switch (fileCount) {
      case 1:
        // One file: stack height should accommodate the file + 16px spacing
        return 100.0; // Approximate card height
      case 2:
        // Two files: second file at top 65, needs space for card
        return 165.0; // 65 (top position) + ~100 (card height)
      case 3:
        // Three files: third file at top 130, needs space for card
        return 230.0; // 130 (top position) + ~100 (card height)
      default:
        return 100.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthFilesProvider>(
      builder: (context, provider, child) {
        final recentFiles = provider.getRecentlyUploadedFiles(limit: 3);

        if (recentFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 24.0,
            bottom: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Upload Timeline',
                style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
         
                  fontWeight: FontWeight.w600,
                  color: Color(0xff424242),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: _getStackHeight(recentFiles.length),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Third file (oldest, if exists)
                    if (recentFiles.length >= 3)
                      Positioned(
                        top: 130,
                        left: 20,
                        right: 20,
                        child: Opacity(
                          opacity: 0.65,
                          child: Transform.scale(
                            scale: 0.95,
                            child: PrescriptionCardTimeline(
                              file: recentFiles[2],
                              isOlder: true,
                              showShadow: false,
                              headingFontSize: 16,
                              subheadingFontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    // Second file (if exists)
                    if (recentFiles.length >= 2)
                      Positioned(
                        top: 65,
                        left: 12,
                        right: 12,
                        child: Transform.scale(
                          scale: 0.97,
                          child: PrescriptionCardTimeline(
                            file: recentFiles[1],
                            headingFontSize: 17,
                            subheadingFontSize: 13,
                          ),
                        ),
                      ),
                    // First file (latest)
                    if (recentFiles.isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: PrescriptionCardTimeline(
                          file: recentFiles[0],
                          headingFontSize: 18,
                          subheadingFontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              // 16px spacing between files and expand timeline
              SizedBox(
                height: _getExpandTimelineTopPadding(recentFiles.length),
              ),
              GestureDetector(
                onTap: () {
                  EcliniqRouter.push(const FileTypeScreen(fileType: null));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Expand Timeline',
                      style: EcliniqTextStyles.responsiveHeadlineXMedium(context).copyWith(
                        color: EcliniqScaffold.darkBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 20,
                      color: EcliniqScaffold.darkBlue,
                    ),
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      EcliniqIcons.arrowDown.assetPath,
                      width: 20,
                      height: 20,
                      color: EcliniqScaffold.darkBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
