import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_ui/lib/widgets/bottom_sheet/bottom_sheet.dart';
import 'package:ecliniq/ecliniq_utils/bottom_sheets/health_files/delete_file_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ActionBottomSheet extends StatefulWidget {
  final HealthFile? healthFile;
  final VoidCallback? onEditDocument;
  final VoidCallback? onDownloadDocument;
  final VoidCallback? onDeleteDocument;
  final BuildContext? parentContext;

  const ActionBottomSheet({
    super.key,
    this.healthFile,
    this.onEditDocument,
    this.onDownloadDocument,
    this.onDeleteDocument,
    this.parentContext,
  });

  @override
  State<ActionBottomSheet> createState() => _ActionBottomSheetState();
}

class _ActionBottomSheetState extends State<ActionBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Choose Action',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
          
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 24),

          _ActionOption(
            icon: EcliniqIcons.penEdit,
            backgroundColor: const Color(0xFFE3F2FD),
            title: 'Edit Document Details',
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 200));
              if (widget.healthFile != null && context.mounted) {
                EcliniqRouter.push(
                  EditDocumentDetailsPage(healthFile: widget.healthFile!),
                );
              } else {
                widget.onEditDocument?.call();
              }
            },
          ),

          const SizedBox(height: 16),

          _ActionOption(
            icon: EcliniqIcons.download,
            backgroundColor: const Color(0xFFE3F2FD),
            title: 'Download Document',
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 200));
              widget.onDownloadDocument?.call();
            },
          ),

          const SizedBox(height: 16),

          _ActionOption(
            icon: EcliniqIcons.delete,
            backgroundColor: const Color(0xFFFFEBEE),
            title: 'Delete Document',
            isDestructive: true,
            onTap: () async {
              // Get parent context before closing this bottom sheet
              final parentCtx = widget.parentContext ?? context;
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 200));
              
              // Show delete confirmation bottom sheet using parent context
              if (parentCtx.mounted) {
                final confirmed = await EcliniqBottomSheet.show<bool>(
                  context: parentCtx,
                  child: const DeleteFileBottomSheet(),
                );
                
                debugPrint('Delete confirmation result: $confirmed');
                
                // If user confirmed deletion, call the delete callback
                if (confirmed == true && parentCtx.mounted) {
                  debugPrint('Calling delete callback...');
                  widget.onDeleteDocument?.call();
                  debugPrint('Delete callback called');
                } else {
                  debugPrint('Delete not confirmed or context not mounted. confirmed: $confirmed, mounted: ${parentCtx.mounted}');
                }
              } else {
                debugPrint('Parent context not mounted');
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ActionOption extends StatelessWidget {
  final EcliniqIcons icon;

  final Color backgroundColor;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionOption({
    required this.icon,

    required this.backgroundColor,
    required this.title,
    this.isDestructive = false,
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                icon.assetPath,
                width: EcliniqTextStyles.getResponsiveIconSize(context, 26),
                height: EcliniqTextStyles.getResponsiveIconSize(context, 26),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  title,
                  style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                  
                    fontWeight: FontWeight.w400,
                    color: isDestructive
                        ? const Color(0xFFF04248)
                        : const Color(0xFF424242),
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
