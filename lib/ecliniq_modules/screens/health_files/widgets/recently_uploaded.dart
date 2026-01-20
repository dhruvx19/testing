import 'dart:io';

import 'package:ecliniq/ecliniq_core/notifications/local_notifications.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/file_type_screen.dart';
import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/utils/date_formatter.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/action_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/snackbar_helper.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class RecentlyUploadedWidget extends StatelessWidget {
  const RecentlyUploadedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthFilesProvider>(
      builder: (context, provider, child) {
        final recentFiles = provider.getRecentlyUploadedFiles(limit: 10);

        if (recentFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.only(left: 16.0, top: 2.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: Text(
                  'Recently Uploaded',
                  style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
                
                    fontWeight: FontWeight.bold,
                    color: Color(0xff424242),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 280,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 16.0),
                  itemCount: recentFiles.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return RecentFileCard(file: recentFiles[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RecentFileCard extends StatefulWidget {
  final HealthFile file;

  const RecentFileCard({super.key, required this.file});

  @override
  State<RecentFileCard> createState() => _RecentFileCardState();
}

class _RecentFileCardState extends State<RecentFileCard> {
  bool? _fileExists;

  @override
  void initState() {
    super.initState();
    // Check file existence asynchronously to avoid blocking build
    _checkFileExists();
  }

  Future<void> _checkFileExists() async {
    final exists = File(widget.file.filePath).existsSync();
    if (mounted) {
      setState(() {
        _fileExists = exists;
      });
    }
  }

  String _formatDate(DateTime date) {
    // Use fileDate if available, otherwise use createdAt
    final displayDate = widget.file.fileDate ?? date;
    // Format as "08/08/2025 | 9:30pm"
    return HealthFileDateFormatter.formatDateTime(displayDate);
  }

  String _getFileIcon() {
    if (widget.file.isImage) {
      return EcliniqIcons.pdffile.assetPath;
    } else if (widget.file.extension == 'pdf') {
      return EcliniqIcons.pdffile.assetPath;
    }
    return EcliniqIcons.pdffile.assetPath;
  }

  Future<void> _handleDownloadFile(BuildContext context, HealthFile file) async {
    debugPrint('_handleDownloadFile called for file: ${file.fileName}, id: ${file.id}');

    // Check storage permissions for Android - use default Android dialog like location
    if (Platform.isAndroid) {
      // Check both permission statuses
      final storageStatus = await Permission.storage.status;
      final manageStorageStatus = await Permission.manageExternalStorage.status;

      // If neither permission is granted, request permission using default Android dialog
      if (!storageStatus.isGranted && !manageStorageStatus.isGranted) {
        // Determine which permission to request
        Permission storagePermission = Permission.storage;
        
        // For Android 11+, try manageExternalStorage first if not permanently denied
        if (manageStorageStatus != PermissionStatus.permanentlyDenied) {
          storagePermission = Permission.manageExternalStorage;
        }

        // Request permission directly (shows default Android dialog)
        final result = await storagePermission.request();
        
        if (!result.isGranted) {
          if (context.mounted) {
            if (result.isPermanentlyDenied) {
              // Show dialog to open settings
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Storage Permission Required'),
                  content: const Text(
                    'Storage permission is permanently denied. Please enable it in app settings to download files.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await openAppSettings();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2372EC),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              );
            } else {
              SnackBarHelper.showErrorSnackBar(
                context,
                'Storage permission is required to download files',
                duration: const Duration(seconds: 2),
              );
            }
          }
          return;
        }
      }
    }

    await _proceedWithDownload(context, file);
  }

  Future<void> _proceedWithDownload(BuildContext context, HealthFile file) async {
    BuildContext? dialogContext;

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const Center(child: EcliniqLoader());
          },
        );
      }

      // Show "Download started" message
      SnackBarHelper.showSnackBar(
        context,
        Platform.isIOS
            ? 'Preparing file for download...'
            : 'Download started. We\'ll notify you when it\'s complete.',
        duration: const Duration(seconds: 2),
      );

      final sourceFile = File(file.filePath);

      if (!await sourceFile.exists()) {
        if (dialogContext != null && context.mounted) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }
        if (context.mounted) {
          SnackBarHelper.showErrorSnackBar(
            context,
            'File not found in storage',
            duration: const Duration(seconds: 2),
          );
        }
        return;
      }

      if (Platform.isAndroid) {
        Directory targetDir;
        final primaryDir = Directory('/storage/emulated/0/Download');
        if (await primaryDir.exists()) {
          targetDir = primaryDir;
        } else {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir == null) {
            throw Exception('Unable to access storage directory. Please check storage permissions.');
          }
          targetDir = Directory(path.join(externalDir.path, 'Download'));
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
        }

        String fileName = file.fileName;
        File destFile = File(path.join(targetDir.path, fileName));

        int counter = 1;
        while (await destFile.exists()) {
          final nameWithoutExt = path.basenameWithoutExtension(fileName);
          final ext = path.extension(fileName);
          fileName = '${nameWithoutExt}_$counter$ext';
          destFile = File(path.join(targetDir.path, fileName));
          counter++;
        }

        await sourceFile.copy(destFile.path);

        if (!await destFile.exists()) {
          throw Exception('File copy failed - destination file does not exist.');
        }

        if (dialogContext != null && context.mounted) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }

        if (context.mounted) {
          CustomSuccessSnackBar.show(
            context: context,
            title: 'Download successful',
            subtitle: 'File saved: $fileName',
            duration: const Duration(seconds: 3),
          );
        }

        await LocalNotifications.showDownloadSuccess(fileName: fileName);
        return;
      }

      if (Platform.isIOS) {
        final documentsDir = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory(path.join(documentsDir.path, 'Downloads'));

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        String fileName = file.fileName;
        File destFile = File(path.join(downloadsDir.path, fileName));

        int counter = 1;
        while (await destFile.exists()) {
          final nameWithoutExt = path.basenameWithoutExtension(fileName);
          final ext = path.extension(fileName);
          fileName = '${nameWithoutExt}_$counter$ext';
          destFile = File(path.join(downloadsDir.path, fileName));
          counter++;
        }

        await sourceFile.copy(destFile.path);

        if (!await destFile.exists()) {
          throw Exception('File copy failed - destination file does not exist.');
        }

        if (dialogContext != null && context.mounted) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        }

        if (context.mounted) {
          CustomSuccessSnackBar.show(
            context: context,
            title: 'Download successful',
            subtitle: 'File saved to app Downloads folder: $fileName',
            duration: const Duration(seconds: 3),
          );
        }

        await LocalNotifications.showDownloadSuccess(fileName: fileName);
        return;
      }
    } catch (e) {
      if (dialogContext != null && context.mounted) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      }

      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Download failed: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _handleDeleteFile(BuildContext context, HealthFile file) async {
    debugPrint('_handleDeleteFile called for file: ${file.fileName}, id: ${file.id}');
    BuildContext? dialogContext;

    try {
      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const Center(child: EcliniqLoader());
          },
        );
      }

      final provider = context.read<HealthFilesProvider>();

      debugPrint('Starting file deletion for: ${file.fileName}');
      // Delete the file (provider handles both physical file and metadata)
      final success = await provider.deleteFile(file);
      debugPrint('File deletion result: $success');

      // Refresh the file list to ensure UI updates
      if (success && context.mounted) {
        await provider.refresh();
      }

      // Close loading indicator - ensure it closes even if refresh fails
      if (dialogContext != null && context.mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (e) {
          debugPrint('Error closing loading dialog: $e');
        }
        dialogContext = null;
      }

      if (!context.mounted) return;

      if (success) {
        CustomSuccessSnackBar.show(
          context: context,
          title: 'Success',
          subtitle: 'File deleted successfully',
          duration: const Duration(seconds: 2),
        );
      } else {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Failed to delete file. Please try again.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Close loading indicator if still open
      if (dialogContext != null && context.mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {
          debugPrint('Error closing loading dialog in catch:');
        }
        dialogContext = null;
      }

      if (context.mounted) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Failed to delete file. Please try again.',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileExists = _fileExists ?? false;
    final filePath = widget.file.filePath;

    return GestureDetector(
      onTap: () {
        // Navigate to file type screen
        EcliniqRouter.push(FileTypeScreen(fileType: widget.file.fileType));
      },
      child: Container(
        width: 250,

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: fileExists && widget.file.isImage
                        ? Image.file(
                            File(filePath),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            cacheWidth: 640,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                EcliniqIcons.pdffile.assetPath,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                cacheWidth: 640,
                              );
                            },
                          )
                        : Image.asset(
                            EcliniqIcons.pdffile.assetPath,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            cacheWidth: 640,
                          ),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Image.asset(_getFileIcon(), width: 24, height: 24),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.fileName,
                            style:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                             
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF424242),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
               
                          Text(
                            _formatDate(widget.file.createdAt),
                            style:  EcliniqTextStyles.responsiveBodySmall(context).copyWith(
                       
                              fontWeight: FontWeight.w400,
                              color: Color(0xff8E8E8E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: () => EcliniqBottomSheet.show(
                        context: context,
                        child: ActionBottomSheet(
                          healthFile: widget.file,
                          parentContext: context,
                          onDownloadDocument: () => _handleDownloadFile(context, widget.file),
                          onDeleteDocument: () => _handleDeleteFile(context, widget.file),
                        ),
                      ),
                      child: SvgPicture.asset(
                        EcliniqIcons.threeDots.assetPath,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
