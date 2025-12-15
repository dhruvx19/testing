import 'dart:io';

import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/models/health_file_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/action_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/widgets/prescription_card_list.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/scaffold/scaffold.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/scripts/ecliniq_ui.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/health_files/delete_file_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/health_files/health_files_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ecliniq/ecliniq_core/notifications/local_notifications.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class FileTypeScreen extends StatefulWidget {
  final HealthFileType? fileType;

  const FileTypeScreen({super.key, this.fileType});

  @override
  State<FileTypeScreen> createState() => _FileTypeScreenState();
}

class _FileTypeScreenState extends State<FileTypeScreen> {
  String? _selectedRecordFor;
  final List<String> _recordForOptions = ['All'];
  HealthFileType? _selectedFileType;

  // Selection mode state
  bool _isSelectionMode = false;
  final Set<String> _selectedFileIds = {};

  // ScrollController for syncing tab indicator
  final ScrollController _tabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedFileType = widget.fileType;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HealthFilesProvider>();
      provider.loadFiles().then((_) {
        _updateRecordForOptions();
      });
    });
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
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

    final confirmed = await EcliniqBottomSheet.show<bool>(
      context: context,
      child: const DeleteFileBottomSheet(),
    );

    if (confirmed == true && mounted) {
      try {
        final provider = context.read<HealthFilesProvider>();
        int successCount = 0;

        final filesToDelete = files
            .where((f) => _selectedFileIds.contains(f.id))
            .toList();

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        for (final file in filesToDelete) {
          final success = await provider.deleteFile(file);
          if (success) successCount++;
        }

        if (!mounted) return;

        // Close loading indicator
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Refresh the file list to ensure UI updates
        if (successCount > 0) {
          await provider.refresh();
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount file(s) deleted successfully'),
            backgroundColor: Colors.green,
            dismissDirection: DismissDirection.horizontal,
            duration: const Duration(seconds: 2),
          ),
        );

        _clearSelection();
      } catch (e) {
        if (!mounted) return;
        
        // Close loading indicator if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting files: ${e.toString()}'),
            backgroundColor: Colors.red,
            dismissDirection: DismissDirection.horizontal,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleBulkDownload(List<HealthFile> files) async {
    if (_selectedFileIds.isEmpty) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

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
          print('Error downloading file ${file.fileName}: $e');
        }
      }

      if (!mounted) return;

      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        CustomSuccessSnackBar(
          context: context,
          title: 'Download successful',
          subtitle: '$successCount file(s) downloaded successfully',
          duration: const Duration(seconds: 3),
        ),
      );

      _clearSelection();
    } catch (e) {
      if (!mounted) return;
      
      // Close loading indicator if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading files: ${e.toString()}'),
          backgroundColor: Colors.red,
          dismissDirection: DismissDirection.horizontal,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleFileDelete(HealthFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final provider = context.read<HealthFilesProvider>();
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        final success = await provider.deleteFile(file);
        
        if (!mounted) return;
        
        // Close loading indicator
        Navigator.pop(context);

        if (success) {
          // Refresh the file list to ensure UI updates
          await provider.refresh();
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'File deleted successfully' : 'Failed to delete file',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            dismissDirection: DismissDirection.horizontal,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        // Close loading indicator if still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting file: ${e.toString()}'),
            backgroundColor: Colors.red,
            dismissDirection: DismissDirection.horizontal,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleFileDownload(
    HealthFile file, {
    bool showSnackbar = true,
  }) async {
    if (!mounted) return;

    // Show "Download started" message immediately
    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download started. We\'ll notify you when it\'s complete.'),
          backgroundColor: Color(0xFF2372EC),
          dismissDirection: DismissDirection.horizontal,
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      final sourceFile = File(file.filePath);

      if (!await sourceFile.exists()) {
        if (!mounted) return;
        
        if (showSnackbar) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found in storage'),
              backgroundColor: Colors.red,
              dismissDirection: DismissDirection.horizontal,
              duration: Duration(seconds: 2),
            ),
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

          // Download file in background
          // Note: Download works on real devices. On emulators, storage access
          // might be limited and downloads may fail due to permission restrictions.
          await sourceFile.copy(destFile.path);

          // Verify file was copied successfully
          if (!await destFile.exists()) {
            throw Exception('File copy failed - destination file does not exist. This may happen on emulators due to storage restrictions. Try on a real device.');
          }

          if (!mounted) return;

          // Show success snackbar
          if (showSnackbar) {
            ScaffoldMessenger.of(context).showSnackBar(
              CustomSuccessSnackBar(
                context: context,
                title: 'Download successful',
                subtitle: 'File saved: $fileName',
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Show local notification
          await LocalNotifications.showDownloadSuccess(fileName: fileName);
          return;
        } catch (e) {
          if (!mounted) return;
          
          if (showSnackbar) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download failed: ${e.toString()}'),
                backgroundColor: Colors.red,
                dismissDirection: DismissDirection.horizontal,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // For iOS, use share functionality
      await _shareFile(file);
    } catch (e) {
      if (!mounted) return;
      
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: ${e.toString()}'),
            backgroundColor: Colors.red,
            dismissDirection: DismissDirection.horizontal,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _shareFile(HealthFile healthFile) async {
    try {
      final file = File(healthFile.filePath);
      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found'),
            backgroundColor: Colors.red,
            dismissDirection: DismissDirection.horizontal,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share functionality coming soon'),
          backgroundColor: Colors.blue,
          dismissDirection: DismissDirection.horizontal,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share file: ${e.toString()}'),
          backgroundColor: Colors.red,
          dismissDirection: DismissDirection.horizontal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFilterBottomSheet() {
    EcliniqBottomSheet.show<String>(
      context: context,
      child: HealthFilesFilter(),
    ).then((selected) {
      if (selected != null) {
        setState(() {
          _selectedRecordFor = selected == 'All' ? null : selected;
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
          Navigator.pop(context); // Close action bottom sheet first
          await Future.delayed(const Duration(milliseconds: 200));
          
          if (!mounted) return;
          
          final confirmed = await EcliniqBottomSheet.show<bool>(
            context: context,
            child: const DeleteFileBottomSheet(),
          );

          if (confirmed == true && mounted) {
            try {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              final provider = context.read<HealthFilesProvider>();
              final success = await provider.deleteFile(file);

              if (!mounted) return;

              // Close loading indicator
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }

              if (success) {
                // Refresh the file list to ensure UI updates
                await provider.refresh();
              }

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'File deleted successfully'
                        : 'Failed to delete file',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                  dismissDirection: DismissDirection.horizontal,
                  duration: const Duration(seconds: 2),
                ),
              );
            } catch (e) {
              if (!mounted) return;
              
              // Close loading indicator if still open
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error deleting file: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  dismissDirection: DismissDirection.horizontal,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildFileTypeTabs() {
    final allTabs = <HealthFileType?>[null, ...HealthFileType.values];

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: SingleChildScrollView(
            controller: _tabScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF2372EC)
                                  : const Color(0xFF626060),
                            ),
                          ),
                        ),
                        Container(
                          height: 3,
                          width: displayName.length * 10.0 + 16,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2372EC)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasSelection
                    ? const Color(0xFF2372EC).withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasSelection
                      ? const Color(0xFF2372EC)
                      : const Color(0xFFB8B8B8),
                  width: 1.5,
                ),
              ),
              child: hasSelection
                  ? const Icon(Icons.remove, size: 16, color: Color(0xFF2372EC))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '${_selectedFileIds.length} Files Selected',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: hasSelection ? () => _handleBulkDownload(files) : null,
              icon: Icon(
                Icons.download_outlined,
                color: hasSelection
                    ? const Color(0xFF424242)
                    : const Color(0xFFB8B8B8),
                size: 24,
              ),
            ),
            IconButton(
              onPressed: hasSelection ? () => _handleBulkDelete(files) : null,
              icon: Icon(
                Icons.delete_outline,
                color: hasSelection ? Colors.red : const Color(0xFFB8B8B8),
                size: 24,
              ),
            ),
            IconButton(
              onPressed: _clearSelection,
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF424242),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF424242),
                  size: 16,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            style: EcliniqTextStyles.headlineMedium.copyWith(
              color: const Color(0xff424242),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: const Color(0xFFB8B8B8), height: 1.0),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              EcliniqIcons.magnifierMyDoctor.assetPath,
              width: 24,
              height: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<HealthFilesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Column(
              children: [
                _buildFileTypeTabs(),
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            );
          }

          final files = provider.getFilesByType(
            _selectedFileType,
            recordFor: _selectedRecordFor,
          );

          return Column(
            children: [
              _buildFileTypeTabs(),
              if (files.isEmpty)
                const Expanded(child: SizedBox.shrink())
              else
                Expanded(
                  child: Column(
                    children: [
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
                                  SvgPicture.asset(
                                    EcliniqIcons.filter.assetPath,
                                    width: 24,
                                    height: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF424242),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SvgPicture.asset(
                                    EcliniqIcons.arrowDown.assetPath,
                                    width: 24,
                                    height: 24,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _toggleSelectionMode,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _isSelectionMode
                                      ? const Color(0xFF2372EC).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _isSelectionMode
                                        ? const Color(0xFF2372EC)
                                        : const Color(0xFFB8B8B8),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  _isSelectionMode
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 20,
                                  color: _isSelectionMode
                                      ? const Color(0xFF2372EC)
                                      : const Color(0xFF424242),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${files.length} ${files.length == 1 ? 'File' : 'Files'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF424242),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: files.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final file = files[index];
                            final isSelected = _selectedFileIds.contains(
                              file.id,
                            );

                            return Row(
                              children: [
                                if (_isSelectionMode) ...[
                                  GestureDetector(
                                    onTap: () => _toggleFileSelection(file),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF2372EC)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2372EC)
                                              : const Color(0xFFB8B8B8),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: PrescriptionCardList(
                                    file: file,
                                    isOlder: false,
                                    onTap: () {
                                      if (_isSelectionMode) {
                                        _toggleFileSelection(file);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                _FileViewerScreen(file: file),
                                          ),
                                        );
                                      }
                                    },
                                    onMenuTap: _isSelectionMode
                                        ? null
                                        : () => _showFileActions(file),
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
              if (_isSelectionMode) _buildSelectionBottomBar(files),
            ],
          );
        },
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
                  const Icon(Icons.description, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'File: ${file.fileName}',
                    style: const TextStyle(fontSize: 18),
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
          const Text(
            'Filter by Person',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
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
                              style: TextStyle(
                                fontSize: 16,
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
