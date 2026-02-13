import 'dart:io';

import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/patient_service.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/details/widgets/date_picker_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/services/local_file_storage_service.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/colors.g.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/select_member_bottom_sheet.dart';
import 'package:ecliniq/ecliniq_modules/screens/auth/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class EditDocumentDetailsPage extends StatefulWidget {
  final HealthFile? healthFile;
  final String? filePath;
  final String? fileName;

  const EditDocumentDetailsPage({
    super.key,
    this.healthFile,
    this.filePath,
    this.fileName,
  }) : assert(
         healthFile != null || (filePath != null && fileName != null),
         'Either healthFile or filePath+fileName must be provided',
       );

  @override
  State<EditDocumentDetailsPage> createState() =>
      _EditDocumentDetailsPageState();
}

class _EditDocumentDetailsPageState extends State<EditDocumentDetailsPage> {
  late TextEditingController _fileNameController;
  late HealthFileType _selectedFileType;
  String _selectedRecordFor = 'Self';
  String? _selectedRecordForId;
  String? _selectedRecordForRelation;
  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _isButtonPressed = false;
  bool get isButtonEnabled => !_isSaving;

  final LocalFileStorageService _storageService = LocalFileStorageService();
  final PatientService _patientService = PatientService();
  
  bool _isLoadingMembers = true;
  DependentData? _selfData;

  @override
  void initState() {
    super.initState();
    _fetchSelfData();

    if (widget.healthFile != null) {
      _fileNameController = TextEditingController(
        text: widget.healthFile!.fileName,
      );
      _selectedFileType = widget.healthFile!.fileType;
      _selectedRecordFor = widget.healthFile!.recordFor ?? 'Self';
      _selectedDate = widget.healthFile!.fileDate;
    } else {
      _fileNameController = TextEditingController(text: widget.fileName ?? '');
      _selectedFileType = HealthFileType.others;
      _selectedRecordFor = 'Self';
      _selectedDate = null;
    }
  }

  Future<void> _fetchSelfData() async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;

