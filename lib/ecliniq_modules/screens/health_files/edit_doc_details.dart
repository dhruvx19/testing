import 'dart:io';

import 'package:ecliniq/ecliniq_modules/screens/details/widgets/date_picker_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/models/health_file_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditDocumentDetailsPage extends StatefulWidget {
  final HealthFile healthFile;

  const EditDocumentDetailsPage({super.key, required this.healthFile});

  @override
  State<EditDocumentDetailsPage> createState() =>
      _EditDocumentDetailsPageState();
}

class _EditDocumentDetailsPageState extends State<EditDocumentDetailsPage> {
  late TextEditingController _fileNameController;
  late HealthFileType _selectedFileType;
  String _selectedRecordFor = '';
  DateTime? _selectedDate;

  final List<String> _recordForOptions = [
    'Ketan Patni',
    'Jane Doe',
    'John Smith',
  ];

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(
      text: widget.healthFile.fileName,
    );
    _selectedFileType = widget.healthFile.fileType;
    _selectedRecordFor = widget.healthFile.recordFor ?? _recordForOptions[0];
    _selectedDate = widget.healthFile.fileDate;
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  String _getFileTypeString(HealthFileType type) {
    return type.displayName;
  }

  HealthFileType _getFileTypeFromString(String typeString) {
    return HealthFileType.values.firstWhere(
      (e) => e.displayName == typeString,
      orElse: () => HealthFileType.others,
    );
  }

