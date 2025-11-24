import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/file_type_screen.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/models/health_file_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/providers/health_files_provider.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/action_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/error_snackbar.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/snackbar/success_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class FileCategory {
  final HealthFileType fileType;
  final String backgroundImage;
  final String overlayImage;

  FileCategory({
    required this.fileType,
    required this.backgroundImage,
    required this.overlayImage,
  });

  String get title => fileType.displayName;
}

class MyFilesWidget extends StatelessWidget {
  const MyFilesWidget({super.key});

  static final List<FileCategory> _categories = [
    FileCategory(
      fileType: HealthFileType.labReports,
      backgroundImage: EcliniqIcons.blue.assetPath,
      overlayImage: EcliniqIcons.blueGradient.assetPath,
    ),
    FileCategory(
      fileType: HealthFileType.scanImaging,
      backgroundImage: EcliniqIcons.green.assetPath,
      overlayImage: EcliniqIcons.greenframe.assetPath,
    ),
    FileCategory(
      fileType: HealthFileType.prescriptions,
      backgroundImage: EcliniqIcons.orange.assetPath,
      overlayImage: EcliniqIcons.orangeframe.assetPath,
    ),
    FileCategory(
      fileType: HealthFileType.invoices,
      backgroundImage: EcliniqIcons.yellow.assetPath,
      overlayImage: EcliniqIcons.yellowframe.assetPath,
    ),
    FileCategory(
      fileType: HealthFileType.vaccinations,
      backgroundImage: EcliniqIcons.blueDark.assetPath,
      overlayImage: EcliniqIcons.blueDarkframe.assetPath,
    ),
    FileCategory(
      fileType: HealthFileType.others,
      backgroundImage: EcliniqIcons.red.assetPath,
      overlayImage: EcliniqIcons.redframe.assetPath,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Files',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff424242),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 170,
            child: Consumer<HealthFilesProvider>(
              builder: (context, provider, child) {
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final fileCount = provider.getFileCountByType(
                      category.fileType,
                    );
                    return FileCategoryCard(
                      category: category,
                      fileCount: fileCount,
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class FileCategoryCard extends StatelessWidget {
  final FileCategory category;
  final int fileCount;

  const FileCategoryCard({
    super.key,
    required this.category,
    required this.fileCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        EcliniqRouter.push(FileTypeScreen(fileType: category.fileType));
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  category.backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned(
                top: 22,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$fileCount ${fileCount == 1 ? 'File' : 'Files'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: SizedBox(
                  height: 76,
                  child: SvgPicture.asset(
                    category.overlayImage,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