      if (authToken != null && authToken.isNotEmpty) {
        final response = await _patientService.getDependents(
          authToken: authToken,
        );

        if (response.success && response.self != null) {
          setState(() {
            _selfData = response.self;
            // If no record is selected yet, auto-select self
            if (_selectedRecordFor == 'Self' && _selfData != null) {
              _selectedRecordFor = _selfData!.fullName;
              _selectedRecordForId = _selfData!.id;
              _selectedRecordForRelation = _selfData!.relation;
            }
            _isLoadingMembers = false;
          });
        } else {
          setState(() {
            _isLoadingMembers = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  bool _isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension);
  }

  String get _displayRecordFor {
    if (_selectedRecordForRelation == null || 
        _selectedRecordForRelation!.toUpperCase() == 'SELF') {
      return _selectedRecordFor;
    }
    // Format the relation text
    final formattedRelation = _selectedRecordForRelation![0].toUpperCase() + 
                              _selectedRecordForRelation!.substring(1).toLowerCase();
    return '$_selectedRecordFor - $formattedRelation';
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
    final filePath = widget.healthFile?.filePath ?? widget.filePath;
    final fileExists = filePath != null && File(filePath).existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
        titleSpacing: 0,
        toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Edit Document Details',
            style: EcliniqTextStyles.responsiveHeadlineMedium(
              context,
            ).copyWith(color: Color(0xff424242), fontWeight: FontWeight.w500),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            EcliniqTextStyles.getResponsiveSize(context, 0.2),
          ),
          child: Container(
            color: const Color(0xFFB8B8B8),
            height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                  context,
                  horizontal: 10.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffF9F9F9),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 8.0),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: EcliniqTextStyles.getResponsiveWidth(
                            context,
                            120.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'File Name',
                                style:
                                    EcliniqTextStyles.responsiveHeadlineXMedium(
                                      context,
                                    ).copyWith(color: Color(0xff626060)),
                              ),
                              Text(
                                ' •',
                                style:
                                    EcliniqTextStyles.responsiveHeadlineLarge(
                                      context,
                                    ).copyWith(color: Color(0xffD92D20)),
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
                              hintStyle:
                                  EcliniqTextStyles.responsiveTitleXLarge(
                                    context,
                                  ).copyWith(color: Colors.grey.shade400),
                            ),
                            style: EcliniqTextStyles.responsiveTitleXLarge(
                              context,
                            ).copyWith(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
                      color: Color(0xffD6D6D6),
                      thickness: EcliniqTextStyles.getResponsiveSize(
                        context,
                        0.5,
                      ),
                    ),
                    Padding(
                      padding:
                          EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                            horizontal: 0,
                            context,
                            vertical: 2.0,
                          ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveWidth(
                              context,
                              120.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'File Type',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineXMedium(
                                        context,
                                      ).copyWith(color: Color(0xff626060)),
                                ),
                                Text(
                                  ' •',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineLarge(
                                        context,
                                      ).copyWith(color: Color(0xffD92D20)),
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
                                      style:
                                          EcliniqTextStyles.responsiveTitleXLarge(
                                            context,
                                          ).copyWith(color: Colors.black87),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Container(
                                    width: 0.5,
                                    height: 22,
                                    color: const Color(0xFFD6D6D6),
                                  ),
                                  SizedBox(width: 8),
                                  SvgPicture.asset(
                                    EcliniqIcons.arrowDown.assetPath,
                                    width: 20,
                                    height: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
                      color: Color(0xffD6D6D6),
                      thickness: EcliniqTextStyles.getResponsiveSize(
                        context,
                        0.5,
                      ),
                    ),
                    Padding(
                      padding:
                          EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                            horizontal: 0,
                            context,
                            vertical: 4.0,
                          ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveWidth(
                              context,
                              124.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Record For',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineXMedium(
                                        context,
                                      ).copyWith(color: Color(0xff626060)),
                                ),
                                Text(
                                  ' •',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineLarge(
                                        context,
                                      ).copyWith(color: Color(0xffD92D20)),
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
                                      _displayRecordFor,
                                      textAlign: TextAlign.right,
                                      style:
                                          EcliniqTextStyles.responsiveTitleXLarge(
                                            context,
                                          ).copyWith(color: Colors.black87),
                                    ),
                                  ),
                                    SizedBox(width: 8),
                                  Container(
                                    width: 0.5,
                                    height: 22,
                                    color: const Color(0xFFD6D6D6),
                                  ),
                                  SizedBox(width: 8),
                                  SvgPicture.asset(
                                    EcliniqIcons.arrowDown.assetPath,
                                    width:
                                        EcliniqTextStyles.getResponsiveIconSize(
                                          context,
                                          20.0,
                                        ),
                                    height:
                                        EcliniqTextStyles.getResponsiveIconSize(
                                          context,
                                          20.0,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: EcliniqTextStyles.getResponsiveSize(context, 1.0),
                      color: Color(0xffD6D6D6),
                      thickness: EcliniqTextStyles.getResponsiveSize(
                        context,
                        0.5,
                      ),
                    ),
                    SizedBox(
                      height: EcliniqTextStyles.getResponsiveSpacing(
                        context,
                        4.0,
                      ),
                    ),
                    Padding(
                      padding:
                          EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                            context,
                            vertical: 6.0,
                            horizontal: 0,
                          ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: EcliniqTextStyles.getResponsiveWidth(
                              context,
                              120.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'File Date',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineXMedium(
                                        context,
                                      ).copyWith(color: Color(0xff626060)),
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
                                      style:
                                          EcliniqTextStyles.responsiveTitleXLarge(
                                            context,
                                          ).copyWith(
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
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0),
              ),

              Container(
                width: double.infinity,
                height: EcliniqTextStyles.getResponsiveHeight(context, 480.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
                  ),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    EcliniqTextStyles.getResponsiveBorderRadius(context, 12.0),
                  ),
                  child: Stack(
                    children: [
                      if (fileExists && _isImageFile(filePath))
                        Image.file(
                          File(filePath),
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
                        bottom: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          12.0,
                        ),
                        right: EcliniqTextStyles.getResponsiveSpacing(
                          context,
                          8.0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (filePath != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _FullScreenPreview(
                                    filePath: filePath,
                                    isImage: _isImageFile(filePath),
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding:
                                EcliniqTextStyles.getResponsiveEdgeInsetsSymmetric(
                                  context,
                                  horizontal: 10.0,
                                  vertical: 10.0,
                                ),
                            decoration: BoxDecoration(
                              color: const Color(0x99FFFFFF),
                              borderRadius: BorderRadius.circular(
                                EcliniqTextStyles.getResponsiveBorderRadius(
                                  context,
                                  45.0,
                                ),
                              ),
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
                                SvgPicture.asset(
                                  EcliniqIcons.eyeOpen.assetPath,
                                  width:
                                      EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        24.0,
                                      ),
                                  height:
                                      EcliniqTextStyles.getResponsiveIconSize(
                                        context,
                                        24.0,
                                      ),
                                ),
                                SizedBox(
                                  width: EcliniqTextStyles.getResponsiveSpacing(
                                    context,
                                    8.0,
                                  ),
                                ),
                                Text(
                                  'Preview',
                                  style:
                                      EcliniqTextStyles.responsiveHeadlineXMedium(
                                        context,
                                      ).copyWith(color: Color(0xff424242)),
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
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0),
              ),

              SizedBox(
                width: double.infinity,
                height: EcliniqTextStyles.getResponsiveButtonHeight(
                  context,
                  baseHeight: 52.0,
                ),
                child: GestureDetector(
                  onTapDown: isButtonEnabled
                      ? (_) => setState(() => _isButtonPressed = true)
                      : null,
                  onTapUp: isButtonEnabled
                      ? (_) {
                          setState(() => _isButtonPressed = false);
                          _saveDetails();
                        }
                      : null,
                  onTapCancel: isButtonEnabled
                      ? () => setState(() => _isButtonPressed = false)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    decoration: BoxDecoration(
                      color: _isSaving
                          ? const Color(0xFF2372EC)
                          : _isButtonPressed
                          ? const Color(0xFF0E4395)
                          : const Color(0xFF2372EC),
                      borderRadius: BorderRadius.circular(
                        EcliniqTextStyles.getResponsiveBorderRadius(
                          context,
                          4.0,
                        ),
                      ),
                    ),
                    child: Center(
                      child: _isSaving
                          ? SizedBox(
                              width: EcliniqTextStyles.getResponsiveIconSize(
                                context,
                                24.0,
                              ),
                              height: EcliniqTextStyles.getResponsiveIconSize(
                                context,
                                24.0,
                              ),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth:
                                    EcliniqTextStyles.getResponsiveSize(
                                      context,
                                      2.5,
                                    ),
                              ),
                            )
                          : Text(
                              'Save Details',
                              style: EcliniqTextStyles.responsiveHeadlineMedium(
                                context,
                              ).copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderPreview() {
    final fileName = widget.healthFile?.fileName ?? widget.fileName ?? 'File';
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: EcliniqTextStyles.getResponsiveIconSize(context, 64),
              color: Colors.grey.shade400,
            ),
            SizedBox(
              height: EcliniqTextStyles.getResponsiveSpacing(context, 16.0),
            ),
            Text(
              fileName,
              style: EcliniqTextStyles.responsiveTitleXLarge(
                context,
              ).copyWith(color: Colors.grey.shade600),
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
        maximumDate: DateTime.now(), // Prevent future dates
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
    // Find currently selected dependent data for pre-selection in bottom sheet
    DependentData? currentlySelected;
    if (_selectedRecordForId != null) {
      // Try to match by ID if we have it
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final authToken = authProvider.authToken;
        if (authToken != null) {
          final response = await _patientService.getDependents(
            authToken: authToken,
          );
          if (response.success) {
            final allMembers = <DependentData>[];
            if (response.self != null) allMembers.add(response.self!);
            allMembers.addAll(response.dependents);
            
            currentlySelected = allMembers.firstWhere(
              (member) => member.id == _selectedRecordForId,
              orElse: () => allMembers.firstWhere(
                (member) => member.fullName == _selectedRecordFor,
                orElse: () => response.self!,
              ),
            );
          }
        }
      } catch (e) {
        // If error, proceed without pre-selection
      }
    }

    final DependentData? selected =
        await EcliniqBottomSheet.show<DependentData>(
          context: context,
          child: SelectMemberBottomSheet(
            currentlySelectedDependent: currentlySelected,
          ),
        );
    if (selected != null && mounted) {
      final selectedName = selected.fullName;
      final selectedId = selected.id;
      final selectedRelation = selected.relation;
      if (selectedName != _selectedRecordFor) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedRecordFor = selectedName;
              _selectedRecordForId = selectedId;
              _selectedRecordForRelation = selectedRelation;
            });
          }
        });
      }
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

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _isButtonPressed = true;
    });

    try {
      HealthFile savedFile;

      if (widget.healthFile != null) {
        final updatedFile = widget.healthFile!.copyWith(
          fileName: _fileNameController.text.trim(),
          fileType: _selectedFileType,
          recordFor: _selectedRecordFor,
          fileDate: _selectedDate,
        );

        if (mounted) {
          final success = await context.read<HealthFilesProvider>().updateFile(
            updatedFile,
          );

          if (!success) {
            throw Exception('Failed to update file');
          }

          savedFile = updatedFile;
        } else {
          return;
        }
      } else {
        if (widget.filePath == null) {
          throw Exception('File path is required');
        }

        final file = File(widget.filePath!);
        if (!await file.exists()) {
          throw Exception('File does not exist');
        }

        savedFile = await _storageService.saveFile(
          file: file,
          fileType: _selectedFileType,
          fileName: _fileNameController.text.trim(),
        );

        savedFile = savedFile.copyWith(
          recordFor: _selectedRecordFor,
          fileDate: _selectedDate,
        );

        await _storageService.saveFileMetadata(savedFile);

        if (mounted) {
          await context.read<HealthFilesProvider>().refresh();
        }
      }

      if (mounted) {
        CustomSuccessSnackBar.show(
          context: context,
          title: 'Success!',
          subtitle: 'Your action was completed',
          duration: const Duration(seconds: 5),
        );

        Navigator.pop(context, savedFile);
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isButtonPressed = false;
        });
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
        surfaceTintColor: Colors.transparent,
        leadingWidth: EcliniqTextStyles.getResponsiveWidth(context, 54.0),
        titleSpacing: 0,
        toolbarHeight: EcliniqTextStyles.getResponsiveHeight(context, 46.0),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: SvgPicture.asset(
            EcliniqIcons.arrowLeft.assetPath,
            width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          filePath.split('/').last,
          style: EcliniqTextStyles.responsiveHeadlineMedium(
            context,
          ).copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              EcliniqIcons.downloadfiles.assetPath,
              width: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
              height: EcliniqTextStyles.getResponsiveIconSize(context, 32.0),
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            onPressed: () async {},
          ),
          SizedBox(width: EcliniqTextStyles.getResponsiveSpacing(context, 8.0)),
        ],
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            EcliniqTextStyles.getResponsiveBorderRadius(context, 20.0),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EcliniqTextStyles.getResponsiveEdgeInsetsOnly(
              context,
              top: 15.0,
              left: 15.0,
            ),
            child: Text(
              'Select File Type',
              style: EcliniqTextStyles.responsiveHeadlineMedium(
                context,
              ).copyWith(color: Color(0xff424242)),
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
                    height: EcliniqTextStyles.getResponsiveSize(context, 20.0),
                    width: EcliniqTextStyles.getResponsiveSize(context, 20.0),
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
                      margin: EcliniqTextStyles.getResponsiveEdgeInsetsAll(
                        context,
                        4.0,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EcliniqColors.light.bgBaseOverlay,
                      ),
                    ),
                  ),
                  title: Text(
                    fileType,
                    style: EcliniqTextStyles.responsiveHeadlineXMedium(
                      context,
                    ).copyWith(color: Color(0xff424242)),
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
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 10.0),
          ),
        ],
      ),
    );
  }
}

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
      padding: EcliniqTextStyles.getResponsiveEdgeInsetsAll(context, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Family Member',
            style: EcliniqTextStyles.responsiveHeadlineXLarge(
              context,
            ).copyWith(color: Color(0xFF2D2D2D)),
          ),
          SizedBox(
            height: EcliniqTextStyles.getResponsiveSpacing(context, 24.0),
          ),
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
                  style: isSelected
                      ? EcliniqTextStyles.responsiveHeadlineBMedium(
                          context,
                        ).copyWith(color: const Color(0xFF2D2D2D))
                      : EcliniqTextStyles.responsiveHeadlineXMedium(
                          context,
                        ).copyWith(color: const Color(0xFF2D2D2D)),
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
