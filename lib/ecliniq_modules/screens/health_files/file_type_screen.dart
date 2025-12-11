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
  final HealthFileType? fileType; // null means "All"

  const FileTypeScreen({super.key, this.fileType});

  @override
  State<FileTypeScreen> createState() => _FileTypeScreenState();
}

class _FileTypeScreenState extends State<FileTypeScreen> {
  String? _selectedRecordFor; // null means "All"
  final List<String> _recordForOptions = ['All'];
  HealthFileType? _selectedFileType; // null means "All"

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
      _selectedRecordFor = null; // Reset filter when changing type
    });
    _updateRecordForOptions();
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
      final provider = context.read<HealthFilesProvider>();
      final success = await provider.deleteFile(file);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'File deleted' : 'Failed to delete file'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleFileDownload(HealthFile file) async {
    try {
      final sourceFile = File(file.filePath);
      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            final downloadDir = Directory(
              path.join(externalDir.path, 'Download'),
            );
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            final destFile = File(path.join(downloadDir.path, file.fileName));
            await sourceFile.copy(destFile.path);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File downloaded successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
            await LocalNotifications.showDownloadSuccess(fileName: file.fileName);
            return;
          }
        } else {
          final destFile = File(path.join(directory.path, file.fileName));
          await sourceFile.copy(destFile.path);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File downloaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          await LocalNotifications.showDownloadSuccess(fileName: file.fileName);
          return;
        }
      }

      // Use share functionality as fallback
      await _shareFile(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareFile(HealthFile healthFile) async {
    try {
      final file = File(healthFile.filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Share functionality coming soon'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          EcliniqRouter.push(EditDocumentDetailsPage(healthFile: file));
        },
        onDownloadDocument: () => _handleFileDownload(file),
        onDeleteDocument: () => EcliniqBottomSheet.show<bool>(
          context: context,
          child: DeleteFileBottomSheet(),
        ).then((confirmed) {
          if (confirmed == true && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                final provider = context.read<HealthFilesProvider>();
                final success = await provider.deleteFile(file);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'File deleted' : 'Failed to delete file'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete file: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            });
          }
        }),
      ),
    );
  }

  Widget _buildFileTypeTabs() {
    final allTabs = <HealthFileType?>[null, ...HealthFileType.values];
    final selectedIndex = allTabs.indexOf(_selectedFileType);

    return Column(
      children: [
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: SingleChildScrollView(
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
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index < allTabs.length - 1 ? 16.0 : 0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
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
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Stack to overlay blue container on divider
        Stack(
          children: [
            // Divider for the whole row
            const Divider(height: 1, thickness: 1, color: Color(0xFFB8B8B8)),
            // Blue container for selected tab, positioned to overlay divider
            if (selectedIndex != -1)
              Positioned(
                bottom: 0,
                left: _calculateSelectedTabLeftPosition(selectedIndex, allTabs),
                child: Container(
                  height: 3,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2372EC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  double _calculateSelectedTabLeftPosition(
    int selectedIndex,
    List<HealthFileType?> allTabs,
  ) {
    double position = 16.0;

    for (int i = 0; i < selectedIndex; i++) {
      final tab = allTabs[i];
      final displayName = tab == null ? 'All' : tab.displayName;
      final textWidth = displayName.length * 10.0;
      position += textWidth + 32.0 + 16.0;
    }

    final selectedTab = allTabs[selectedIndex];
    final selectedDisplayName = selectedTab == null
        ? 'All'
        : selectedTab.displayName;
    final selectedTextWidth = selectedDisplayName.length * 10.0;
    final selectedTabWidth = selectedTextWidth + 32.0;
    position += (selectedTabWidth - 120) / 2;

    return position;
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
      body: Column(
        children: [
          _buildFileTypeTabs(),

          Expanded(
            child: Consumer<HealthFilesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final files = provider.getFilesByType(
                  _selectedFileType,
                  recordFor: _selectedRecordFor,
                );

                if (files.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
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
                          return PrescriptionCardList(
                            file: files[index],
                            isOlder: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      _FileViewerScreen(file: files[index]),
                                ),
                              );
                            },
                            onMenuTap: () => _showFileActions(files[index]),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
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
