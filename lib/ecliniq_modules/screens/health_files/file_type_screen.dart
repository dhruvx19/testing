import 'dart:async';
import 'dart:io';

import 'package:ecliniq/ecliniq_core/notifications/local_notifications.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_api/health_file_model.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../ecliniq_icons/assets/home/widgets/top_bar_widgets/search_bar.dart';

class FileTypeScreen extends StatefulWidget {
  final HealthFileType? fileType;

  const FileTypeScreen({super.key, this.fileType});

  @override
  State<FileTypeScreen> createState() => _FileTypeScreenState();
}

class _FileTypeScreenState extends State<FileTypeScreen> {
  String? _selectedRecordFor; // For backward compatibility
  final Set<String> _selectedNames = {}; // For multiple name filtering
  final List<String> _recordForOptions = ['All'];
  HealthFileType? _selectedFileType;

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedFileIds = {};

  // ScrollController for syncing tab indicator
  final ScrollController _tabScrollController = ScrollController();

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
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
    _speechToText.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
          final errorMsg = error.errorMsg.toLowerCase();
          if (!errorMsg.contains('no_match') &&
              !errorMsg.contains('listen_failed')) {
            debugPrint(
              'Speech recognition initialization error: ${error.errorMsg}',
            );
          }
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (mounted) {
            if (status == 'notListening' ||
                status == 'done' ||
                status == 'doneNoResult') {
              setState(() => _isListening = false);
            } else if (status == 'listening') {
              setState(() => _isListening = true);
            }
          }
        },
      );
      if (mounted) {
        setState(() {});
      }
      debugPrint('Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      _speechEnabled = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startListening() async {
    if (_isListening) {
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
      if (!_speechEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Speech recognition is not available. Please check your permissions.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    final isAvailable = await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech recognition error: ${error.errorMsg}');
        final errorMsg = error.errorMsg.toLowerCase();
        if (errorMsg.contains('no_match') ||
            errorMsg.contains('listen_failed') ||
            errorMsg.contains('error_network_error')) {
          debugPrint('Expected speech recognition error: ${error.errorMsg}');
          if (mounted) {
            setState(() => _isListening = false);
          }
          return;
        }

        if (mounted) {
          setState(() => _isListening = false);
          if (errorMsg.contains('error_permission') ||
              errorMsg.contains('permission')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Microphone permission is required for voice search.',
                ),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speech recognition error: ${error.errorMsg}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onStatus: (status) {
        debugPrint('Speech recognition status: $status');
        if (mounted) {
          if (status == 'notListening' ||
              status == 'done' ||
              status == 'doneNoResult') {
            setState(() => _isListening = false);
          } else if (status == 'listening') {
            setState(() => _isListening = true);
          }
        }
      },
    );

    if (!isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available. Please check your permissions.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      if (mounted) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting voice search: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      debugPrint('Speech recognition stopped');
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    debugPrint(
      'Speech result: ${result.recognizedWords}, final: ${result.finalResult}',
    );

    // Update the search controller with recognized words
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

    // Check storage permissions for Android before bulk delete
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

            // Try to request permission
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
      } catch (e) {
        debugPrint('Error checking permissions: $e');
        // Continue anyway
      }
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
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return const Center(child: EcliniqLoader());
          },
        );
        // Give the dialog a moment to be fully shown
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final provider = context.read<HealthFilesProvider>();
      int successCount = 0;
      int notFoundCount = 0;
      int failedCount = 0;

      final filesToDelete = files
          .where((f) => _selectedFileIds.contains(f.id))
          .toList();

      // Delete files one by one
      for (final file in filesToDelete) {
        try {
          // Check if file exists
          final fileToDelete = File(file.filePath);
          if (!await fileToDelete.exists()) {
            notFoundCount++;
            // Still try to remove from database
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
          debugPrint('Error deleting file ${file.fileName}: $e');
          failedCount++;
        }
      }

      // Refresh the file list to ensure UI updates
      if (mounted && (successCount > 0 || notFoundCount > 0)) {
        await provider.refresh();
      }

      // Close loading indicator
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (e) {
          debugPrint('Error closing loading dialog: $e');
        }
        dialogContext = null;
      }

      if (!mounted) return;

      // Show appropriate message
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
      // Close loading indicator if still open
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {
          debugPrint('Error closing loading dialog in catch:');
        }
        dialogContext = null;
      }

      if (!mounted) return;

      SnackBarHelper.showErrorSnackBar(
        context,
        'Error deleting files: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Ensure dialog is closed even if something unexpected happens
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {
          // Dialog might already be closed, ignore error
        }
        dialogContext = null;
      }
    }
  }

  Future<void> _handleBulkDownload(List<HealthFile> files) async {
    if (_selectedFileIds.isEmpty) return;

    // Check storage permissions for Android before bulk download - use default Android dialog
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
          if (mounted) {
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

    await _proceedWithBulkDownload(files);
  }

  void _showUploadBottomSheet(BuildContext context) {
    EcliniqBottomSheet.show(
      context: context,
      child: UploadBottomSheet(
        onFileUploaded: () async {
          // Refresh files after upload - ensure UI updates immediately
          if (mounted) {
            final provider = context.read<HealthFilesProvider>();
            // Force refresh to reload files from storage
            await provider.refresh();
            // Ensure listeners are notified
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
        } catch (e) {
          // Continue with next file if one fails
          debugPrint('Error downloading file ${file.fileName}: $e');
        }
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
    // Check storage permissions for Android before delete
    if (Platform.isAndroid) {
      try {
        // Check if file is in app-specific directory (no permission needed)
        final appDir = await getApplicationDocumentsDirectory();
        final externalDir = await getExternalStorageDirectory();

        final isInAppDir =
            file.filePath.startsWith(appDir.path) ||
            (externalDir != null && file.filePath.startsWith(externalDir.path));

        if (!isInAppDir) {
          // File is in public storage (like Downloads), need permission
          final status = await Permission.storage.status;

          if (!status.isGranted) {
            if (!mounted) return;

            // Request permission
            final result = await Permission.storage.request();

            if (!result.isGranted) {
              if (!mounted) return;

              // Show dialog to explain and direct to settings if needed
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
      } catch (e) {
        debugPrint('Error checking permissions: $e');
        // Continue anyway - let the delete operation fail if needed
      }
    }

    // Proceed with delete confirmation
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
      // Show loading indicator
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

      // Delete the file (provider handles both physical file and metadata)
      final success = await provider.deleteFile(file);

      // Refresh the file list to ensure UI updates
      if (success && mounted) {
        await provider.refresh();
      }

      // Close loading indicator - ensure it closes even if refresh fails
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (e) {
          debugPrint('Error closing loading dialog: $e');
        }
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
      // Close loading indicator if still open
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {
          debugPrint('Error closing loading dialog in catch:');
        }
        dialogContext = null;
      }

      if (!mounted) return;

      SnackBarHelper.showErrorSnackBar(
        context,
        'Error deleting file: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Ensure dialog is closed even if something unexpected happens
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } catch (_) {
          // Dialog might already be closed, ignore error
        }
      }
    }
  }

  Future<void> _handleFileDownload(
    HealthFile file, {
    bool showSnackbar = true,
  }) async {
    if (!mounted) return;

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
          if (mounted) {
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

    // Proceed with download
    await _proceedWithDownload(file, showSnackbar: showSnackbar);
  }

  Future<void> _proceedWithDownload(
    HealthFile file, {
    bool showSnackbar = true,
  }) async {
    if (!mounted) return;

    // Show "Download started" message immediately
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

          // Try primary download directory first
          final primaryDir = Directory('/storage/emulated/0/Download');
          if (await primaryDir.exists()) {
            targetDir = primaryDir;
          } else {
            // Fallback to app's external storage directory
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

          // Download file in background
          await sourceFile.copy(destFile.path);

          // Verify file was copied successfully
          if (!await destFile.exists()) {
            throw Exception(
              'File copy failed - destination file does not exist.',
            );
          }

          if (!mounted) return;

          // Show success snackbar
          if (showSnackbar) {
            CustomSuccessSnackBar.show(
              context: context,
              title: 'Download successful',
              subtitle: 'File saved: $fileName',
              duration: const Duration(seconds: 3),
            );
          }

          // Show local notification
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

      // For iOS - save to app's Documents directory in a Downloads subfolder
      if (Platform.isIOS) {
        try {
          final documentsDir = await getApplicationDocumentsDirectory();
          final downloadsDir = Directory(
            path.join(documentsDir.path, 'Downloads'),
          );

          // Create Downloads directory if it doesn't exist
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
            debugPrint('📁 Created Downloads directory: ${downloadsDir.path}');
          }

          String fileName = file.fileName;
          File destFile = File(path.join(downloadsDir.path, fileName));

          // Handle duplicate file names
          int counter = 1;
          while (await destFile.exists()) {
            final nameWithoutExt = path.basenameWithoutExtension(fileName);
            final ext = path.extension(fileName);
            fileName = '${nameWithoutExt}_$counter$ext';
            destFile = File(path.join(downloadsDir.path, fileName));
            counter++;
          }

          // Copy file to Downloads directory
          await sourceFile.copy(destFile.path);
          debugPrint('✅ File copied to: ${destFile.path}');

          // Verify file was copied successfully
          if (!await destFile.exists()) {
            throw Exception(
              'File copy failed - destination file does not exist.',
            );
          }

          if (!mounted) return;

          // Show success message
          if (showSnackbar) {
            CustomSuccessSnackBar.show(
              context: context,
              title: 'Download successful',
              subtitle: 'File saved to app Downloads folder: $fileName',
              duration: const Duration(seconds: 3),
            );
          }

          // Show local notification
          await LocalNotifications.showDownloadSuccess(fileName: fileName);

          debugPrint('✅ iOS download completed: $fileName');
          return;
        } catch (e) {
          debugPrint('❌ iOS download error: $e');

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
      debugPrint('❌ Download error: $e');

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

  Future<void> _shareFile(HealthFile healthFile) async {
    try {
      final file = File(healthFile.filePath);
      if (!await file.exists()) {
        if (!mounted) return;
        SnackBarHelper.showErrorSnackBar(
          context,
          'File not found',
          duration: const Duration(seconds: 2),
        );
        return;
      }

      if (!mounted) return;

      // Note: To implement actual sharing, you need to add share_plus package
      // Add to pubspec.yaml: share_plus: ^7.2.1
      // Then uncomment this code:
      /*
      await Share.shareXFiles(
        [XFile(file.path)],
        text: healthFile.fileName,
      );
      */

      // For now, show a message
      SnackBarHelper.showSnackBar(
        context,
        'File saved to app Downloads folder. Share functionality coming soon.',
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showErrorSnackBar(
        context,
        'Failed to process file: ${e.toString()}',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _showFilterBottomSheet() {
    EcliniqBottomSheet.show<Map<String, dynamic>>(
      context: context,
      child: HealthFilesFilter(
        initialSelectedNames: _selectedNames,
        onApply: (result) {
          // This callback is called before the bottom sheet closes
          // We'll update state in .then() after the sheet closes
        },
      ),
    ).then((result) {
      // Update state after bottom sheet closes
      if (mounted) {
        setState(() {
          if (result != null) {
            final selectedNames = result['selectedNames'] as List<dynamic>?;
            final sortBy = result['sortBy'];
            // Check if reset was called (empty result)
            if (selectedNames == null ||
                (selectedNames.isEmpty && sortBy == null)) {
              // Reset filters - clear all selections
              _selectedNames.clear();
              _selectedRecordFor = null;
            } else if (selectedNames != null && selectedNames.isNotEmpty) {
              _selectedNames.clear();
              _selectedNames.addAll(
                selectedNames.map((name) => name.toString()),
              );
              // Clear single selection for backward compatibility
              _selectedRecordFor = null;
            } else {
              _selectedNames.clear();
              _selectedRecordFor = null;
            }
          } else {
            // If result is null, user dismissed without applying
            // Keep current selections
          }
        });
      }
    });
  }

  void _showFileActions(HealthFile file) {
    // Store context before showing bottom sheet
    final savedContext = context;

    EcliniqBottomSheet.show(
      context: context,
      child: ActionBottomSheet(
        healthFile: file,
        onEditDocument: () {
          Navigator.pop(context); // Close action bottom sheet first
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              EcliniqRouter.push(EditDocumentDetailsPage(healthFile: file));
            }
          });
        },
        onDownloadDocument: () async {
          Navigator.pop(context); // Close action bottom sheet first
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            await _handleFileDownload(file);
          }
        },
        onDeleteDocument: () async {
          // Close action bottom sheet first
          Navigator.of(context, rootNavigator: false).pop();

          // Wait for bottom sheet animation to complete
          await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted) return;

          // Call the delete method which will check permissions, show confirmation and handle deletion
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
                      right: index < allTabs.length - 1 ? 16.0 : 0,
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
                          width: displayName.length * 10.0 + 16,
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
        horizontal: 12,
        vertical: 12,
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
            // Selected count badge
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

            // Download button
            IconButton(
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 6),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: hasSelection ? () => _handleBulkDownload(files) : null,
              icon: SvgPicture.asset(
                hasSelection
                    ? EcliniqIcons.downloadfiles.assetPath
                    : EcliniqIcons.downloadDisabled.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 20),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 20),
              ),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 2)),
            Container(
              width: 0.5,
              height: EcliniqTextStyles.getResponsiveHeight(context, 20),
              color: const Color(0xFFB8B8B8),
            ),
            SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 2)),
            // Delete button
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: hasSelection ? () => _handleBulkDelete(files) : null,
              icon: SvgPicture.asset(
                hasSelection
                    ? EcliniqIcons.delete.assetPath
                    : EcliniqIcons.trashBin.assetPath,
                width: 20,
                height: 20,
              ),
            ),
            const SizedBox(width: 2),
            Container(width: 0.5, height: 20, color: const Color(0xFFB8B8B8)),
            const SizedBox(width: 2),
            // Close/Cancel button
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: _clearSelection,
              icon: SvgPicture.asset(
                EcliniqIcons.closeCircle.assetPath,
                width: 20,
                height: 20,
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
        leadingWidth: 58,
        titleSpacing: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.backArrow.assetPath,
            width: 32,
            height: 32,
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
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: const Color(0xFFB8B8B8), height: 1.0),
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
                        // Show filter header only if there are files present and not in search mode
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
          // Only show upload button when not in selection mode
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
    // Check if filter is applied
    final hasFilter = _selectedNames.isNotEmpty || _selectedRecordFor != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
