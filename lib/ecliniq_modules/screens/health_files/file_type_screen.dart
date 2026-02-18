import 'dart:async';
import 'dart:io';

import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_core/notifications/local_notifications.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/action_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/permission_request_dialog.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/prescription_card_list.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/upload_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/health_files/delete_file_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/health_files/health_files_filter.dart';
import 'package:ecliniq/ecliniq_utils/snackbar_helper.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:ecliniq/ecliniq_utils/speech_helper.dart';

import '../../../ecliniq_icons/assets/home/widgets/top_bar_widgets/search_bar.dart';

class FileTypeScreen extends StatefulWidget {
  final HealthFileType? fileType;

  const FileTypeScreen({super.key, this.fileType});

  @override
  State<FileTypeScreen> createState() => _FileTypeScreenState();
}

class _FileTypeScreenState extends State<FileTypeScreen> {
  String? _selectedRecordFor;
  final Set<String> _selectedNames = {};
  final List<String> _recordForOptions = ['All'];
  HealthFileType? _selectedFileType;

  bool _isSelectionMode = false;
  final Set<String> _selectedFileIds = {};

  final ScrollController _tabScrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  final SpeechHelper _speechHelper = SpeechHelper();
  bool get _isListening => _speechHelper.isListening;
  String _searchQuery = '';
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _selectedFileType = widget.fileType;
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HealthFilesProvider>();
      provider.loadFiles().then((_) {
        _updateRecordForOptions();
      });
    });
    _initSpeech();
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    _searchController.dispose();
    _speechHelper.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    await _speechHelper.initSpeech(
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
      mounted: () => mounted,
    );
  }

  void _startListening() async {
    await _speechHelper.startListening(
      onResult: _onSpeechResult,
      onError: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
          );
        }
      },
      mounted: () => mounted,
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _stopListening() async {
    await _speechHelper.stopListening(
      onListeningChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _searchController.text = result.recognizedWords;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: result.recognizedWords.length),
    );

    setState(() {
      _searchQuery = result.recognizedWords;
    });

    _onSearchChanged();

    if (result.finalResult) {
      _stopListening();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      _isSearchMode = _searchQuery.isNotEmpty;
    });
    context.read<HealthFilesProvider>().searchFiles(_searchQuery);
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _isSearchMode = false;
    });
    context.read<HealthFilesProvider>().searchFiles('');
    if (_isListening) {
      _stopListening();
    }
  }

  void _toggleVoiceSearch() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _updateRecordForOptions() {
    final provider = context.read<HealthFilesProvider>();
    final options = provider.getRecordForOptions(_selectedFileType);
    setState(() {
      _recordForOptions.clear();
      _recordForOptions.add('All');
      _recordForOptions.addAll(options);
    });
  }

  void _onFileTypeSelected(HealthFileType? fileType) {
    setState(() {
      _selectedFileType = fileType;
      _selectedRecordFor = null;
      _selectedNames.clear();
    });
    _updateRecordForOptions();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFileIds.clear();
      }
    });
  }

  void _toggleFileSelection(HealthFile file) {
    setState(() {
      if (_selectedFileIds.contains(file.id)) {
        _selectedFileIds.remove(file.id);
      } else {
        _selectedFileIds.add(file.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedFileIds.clear();
    });
  }

  Future<void> _handleBulkDelete(List<HealthFile> files) async {
    if (_selectedFileIds.isEmpty) return;

    if (Platform.isAndroid) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final externalDir = await getExternalStorageDirectory();

        final hasExternalFiles = files.any((f) {
          if (!_selectedFileIds.contains(f.id)) return false;

          final isInAppDir =
              f.filePath.startsWith(appDir.path) ||
              (externalDir != null && f.filePath.startsWith(externalDir.path));
          return !isInAppDir;
        });

        if (hasExternalFiles) {
          final status = await Permission.storage.status;

          if (!status.isGranted) {
            if (!mounted) return;

            final result = await Permission.storage.request();

            if (!result.isGranted) {
              if (!mounted) return;

              await showDialog(
                context: context,
                builder: (context) => PermissionRequestDialog(
                  permission: Permission.storage,
                  title: 'Storage Permission Required',
                  message:
                      'We need storage permission to delete files from your device.',
                  onGranted: () async {
                    await _proceedWithBulkDelete(files);
                  },
                  onDenied: () {
                    if (mounted) {
                      SnackBarHelper.showErrorSnackBar(
                        context,
                        'Storage permission is required to delete files',
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
              );
              return;
            }
          }
        }
      } catch (e) {}
    }

    await _proceedWithBulkDelete(files);
  }

  Future<void> _proceedWithBulkDelete(List<HealthFile> files) async {
    final confirmed = await EcliniqBottomSheet.show<bool>(
      context: context,
      child: const DeleteFileBottomSheet(),
    );

    if (confirmed != true || !mounted) return;

    BuildContext? dialogContext;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const Center(child: EcliniqLoader());
          },
        );

        await Future.delayed(const Duration(milliseconds: 100));
      }

      final provider = context.read<HealthFilesProvider>();
      int successCount = 0;
      int notFoundCount = 0;
      int failedCount = 0;

      final filesToDelete = files
          .where((f) => _selectedFileIds.contains(f.id))
          .toList();

      for (final file in filesToDelete) {
        try {
          final fileToDelete = File(file.filePath);
          if (!await fileToDelete.exists()) {
            notFoundCount++;

            await provider.deleteFile(file);
            continue;
          }

          final success = await provider.deleteFile(file);
          if (success) {
            successCount++;
          } else {
            failedCount++;
          }
        } catch (e) {
          failedCount++;
        }
      }

      if (mounted && (successCount > 0 || notFoundCount > 0)) {
        await provider.refresh();
      }

      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (e) {}
        dialogContext = null;
      }

      if (!mounted) return;

      if (successCount > 0) {
        String message = '$successCount file(s) deleted successfully';
        if (notFoundCount > 0) {
          message += ' ($notFoundCount already removed)';
        }

        CustomSuccessSnackBar.show(
          context: context,
          title: 'Success',
          subtitle: message,
          duration: const Duration(seconds: 3),
        );
      } else if (notFoundCount > 0) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Selected files were already removed',
          duration: const Duration(seconds: 2),
        );
      } else {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Failed to delete files${failedCount > 0 ? " ($failedCount failed)" : ""}',
          duration: const Duration(seconds: 2),
        );
      }

      _clearSelection();
    } catch (e) {
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {}
        dialogContext = null;
      }

      if (!mounted) return;

      SnackBarHelper.showErrorSnackBar(
        context,
        'Error deleting files: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {}
        dialogContext = null;
      }
    }
  }

  Future<void> _handleBulkDownload(List<HealthFile> files) async {
    if (_selectedFileIds.isEmpty) return;

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
          if (mounted) {
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

    await _proceedWithBulkDownload(files);
  }

  void _showUploadBottomSheet(BuildContext context) {
    EcliniqBottomSheet.show(
      context: context,
      child: UploadBottomSheet(
        onFileUploaded: () async {
          if (mounted) {
            final provider = context.read<HealthFilesProvider>();

            await provider.refresh();

            if (mounted) {
              provider.notifyListeners();
            }
          }
        },
      ),
    );
  }

  Future<void> _proceedWithBulkDownload(List<HealthFile> files) async {
    try {
      int successCount = 0;

      final filesToDownload = files
          .where((f) => _selectedFileIds.contains(f.id))
          .toList();

      for (final file in filesToDownload) {
        try {
          await _handleFileDownload(file, showSnackbar: false);
          successCount++;
        } catch (e) {}
      }

      if (!mounted) return;

      if (successCount > 0) {
        CustomSuccessSnackBar.show(
          context: context,
          title: 'Download successful',
          subtitle: '$successCount file(s) downloaded successfully',
          duration: const Duration(seconds: 3),
        );
      } else {
        SnackBarHelper.showErrorSnackBar(
          context,
          'No files were downloaded',
          duration: const Duration(seconds: 2),
        );
      }

      _clearSelection();
    } catch (e) {
      if (!mounted) return;

      SnackBarHelper.showErrorSnackBar(
        context,
        'Error downloading files: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _handleFileDelete(HealthFile file) async {
    if (Platform.isAndroid) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final externalDir = await getExternalStorageDirectory();

        final isInAppDir =
            file.filePath.startsWith(appDir.path) ||
            (externalDir != null && file.filePath.startsWith(externalDir.path));

        if (!isInAppDir) {
          final status = await Permission.storage.status;

          if (!status.isGranted) {
            if (!mounted) return;

            final result = await Permission.storage.request();

            if (!result.isGranted) {
              if (!mounted) return;

              await showDialog(
                context: context,
                builder: (context) => PermissionRequestDialog(
                  permission: Permission.storage,
                  title: 'Storage Permission Required',
                  message:
                      'We need storage permission to delete files from your device.',
                  onGranted: () async {
                    await _proceedWithDelete(file);
                  },
                  onDenied: () {
                    if (mounted) {
                      SnackBarHelper.showErrorSnackBar(
                        context,
                        'Storage permission is required to delete files',
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
              );
              return;
            }
          }
        }
      } catch (e) {}
    }

    await _proceedWithDelete(file);
  }

  Future<void> _proceedWithDelete(HealthFile file) async {
    final confirmed = await EcliniqBottomSheet.show<bool>(
      context: context,
      child: const DeleteFileBottomSheet(),
    );

    if (confirmed != true || !mounted) return;

    BuildContext? dialogContext;

    try {
      if (mounted) {
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

      final success = await provider.deleteFile(file);

      if (success && mounted) {
        await provider.refresh();
      }

      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (e) {}
        dialogContext = null;
      }

      if (!mounted) return;

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
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {}
        dialogContext = null;
      }

      if (!mounted) return;

      SnackBarHelper.showErrorSnackBar(
        context,
        'Error deleting file: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {}
      }
    }
  }

  Future<void> _handleFileDownload(
    HealthFile file, {
    bool showSnackbar = true,
  }) async {
    if (!mounted) return;

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
          if (mounted) {
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
            } else if (showSnackbar) {
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

    await _proceedWithDownload(file, showSnackbar: showSnackbar);
  }

  Future<void> _proceedWithDownload(
    HealthFile file, {
    bool showSnackbar = true,
  }) async {
    if (!mounted) return;

    if (showSnackbar) {
      SnackBarHelper.showSnackBar(
        context,
        Platform.isIOS
            ? 'Preparing file for download...'
            : 'Download started. We\'ll notify you when it\'s complete.',
        backgroundColor: const Color(0xFF2372EC),
        duration: const Duration(seconds: 2),
      );
    }

    try {
      final sourceFile = File(file.filePath);

      if (!await sourceFile.exists()) {
        if (!mounted) return;

        if (showSnackbar) {
          SnackBarHelper.showErrorSnackBar(
            context,
            'File not found in storage',
            duration: const Duration(seconds: 2),
          );
        }
        return;
      }

      if (Platform.isAndroid) {
        try {
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

          if (!mounted) return;

          if (showSnackbar) {
            CustomSuccessSnackBar.show(
              context: context,
              title: 'Download successful',
              subtitle: 'File saved: $fileName',
              duration: const Duration(seconds: 3),
            );
          }

          await LocalNotifications.showDownloadSuccess(fileName: fileName);
          return;
        } catch (e) {
          if (!mounted) return;

          if (showSnackbar) {
            SnackBarHelper.showErrorSnackBar(
              context,
              'Download failed: ${e.toString()}',
              duration: const Duration(seconds: 3),
            );
          }
          return;
        }
      }

      if (Platform.isIOS) {
        try {
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

          if (!mounted) return;

          if (showSnackbar) {
            CustomSuccessSnackBar.show(
              context: context,
              title: 'Download successful',
              subtitle: 'File saved to app Downloads folder: $fileName',
              duration: const Duration(seconds: 3),
            );
          }

          await LocalNotifications.showDownloadSuccess(fileName: fileName);

          return;
        } catch (e) {
          if (!mounted) return;

          if (showSnackbar) {
            SnackBarHelper.showErrorSnackBar(
              context,
              'Download failed: ${e.toString()}',
              duration: const Duration(seconds: 3),
            );
          }
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;

      if (showSnackbar) {
        SnackBarHelper.showErrorSnackBar(
          context,
          'Failed to download file: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }


  void _showFilterBottomSheet() {
    EcliniqBottomSheet.show<Map<String, dynamic>>(
      context: context,
      child: HealthFilesFilter(
        initialSelectedNames: _selectedNames,
        onApply: (result) {},
      ),
    ).then((result) {
      if (mounted) {
        setState(() {
          if (result != null) {
            final selectedNames = result['selectedNames'] as List<dynamic>?;
            final sortBy = result['sortBy'];

            if (selectedNames == null ||
                (selectedNames.isEmpty && sortBy == null)) {
              _selectedNames.clear();
              _selectedRecordFor = null;
            } else if (selectedNames.isNotEmpty) {
              _selectedNames.clear();
              _selectedNames.addAll(
                selectedNames.map((name) => name.toString()),
              );

              _selectedRecordFor = null;
            } else {
              _selectedNames.clear();
              _selectedRecordFor = null;
            }
          } else {}
        });
      }
    });
  }

  void _showFileActions(HealthFile file) {

    EcliniqBottomSheet.show(
      context: context,
      child: ActionBottomSheet(
        healthFile: file,
        onEditDocument: () {
          Navigator.pop(context);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              EcliniqRouter.push(EditDocumentDetailsPage(healthFile: file));
            }
          });
        },
        onDownloadDocument: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            await _handleFileDownload(file);
          }
        },
        onDeleteDocument: () async {
          Navigator.of(context, rootNavigator: false).pop();

          await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted) return;

          await _handleFileDelete(file);
        },
      ),
    );
  }

  Widget _buildFileTypeTabs() {
    final allTabs = <HealthFileType?>[null, ...HealthFileType.values];

    return Column(
      children: [
        SizedBox(
          height: EcliniqTextStyles.getResponsiveHeight(context, 50),
          child: SingleChildScrollView(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
              context,
              horizontal: 16.0,
              vertical: 0,
            ),
            child: Row(
              children: allTabs.asMap().entries.map((entry) {
                final index = entry.key;
                final fileType = entry.value;
                final isSelected = fileType == _selectedFileType;
                final displayName = fileType == null
                    ? 'All'
                    : fileType.displayName;

                return GestureDetector(
                  onTap: () => _onFileTypeSelected(fileType),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < allTabs.length - 1 ? 6.0 : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding:
                              EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                context,
                                horizontal: 8,
                                vertical: 8,
                              ),
                          child: Text(
                            displayName,
                            style:
                                EcliniqTextStyles.responsiveHeadlineBMedium(
                                  context,
                                ).copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF2372EC)
                                      : const Color(0xFF626060),
                                ),
                          ),
                        ),
                        Container(
                          height: EcliniqTextStyles.getResponsiveHeight(
                            context,
                            3,
                          ),
                          width: displayName.length * 10.0 + 12,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2372EC)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              EcliniqTextStyles.getResponsiveBorderRadius(
                                context,
                                2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFB8B8B8)),
      ],
    );
  }

  Widget _buildSelectionBottomBar(List<HealthFile> files) {
    final hasSelection = _selectedFileIds.isNotEmpty;
    final selectedCount = _selectedFileIds.length;

    return Container(
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
        context,
        horizontal: 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: EcliniqTextStyles.getResponsiveWidth(context, 24),
                    height: EcliniqTextStyles.getResponsiveHeight(context, 24),
                    decoration: BoxDecoration(
                      color: hasSelection
                          ? const Color(0xFF96BFFF)
                          : const Color(0xFFffffff),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(context, 6),
                      ),
                      border: Border.all(
                        color: hasSelection
                            ? const Color(0xFF96BFFF)
                            : const Color(0xFF8E8E8E),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                        context,
                        4.0,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          EcliniqIcons.minus.assetPath,
                          width: EcliniqTextStyles.getResponsiveWidth(
                            context,
                            8,
                          ),
                          height: EcliniqTextStyles.getResponsiveHeight(
                            context,
                            8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 6),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$selectedCount ${selectedCount == 1 ? 'File' : 'Files'} Selected',
                        style:
                            EcliniqTextStyles.responsiveHeadlineBMedium(
                              context,
                            ).copyWith(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF424242),
                            ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: hasSelection ? () => _handleBulkDownload(files) : null,
              icon: SvgPicture.asset(
                hasSelection
                    ? EcliniqIcons.downloadfiles.assetPath
                    : EcliniqIcons.downloadDisabled.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
            Container(
              width: 0.5,
              height: EcliniqTextStyles.getResponsiveHeight(context, 20),
              color: const Color(0xFFB8B8B8),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8)),

            IconButton(
              onPressed: hasSelection ? () => _handleBulkDelete(files) : null,
              icon: SvgPicture.asset(
                hasSelection
                    ? EcliniqIcons.delete.assetPath
                    : EcliniqIcons.trashBin.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8)),
            Container(width: 0.5, height: 20, color: const Color(0xFFB8B8B8)),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8)),

            IconButton(
              onPressed: _clearSelection,
              icon: SvgPicture.asset(
                EcliniqIcons.closeCircle.assetPath,
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
          leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
          titleSpacing: 0,
          toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'My Files',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: const Color(0xff424242)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
          child: Container(
            color: Color(0xFFB8B8B8),
            height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
        ),

        actions: [
          if (!_isSearchMode)
            IconButton(
              icon: SvgPicture.asset(
                EcliniqIcons.magnifierMyDoctor.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 30),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 30),
              ),
              onPressed: () {
                setState(() {
                  _isSearchMode = true;
                });
              },
            )
          else
            IconButton(
              icon: Icon(
                Icons.close,
                color: const Color(0xFF424242),
                size: EcliniqTextStyles.getResponsiveIconSize(context, 30),
              ),
              onPressed: () {
                _clearSearch();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isSearchMode) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SearchBarWidget(
                    controller: _searchController,
                    onSearch: (String value) {
                      _onSearchChanged();
                    },
                    hintText: 'Search File',
                    onVoiceSearch: _toggleVoiceSearch,
                    onClear: _clearSearch,
                  ),
                ),
              ],
              Expanded(
                child: Consumer<HealthFilesProvider>(
                  builder: (context, provider, child) {
                    final files = _isSearchMode
                        ? provider.searchResults
                        : provider.getFilesByType(
                            _selectedFileType,
                            recordFor: _selectedRecordFor,
                            selectedNames: _selectedNames.isNotEmpty
                                ? _selectedNames.toList()
                                : null,
                          );

                    return Column(
                      children: [
                        if (!_isSearchMode) _buildFileTypeTabs(),

                        if (files.isNotEmpty && !_isSearchMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: _showFilterBottomSheet,
                                  child: Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          SvgPicture.asset(
                                            EcliniqIcons.filter.assetPath,
                                            width: 24,
                                            height: 24,
                                          ),
                                          if (_hasActiveFilters())
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Filters',
                                        style:
                                            EcliniqTextStyles.responsiveHeadlineBMedium(
                                              context,
                                            ).copyWith(
                                              color: Color(0xFF424242),
                                              fontWeight: FontWeight.w400,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      SvgPicture.asset(
                                        EcliniqIcons.arrowDown.assetPath,
                                        width:
                                            EcliniqTextStyles.getResponsiveIconSize(
                                              context,
                                              24,
                                            ),
                                        height:
                                            EcliniqTextStyles.getResponsiveIconSize(
                                              context,
                                              24,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 0.5,
                                  height: 20,
                                  color: const Color(0xFFD6D6D6),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _toggleSelectionMode,
                                  child: SvgPicture.asset(
                                    _isSelectionMode
                                        ? EcliniqIcons.deselect.assetPath
                                        : EcliniqIcons.select.assetPath,
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${files.length} ${files.length == 1 ? 'File' : 'Files'}',
                                  style:
                                      EcliniqTextStyles.responsiveTitleXLarge(
                                        context,
                                      ).copyWith(
                                        color: Color(0xFF424242),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        if (files.isEmpty) ...[
                         
                          _buildEmptyState(),
                        ] else
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    itemCount: files.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final file = files[index];
                                      final isSelected = _selectedFileIds
                                          .contains(file.id);

                                      return PrescriptionCardList(
                                        file: file,
                                        isOlder: false,
                                        isSelectionMode:
                                            _isSelectionMode && !_isSearchMode,
                                        isSelected: isSelected,
                                        onTap: () {
                                          if (_isSelectionMode &&
                                              !_isSearchMode) {
                                            _toggleFileSelection(file);
                                          } else {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    _FileViewerScreen(
                                                      file: file,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                        onMenuTap:
                                            (_isSelectionMode && !_isSearchMode)
                                            ? null
                                            : () => _showFileActions(file),
                                        onSelectionToggle: () =>
                                            _toggleFileSelection(file),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_isSelectionMode && !_isSearchMode)
                          _buildSelectionBottomBar(files),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          if (!_isSelectionMode)
            Positioned(
              right: 16,
              bottom: 20,
              child: GestureDetector(
                onTap: () => _showUploadBottomSheet(context),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: EcliniqScaffold.darkBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.upload.assetPath,
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Upload',
                        style:
                            EcliniqTextStyles.responsiveHeadlineBMedium(
                              context,
                            ).copyWith(
                              color: Colors.white,

                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedNames.isNotEmpty || _selectedRecordFor != null;
  }

  Widget _buildEmptyState() {
    final hasFilter = _selectedNames.isNotEmpty || _selectedRecordFor != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
      const SizedBox(height: 40),
       const SizedBox(height: 40),
        const SizedBox(height: 40),
         const SizedBox(height: 40),
          const SizedBox(height: 40),
          SvgPicture.asset(EcliniqIcons.nofiles.assetPath),
          const SizedBox(height: 12),
          Text(
            hasFilter ? 'No Files Found' : 'No Documents Uploaded Yet',
            style: EcliniqTextStyles.responsiveButtonXLarge(
              context,
            ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff424242)),
          ),
          const SizedBox(height: 2),
          Text(
            hasFilter
                ? 'Try adjusting your filters to see more files'
                : 'Click upload button to maintain your health files',
            style: EcliniqTextStyles.responsiveButtonXLargeProminent(
              context,
            ).copyWith(color: Color(0xff8E8E8E), fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

class _FileViewerScreen extends StatelessWidget {
  final HealthFile file;

  const _FileViewerScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          file.fileName,
          style: EcliniqTextStyles.responsiveHeadlineBMedium(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              EcliniqIcons.downloadfiles.assetPath,
              width: 32,
              height: 32,
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            onPressed: () async {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: file.isImage && File(file.filePath).existsSync()
          ? Center(
              child: InteractiveViewer(child: Image.file(File(file.filePath))),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description,
                    size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'File: ${file.fileName}',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(
                      context,
                    ).copyWith(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Size: ${_formatFileSize(file.fileSize)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final List<String> options;
  final String selectedOption;

  const _FilterBottomSheet({
    required this.options,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Person',
            style: EcliniqTextStyles.responsiveHeadlineLarge(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: Color(0xFF424242)),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selectedOption;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, option),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE3F2FD)
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2B7FFF)
                              : const Color(0xFFE0E0E0),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style:
                                  EcliniqTextStyles.responsiveTitleXLarge(
                                    context,
                                  ).copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: const Color(0xFF424242),
                                  ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2B7FFF),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
