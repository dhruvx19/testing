import 'dart:io';

import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_core/notifications/local_notifications.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/file_type_screen.dart';
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
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
            context,
            top: 2,
            bottom: 8,
            left: 16,
            right: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                  context,
                  right: 16,
                  left: 0,
                  top: 0,
                  bottom: 0,
                ),
                child: Text(
                  'Recently Uploaded',
                  style: EcliniqTextStyles.responsiveHeadlineLarge(context)
                      .copyWith(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff424242),
                      ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
              ),

              SizedBox(
                height: EcliniqTextStyles.getResponsiveHeight(context, 215),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
                    context,
                    right: 16,
                    left: 0,
                    top: 0,
                    bottom: 0,
                  ),
                  itemCount: recentFiles.length,
                  separatorBuilder: (context, index) => SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                  ),
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
    final displayDate = widget.file.fileDate ?? date;

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

  Future<void> _handleDownloadFile(
    BuildContext context,
    HealthFile file,
  ) async {
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.status;
      final manageStorageStatus = await Permission.manageExternalStorage.status;

      if (!storageStatus.isGranted && !manageStorageStatus.isGranted) {
        Permission storagePermission = Permission.storage;

        if (manageStorageStatus != PermissionStatus.permanentlyDenied) {
          storagePermission = Permission.manageExternalStorage;
        }

        final result = await storagePermission.request();

        if (!result.isGranted) {
          if (context.mounted) {
            if (result.isPermanentlyDenied) {
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

  Future<void> _proceedWithDownload(
    BuildContext context,
    HealthFile file,
  ) async {
    BuildContext? dialogContext;

    try {
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
            throw Exception(
              'Unable to access storage directory. Please check storage permissions.',
            );
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
          throw Exception(
            'File copy failed - destination file does not exist.',
          );
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
        final downloadsDir = Directory(
          path.join(documentsDir.path, 'Downloads'),
        );

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
          throw Exception(
            'File copy failed - destination file does not exist.',
          );
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
    BuildContext? dialogContext;

    try {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const Center(child: EcliniqLoader());
          },
        );
        // Wait for the dialog frame to render before starting the operation.
        await WidgetsBinding.instance.endOfFrame;
      }

      final provider = context.read<HealthFilesProvider>();

      final success = await provider.deleteFile(file);

      // Dismiss the dialog BEFORE calling refresh(). On iOS, refresh() triggers
      // a widget rebuild that removes this card from the tree, unmounting its
      // context. If we check context.mounted after refresh, it will be false
      // and the loader dialog will never be dismissed (infinite loading).
      if (dialogContext != null) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (e) {}
        dialogContext = null;
      }

      if (success && context.mounted) {
        await provider.refresh();
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
      if (dialogContext != null) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {}
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
        EcliniqRouter.push(FileTypeScreen(fileType: widget.file.fileType));
      },
      child: Container(
        width: EcliniqTextStyles.getResponsiveWidth(context, 250),
        height: EcliniqTextStyles.getResponsiveHeight(context, 215),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
          ),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  width: EcliniqTextStyles.getResponsiveWidth(context, 250),
                  height: EcliniqTextStyles.getResponsiveHeight(context, 215),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          12,
                        ),
                      ),
                      topRight: Radius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          12,
                        ),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          12,
                        ),
                      ),
                      topRight: Radius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          12,
                        ),
                      ),
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
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                  context,
                  10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      EcliniqTextStyles.getResponsiveBorderRadius(context, 12),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      _getFileIcon(),
                      width: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        24,
                      ),
                      height: EcliniqTextStyles.getResponsiveIconSize(
                        context,
                        24,
                      ),
                    ),
                    SizedBox(
                      width: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.fileName,
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF424242),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          FittedBox(
                            child: Text(
                              _formatDate(widget.file.createdAt),
                              style:
                                  EcliniqTextStyles.responsiveBodySmall(
                                    context,
                                  ).copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff8E8E8E),
                                  ),
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
                          onDownloadDocument: () =>
                              _handleDownloadFile(context, widget.file),
                          onDeleteDocument: () =>
                              _handleDeleteFile(context, widget.file),
                        ),
                      ),
                      child: SvgPicture.asset(
                        EcliniqIcons.threeDots.assetPath,
                        width: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          32,
                        ),
                        height: EcliniqTextStyles.getResponsiveIconSize(
                          context,
                          32,
                        ),
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
