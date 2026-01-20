// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_core/notifications/local_notifications.dart';
import 'package:ecliniq/ecliniq_core/router/navigation_helper.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/action_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/custom_refresh_indicator.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/my_files.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/prescription_card_list.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/recently_uploaded.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/upload_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/upload_timeline.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/notification_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/notifications/provider/notification_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_navigation/bottom_navigation.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/text/text.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/health_files/delete_file_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/snackbar_helper.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../ecliniq_icons/assets/home/widgets/top_bar_widgets/search_bar.dart';

class HealthFiles extends StatefulWidget {
  const HealthFiles({super.key});

  @override
  State<HealthFiles> createState() => _HealthFilesState();
}

class _HealthFilesState extends State<HealthFiles> {
  static const int _currentIndex = 2;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load files when page loads
    // NOTE: We don't request permissions upfront on iOS to avoid them becoming permanently denied
    // Permissions will be requested when user actually tries to upload (handled in upload_bottom_sheet.dart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthFilesProvider>().loadFiles();
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchUnreadCount();
    });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
          }
          // Log but don't show expected errors during initialization
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
    // If already listening, don't start again
    if (_isListening) {
      return;
    }

    // Initialize if not already initialized
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

    // Ensure speech recognition is initialized with proper callbacks
    final isAvailable = await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech recognition error: ${error.errorMsg}');

        // Don't show error for expected errors like no_match
        final errorMsg = error.errorMsg.toLowerCase();
        if (errorMsg.contains('no_match') ||
            errorMsg.contains('listen_failed') ||
            errorMsg.contains('error_network_error')) {
          // These are expected errors, just log them
          debugPrint('Expected speech recognition error: ${error.errorMsg}');
          if (mounted) {
            setState(() => _isListening = false);
          }
          return;
        }

        // Show error for unexpected issues
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

    // Start listening - listen() returns void, not bool
    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true, // Get results as user speaks
        localeId: 'en_US', // You can make this configurable
        cancelOnError: false,
        listenMode: ListenMode.confirmation, // Better for search queries
      );

      // Set listening state - the status callback will also update this
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

    // Trigger search with the recognized words
    _onSearch(result.recognizedWords);

    // Stop listening when we get the final result
    if (result.finalResult) {
      _stopListening();
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
      _searchController.text = query;
    });
    context.read<HealthFilesProvider>().searchFiles(_searchQuery);
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    context.read<HealthFilesProvider>().searchFiles('');
    // Stop listening if active
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

  void _showFileActions(HealthFile file) {
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

          // Call the delete method which will show confirmation and handle deletion
          await _proceedWithDelete(file);
        },
      ),
    );
  }

  Future<void> _proceedWithDelete(HealthFile file) async {
    // Show confirmation bottom sheet first
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Don't navigate if already on the same tab
    if (index == _currentIndex) {
      return;
    }

    // Navigate using the navigation helper with smooth left-to-right transitions
    NavigationHelper.navigateToTab(context, index, _currentIndex);
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(EcliniqIcons.nofiles.assetPath),
          const SizedBox(height: 12),
          Text(
            'No Documents Uploaded Yet',
            style: EcliniqTextStyles.responsiveButtonXLargeProminent(
              context,
            ).copyWith(fontWeight: FontWeight.w400, color: Color(0xff424242)),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 2)),
          Text(
            'Click upload button to maintain your health files',
            style: EcliniqTextStyles.responsiveButtonXLargeProminent(
              context,
            ).copyWith(color: Color(0xff8E8E8E), fontWeight: FontWeight.w400),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 24)),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<HealthFilesProvider>(
      builder: (context, provider, child) {
        final files = provider.searchResults;

        if (files.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 16),
          itemCount: files.length,
          separatorBuilder: (context, index) => SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 12),
          ),
          itemBuilder: (context, index) {
            return PrescriptionCardList(
              file: files[index],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _FileViewerScreen(file: files[index]),
                  ),
                );
              },
              onMenuTap: () => _showFileActions(files[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Consumer<HealthFilesProvider>(
      builder: (context, provider, child) {
        // Show normal content with files directly
        return CustomRefreshIndicator(
          onRefresh: () async {
            await context.read<HealthFilesProvider>().refresh();
          },
          color: const Color(0xFF2372EC),
          backgroundColor: Colors.white,
          displacement: 40,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                const MyFilesWidget(),
                if (provider.allFiles.isEmpty) _buildEmptyState(),
                const RecentlyUploadedWidget(),
                const UploadTimeline(),
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        EcliniqScaffold(
          backgroundColor: EcliniqScaffold.primaryBlue,
          body: SizedBox.expand(
            child: Column(
              children: [
                SizedBox(
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 40),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.nameLogo.assetPath,
                        height: 28,
                        width: 140,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () async {
                          await EcliniqRouter.push(NotificationScreen());
                          if (mounted) {
                            Provider.of<NotificationProvider>(
                              context,
                              listen: false,
                            ).fetchUnreadCount();
                          }
                        },
                        child: Consumer<NotificationProvider>(
                          builder: (context, provider, child) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SvgPicture.asset(
                                  EcliniqIcons.notificationBell.assetPath,
                                  height: 32,
                                  width: 32,
                                ),
                                if (provider.unreadCount > 0)
                                  Positioned(
                                    top: -12,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF04248),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: EcliniqText(
                                          provider.unreadCount > 99
                                              ? '99+'
                                              : '${provider.unreadCount}',
                                          style: EcliniqTextStyles.headlineSmall
                                              .copyWith(
                                                color: Colors.white,
                                                height: 1,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 18),
                              SearchBarWidget(
                                controller: _searchController,
                                onSearch: _onSearch,
                                hintText: 'Search File',
                                isListening: _isListening,
                                onVoiceSearch: _toggleVoiceSearch,
                                onClear: _clearSearch,
                              ),
                              Expanded(
                                child: _searchQuery.isNotEmpty
                                    ? _buildSearchResults()
                                    : _buildMainContent(),
                              ),
                            ],
                          ),
                        ),
                        EcliniqBottomNavigationBar(
                          currentIndex: _currentIndex,
                          onTap: _onTabTapped,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          right: EcliniqTextStyles.getResponsiveWidth(context, 20),
          bottom: EcliniqTextStyles.getResponsiveHeight(context, 86),
          child: GestureDetector(
            onTap: () => _showUploadBottomSheet(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: EcliniqTextStyles.getResponsiveButtonHeight(
                context,
                baseHeight: 52.0,
              ),
              padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                context,
                horizontal: 12,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: EcliniqScaffold.darkBlue,
                borderRadius: BorderRadius.circular(
                  EcliniqTextStyles.getResponsiveBorderRadius(context, 4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    EcliniqIcons.upload.assetPath,
                    width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                    height: EcliniqTextStyles.getResponsiveIconSize(
                      context,
                      24,
                    ),
                  ),
                  SizedBox(
                    width: EcliniqTextStyles.getResponsiveSpacing(context, 4),
                  ),

                  Text(
                    'Upload',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(context)
                        .copyWith(
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
    );
  }
}

class _FileViewerScreen extends StatelessWidget {
  final HealthFile file;

  const _FileViewerScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(file.fileName),
        backgroundColor: EcliniqScaffold.primaryBlue,
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
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 16),
                  ),
                  Text(
                    'File: ${file.fileName}',
                    style: EcliniqTextStyles.responsiveHeadlineBMedium(
                      context,
                    ).copyWith(),
                  ),
                  SizedBox(
                    height: EcliniqTextStyles.getResponsiveSpacing(context, 8),
                  ),
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