  List<String> get _fileTypes {
    return HealthFileType.values.map((e) => e.displayName).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fileExists = File(widget.healthFile.filePath).existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: const Text(
            'Edit Document Details',
            style: TextStyle(
              color: Color(0xff424242),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.2),
          child: Container(color: const Color(0xFFB8B8B8), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Row(
                            children: [
                              const Text(
                                'File Name',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff626060),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Text(
                                ' •',
                                style: TextStyle(
                                  color: Color(0xffD92D20),
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _fileNameController,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: 'Enter file name',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xffD6D6D6),
                      thickness: 0.5,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: [
                                const Text(
                                  'File Type',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xff626060),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const Text(
                                  ' •',
                                  style: TextStyle(
                                    color: Color(0xffD92D20),
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showFileTypeBottomSheet(context),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getFileTypeString(_selectedFileType),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xffD6D6D6),
                      thickness: 0.5,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: [
                                const Text(
                                  'Record For',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xff626060),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const Text(
                                  ' •',
                                  style: TextStyle(
                                    color: Color(0xffD92D20),
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showRecordForBottomSheet(context),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedRecordFor,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Color(0xffD6D6D6),
                      thickness: 0.5,
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: [
                                const Text(
                                  'File Date',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xff626060),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showDateBottomSheet(context),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedDate != null
                                          ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                                          : 'Select Date',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _selectedDate != null
                                            ? Colors.black87
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // File Preview
              Container(
                width: double.infinity,
                height: 480,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      if (fileExists && widget.healthFile.isImage)
                        Image.file(
                          File(widget.healthFile.filePath),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderPreview();
                          },
                        )
                      else
                        _buildPlaceholderPreview(),
                      Positioned(
                        bottom: 12,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            // Show full screen preview
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _FullScreenPreview(
                                  filePath: widget.healthFile.filePath,
                                  isImage: widget.healthFile.isImage,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x99FFFFFF),
                              borderRadius: BorderRadius.circular(45),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 4),
                                  blurRadius: 10.4,
                                  spreadRadius: 0,
                                  color: const Color(0x1F000000),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Preview',
                                  style: TextStyle(
                                    color: Color(0xff424242),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2372EC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPreview() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              widget.healthFile.fileName,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateBottomSheet(BuildContext context) async {
    final DateTime? picked = await EcliniqBottomSheet.show<DateTime>(
      context: context,
      child: DatePickerBottomSheet(
        initialDate: _selectedDate ?? DateTime.now(),
        title: 'Select Date of File',
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showFileTypeBottomSheet(BuildContext context) async {
    final String? selected = await EcliniqBottomSheet.show<String>(
      context: context,
      child: FileTypeBottomSheet(
        fileTypes: _fileTypes,
        selectedFileType: _getFileTypeString(_selectedFileType),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedFileType = _getFileTypeFromString(selected);
      });
    }
  }

  Future<void> _showRecordForBottomSheet(BuildContext context) async {
    final String? selected = await EcliniqBottomSheet.show<String>(
      context: context,
      child: RecordForBottomSheet(
        recordForOptions: _recordForOptions,
        selectedRecordFor: _selectedRecordFor,
      ),
    );
    if (selected != null && selected != _selectedRecordFor) {
      setState(() {
        _selectedRecordFor = selected;
      });
    }
  }

  Future<void> _saveDetails() async {
    if (_fileNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a file name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Update the file with new details
      final updatedFile = widget.healthFile.copyWith(
        fileName: _fileNameController.text.trim(),
        fileType: _selectedFileType,
        recordFor: _selectedRecordFor,
        fileDate: _selectedDate,
      );

      // Update file via provider
      if (mounted) {
        final success = await context.read<HealthFilesProvider>().updateFile(
          updatedFile,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            CustomSuccessSnackBar(
              title: 'Details saved successfully',
              subtitle: 'Your changes have been saved successfully',
              context: context,
            ),
          );

          // Navigate back with updated file
          Navigator.pop(context, updatedFile);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _FullScreenPreview extends StatelessWidget {
  final String filePath;
  final bool isImage;

  const _FullScreenPreview({required this.filePath, required this.isImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: isImage && File(filePath).existsSync()
            ? InteractiveViewer(child: Image.file(File(filePath)))
            : const Center(
                child: Text(
                  'Preview not available',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }
}

// File Type Bottom Sheet
class FileTypeBottomSheet extends StatelessWidget {
  final List<String> fileTypes;
  final String selectedFileType;

  const FileTypeBottomSheet({
    super.key,
    required this.fileTypes,
    required this.selectedFileType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 15, left: 15),
            child: Text(
              'Select File Type',
              style: EcliniqTextStyles.headlineBMedium.copyWith(
                color: Color(0xff424242),
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: fileTypes.length,
              itemBuilder: (context, index) {
                final fileType = fileTypes[index];
                final isSelected = selectedFileType == fileType;
                return ListTile(
                  leading: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? EcliniqColors.light.strokeBrand
                            : EcliniqColors.light.strokeNeutralSubtle,
                      ),
                      shape: BoxShape.circle,
                      color: isSelected
                          ? EcliniqColors.light.bgContainerInteractiveBrand
                          : EcliniqColors.light.bgBaseOverlay,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EcliniqColors.light.bgBaseOverlay,
                      ),
                    ),
                  ),
                  title: Text(
                    fileType,
                    style: EcliniqTextStyles.bodyMedium.copyWith(
                      color: Color(0xff424242),
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
                  onTap: () {
                    Future.delayed(
                      const Duration(milliseconds: 300),
                      () => Navigator.pop(context, fileType),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Record For Bottom Sheet
class RecordForBottomSheet extends StatelessWidget {
  final List<String> recordForOptions;
  final String selectedRecordFor;

  const RecordForBottomSheet({
    super.key,
    required this.recordForOptions,
    required this.selectedRecordFor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Family Member',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: recordForOptions.length,
              itemBuilder: (context, index) {
                final recordFor = recordForOptions[index];
                final isSelected = recordFor == selectedRecordFor;

                return _RecordForOption(
                  recordFor: recordFor,
                  isSelected: isSelected,
                  onTap: () {
                    Navigator.pop(context, recordFor);
                  },
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

class _RecordForOption extends StatelessWidget {
  final String recordFor;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecordForOption({
    required this.recordFor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
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
                  recordFor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: const Color(0xFF2D2D2D),
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
  }
}
