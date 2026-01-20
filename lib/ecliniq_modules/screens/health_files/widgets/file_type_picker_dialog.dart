import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Dialog for selecting file type/category
class FileTypePickerDialog extends StatelessWidget {
  final Function(HealthFileType) onFileTypeSelected;

  const FileTypePickerDialog({
    super.key,
    required this.onFileTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final fileTypes = [
      HealthFileType.labReports,
      HealthFileType.scanImaging,
      HealthFileType.prescriptions,
      HealthFileType.invoices,
      HealthFileType.vaccinations,
      HealthFileType.others,
    ];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              'Select File Category',
              style: EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
              
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 20),
            ...fileTypes.map((fileType) => _FileTypeOption(
              fileType: fileType,
              onTap: () {
                onFileTypeSelected(fileType);
                Navigator.of(context).pop();
              },
            )),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeOption extends StatelessWidget {
  final HealthFileType fileType;
  final VoidCallback onTap;

  const _FileTypeOption({
    required this.fileType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String backgroundImage;
    switch (fileType) {
      case HealthFileType.labReports:
        backgroundImage = EcliniqIcons.blue.assetPath;
        break;
      case HealthFileType.scanImaging:
        backgroundImage = EcliniqIcons.green.assetPath;
        break;
      case HealthFileType.prescriptions:
        backgroundImage = EcliniqIcons.orange.assetPath;
        break;
      case HealthFileType.invoices:
        backgroundImage = EcliniqIcons.yellow.assetPath;
        break;
      case HealthFileType.vaccinations:
        backgroundImage = EcliniqIcons.blueDark.assetPath;
        break;
      case HealthFileType.others:
        backgroundImage = EcliniqIcons.red.assetPath;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SvgPicture.asset(
                      backgroundImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    fileType.displayName,
                    style:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                     
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

