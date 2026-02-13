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
import 'package:ecliniq/ecliniq_utils/speech_helper.dart';

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
  final SpeechHelper _speechHelper = SpeechHelper();
  bool get _isListening => _speechHelper.isListening;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

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

    _onSearch(result.recognizedWords);

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

          await _proceedWithDelete(file);
        },
      ),
    );
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _speechHelper.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      return;
    }

    NavigationHelper.navigateToTab(context, index, _currentIndex);
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            EcliniqIcons.nofiles.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 100),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 100),
          ),
          SizedBox(height: EcliniqTextStyles.getResponsiveSpacing(context, 12)),
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
        if (provider.allFiles.isEmpty) {
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Column(
                  children: [
                    const MyFilesWidget(),
                    Expanded(
                      child: _buildEmptyState(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
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
                  height: EcliniqTextStyles.getResponsiveSpacing(context, 44),
                ),
                Padding(
                 padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 14.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        EcliniqIcons.nameLogo.assetPath,
                        height: EcliniqTextStyles.getResponsiveHeight(
                          context,
                          32,
                        ),
                        width: EcliniqTextStyles.getResponsiveWidth(
                          context,
                          138,
                        ),
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
                                  height:
                                      EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        32,
                                      ),
                                  width:
                                      EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        32,
                                      ),
                                ),
                                if (provider.unreadCount > 0)
                                  Positioned(
                                    top: EcliniqTextStyles.getResponsiveSize(
                                      context,
                                      -12,
                                    ),
                                    right: EcliniqTextStyles.getResponsiveSize(
                                      context,
                                      -8,
                                    ),
                                    child: Container(
                                      padding:
                                          EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                                            context,
                                            4,
                                          ),
                                      constraints: BoxConstraints(
                                        minWidth:
                                            EcliniqTextStyles.getResponsiveSize(
                                              context,
                                              20,
                                            ),
                                        minHeight:
                                            EcliniqTextStyles.getResponsiveSize(
                                              context,
                                              20,
                                            ),
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
                              SizedBox(
                                height: EcliniqTextStyles.getResponsiveSpacing(
                                  context,
                                  18,
                                ),
                              ),
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
          right: 16,
          bottom: 110,
          child: GestureDetector(
            onTap: () => _showUploadBottomSheet(context),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        toolbarHeight: EcliniqTextStyles.getResponsiveSize(context, 38),
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
                    style: EcliniqTextStyles.responsiveBodySmall(
                      context,
                    ).copyWith(color: Colors.grey),
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
