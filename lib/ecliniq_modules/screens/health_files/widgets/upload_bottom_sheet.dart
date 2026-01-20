import 'dart:io';

import 'package:ecliniq/ecliniq_core/media/media_permission_manager.dart';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_api/health_file_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/services/file_upload_handler.dart';
import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadBottomSheet extends StatefulWidget {
  final Future<void> Function()? onFileUploaded;

  const UploadBottomSheet({super.key, this.onFileUploaded});

  @override
  State<UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<UploadBottomSheet> with WidgetsBindingObserver {
  final FileUploadHandler _uploadHandler = FileUploadHandler();
  bool _isUploading = false;
  BuildContext? _storedParentContext;
  UploadSource? _pendingUploadSource;

  Future<void> _handleUpload(UploadSource source) async {
    if (!mounted) return;

    _storedParentContext = context;

    if (mounted) {
      Navigator.pop(context);
    }

    await Future.delayed(const Duration(milliseconds: 300));

    final safeContext = _storedParentContext;
    if (safeContext == null) return;

    // Check permissions for both iOS and Android
    if (!kIsWeb) {
      Permission? requiredPermission;
      String permissionTitle = 'Permission Required';
      String permissionMessage = '';

      switch (source) {
        case UploadSource.camera:
          requiredPermission = Permission.camera;
          permissionTitle = 'Camera Permission';
          permissionMessage =
              'We need access to your camera to take photos of your health documents';
          break;
        case UploadSource.gallery:
          requiredPermission = Permission.photos;
          permissionTitle = 'Photo Library Access';
          permissionMessage =
              'We need access to your photo library to select health documents and images';
          break;
        case UploadSource.files:
          // File picker handles its own permissions
          break;
      }

      // Handle permission if required
      // Only check for permanently denied - let image_picker handle the actual permission request
      if (requiredPermission != null) {
        try {
          // Check if permission is permanently denied - if so, direct to Settings
          final permissionResult = await MediaPermissionManager.getPermissionStatus(requiredPermission);
          
          if (permissionResult == MediaPermissionResult.permanentlyDenied) {
            // Permission is permanently denied, user must go to Settings
            _pendingUploadSource = source;
            _showPermissionDeniedDialog(
              safeContext,
              permissionTitle,
              permissionMessage,
              source: source,
            );
            return;
          }
          
          // For all other cases (granted, denied, notDetermined), let image_picker handle it
          // image_picker will show the permission dialog if needed
          // We'll catch any permission errors in the upload handler
        } catch (e) {
          debugPrint('Permission check error: $e');
          // Continue anyway - let image_picker handle it
        }
      }
    }

    // Permission granted, proceed with upload
    _proceedWithUpload(source);
  }

  /// Proceed with the actual upload after permission is granted
  Future<void> _proceedWithUpload(UploadSource source) async {
    final safeContext = _storedParentContext;
    if (safeContext == null || !mounted) return;
    BuildContext? loadingDialogContext;

    try {
      // Show loading dialog
      showDialog(
        context: safeContext,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingDialogContext = dialogContext;
          return PopScope(
            canPop: false,
            child: const Center(
              child: EcliniqLoader(size: 32, color: Color(0xFF2372EC)),
            ),
          );
        },
      );

      if (mounted) {
        setState(() => _isUploading = true);
      }

      // Pick file (don't save yet - will be saved when user clicks Save in EditDocumentDetailsPage)
      Map<String, String>? fileData;
      try {
        fileData = await _uploadHandler.handleUpload(
          source: source,
        );
      } catch (e) {
        // Handle permission errors from image_picker on iOS
        if (!kIsWeb && Platform.isIOS && e.toString().contains('permission')) {
          String iosPermissionTitle = '';
          String iosPermissionMessage = '';

          switch (source) {
            case UploadSource.camera:
              iosPermissionTitle = 'Camera Permission';
              iosPermissionMessage =
                  'We need access to your camera to take photos of your health documents';
              break;
            case UploadSource.gallery:
              iosPermissionTitle = 'Photo Library Access';
              iosPermissionMessage =
                  'We need access to your photo library to select health documents and images';
              break;
            default:
              break;
          }

          // Close loading dialog
          _closeLoadingDialog(loadingDialogContext, safeContext);
          loadingDialogContext = null;

          // Check permission status using MediaPermissionManager
          if (source == UploadSource.camera || source == UploadSource.gallery) {
            Permission permission = source == UploadSource.camera
                ? Permission.camera
                : Permission.photos;

            final permissionResult = await MediaPermissionManager.getPermissionStatus(permission);

            // On iOS, if permission is denied (even if not permanently), we should direct to Settings
            // because requesting again might make it permanently denied
            if (permissionResult == MediaPermissionResult.permanentlyDenied ||
                (Platform.isIOS && permissionResult == MediaPermissionResult.denied)) {
              _pendingUploadSource = source;
              _showPermissionDeniedDialog(
                safeContext,
                iosPermissionTitle,
                iosPermissionMessage,
                source: source,
              );
            } else {
              // On Android, we can retry
              ScaffoldMessenger.of(safeContext).showSnackBar(
                SnackBar(
                  content: Text('$iosPermissionTitle is required to continue'),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () {
                      if (_storedParentContext != null) {
                        _handleUpload(source);
                      }
                    },
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(safeContext).showSnackBar(
              SnackBar(
                content: Text('Failed to access: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
        rethrow;
      }

      // Close loading dialog BEFORE navigating
      _closeLoadingDialog(loadingDialogContext, safeContext);
      loadingDialogContext = null;
      await Future.delayed(const Duration(milliseconds: 200));

      if (fileData != null && fileData['path'] != null) {
        if (mounted) {
          setState(() => _isUploading = false);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Use EcliniqRouter for navigation - it uses global navigator key
        // This ensures navigation works even after bottom sheet is closed
        // Pass file path instead of saved HealthFile - file will be saved when user clicks Save
        try {
          final savedFile = await EcliniqRouter.push<HealthFile>(
            EditDocumentDetailsPage(
              filePath: fileData['path']!,
              fileName: fileData['name'] ?? 'file',
            ),
          );

          // Refresh after file is saved (user clicked Save Details)
          if (savedFile != null && widget.onFileUploaded != null) {
            await widget.onFileUploaded!();
          }
        } catch (e) {
          debugPrint('Error navigating to EditDocumentDetailsPage: $e');
          // Fallback: try with context if EcliniqRouter fails
          if (safeContext != null && mounted) {
            try {
              final savedFile = await Navigator.of(safeContext, rootNavigator: true)
                  .push<HealthFile>(
                    MaterialPageRoute(
                      builder: (context) => EditDocumentDetailsPage(
                        filePath: fileData?['path']!,
                        fileName: fileData?['name'] ?? 'file',
                      ),
                    ),
                  );

              // Refresh after file is saved (user clicked Save Details)
              if (savedFile != null && widget.onFileUploaded != null) {
                await widget.onFileUploaded!();
              }
            } catch (e2) {
              debugPrint('Fallback navigation also failed: $e2');
            }
          }
        }
      } else {
        // User cancelled
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(safeContext).showSnackBar(
            const SnackBar(
              content: Text('Upload cancelled'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      _closeLoadingDialog(loadingDialogContext, safeContext);
      loadingDialogContext = null;

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(safeContext).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }

      _closeLoadingDialog(loadingDialogContext, safeContext);
      loadingDialogContext = null;
      _storedParentContext = null;
    }
  }

  /// Helper method to safely close loading dialog
  void _closeLoadingDialog(
    BuildContext? dialogContext,
    BuildContext fallbackContext,
  ) {
    if (dialogContext == null) return;

    try {
      Navigator.of(dialogContext, rootNavigator: true).pop();
    } catch (_) {
      try {
        if (Navigator.of(fallbackContext, rootNavigator: true).canPop()) {
          Navigator.of(fallbackContext, rootNavigator: true).pop();
        }
      } catch (_) {}
    }
  }

  void _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message, {
    UploadSource? source,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style:  EcliniqTextStyles.responsiveHeadlineLarge(context).copyWith(
  
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
        ),
        content: Text(
          message.isEmpty
              ? Platform.isIOS
                  ? 'Permission is required. Please enable it in Settings > Ecliniq to continue.'
                  : 'Permission is permanently denied. Please enable it in app settings to continue.'
              : Platform.isIOS
                  ? '$message\n\nPlease enable this permission in Settings > Ecliniq to continue.'
                  : '$message\n\nPermission is permanently denied. Please enable it in app settings to continue.',
          style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
           
            color: Color(0xFF8E8E8E),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child:  Text(
              'Cancel',
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
             
                fontWeight: FontWeight.w500,
                color: Color(0xFF424242),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Store the source to resume after returning from settings
              if (source != null) {
                _pendingUploadSource = source;
              }
              await openAppSettings();
              // On Android, when user returns from settings, didChangeAppLifecycleState
              // will be called and check if permission is granted
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2372EC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:  Text(
              'Open Settings',
              style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith( fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _storedParentContext = null;
    _pendingUploadSource = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app comes back to foreground, check if permission was granted
    if (state == AppLifecycleState.resumed && _pendingUploadSource != null) {
      _checkPermissionAndProceed(_pendingUploadSource!);
    }
  }

  /// Check permission status and proceed with upload if granted
  Future<void> _checkPermissionAndProceed(UploadSource source) async {
    if (!mounted || _storedParentContext == null) return;

    final safeContext = _storedParentContext!;
    Permission? requiredPermission;

    if (source == UploadSource.camera) {
      requiredPermission = Permission.camera;
    } else if (source == UploadSource.gallery) {
      requiredPermission = Permission.photos;
    } else {
      // For files, no permission check needed
      _pendingUploadSource = null;
      _proceedWithUpload(source);
      return;
    }

    if (requiredPermission != null) {
      // Add a small delay to ensure app is fully resumed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use MediaPermissionManager for better iOS 17 handling
      final permissionResult = await MediaPermissionManager.getPermissionStatus(requiredPermission);
      if (permissionResult == MediaPermissionResult.granted) {
        // Permission granted, proceed with upload
        _pendingUploadSource = null;
        _proceedWithUpload(source);
      } else {
        // Permission still not granted, clear pending
        _pendingUploadSource = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20), bottom: Radius.circular(16)),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            'Upload From',
            style: EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
        
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 24),
          _ActionOption(
            icon: EcliniqIcons.camera,
            backgroundColor: const Color(0xFFE3F2FD),
            title: 'Take a Photo',
            onTap: () => _handleUpload(UploadSource.camera),
            enabled: !_isUploading,
          ),
          const SizedBox(height: 16),
          _ActionOption(
            icon: EcliniqIcons.gallery,
            backgroundColor: const Color(0xFFE3F2FD),
            title: 'Gallery',
            onTap: () => _handleUpload(UploadSource.gallery),
            enabled: !_isUploading,
          ),
          const SizedBox(height: 16),
          _ActionOption(
            icon: EcliniqIcons.fileSend,
            backgroundColor: const Color(0xFFFFEBEE),
            title: 'Files',
            isDestructive: true,
            onTap: () => _handleUpload(UploadSource.files),
            enabled: !_isUploading,
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
  final bool enabled;

  const _ActionOption({
    required this.icon,
    required this.backgroundColor,
    required this.title,
    this.isDestructive = false,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
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
                  width: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                  height: EcliniqTextStyles.getResponsiveIconSize(context, 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style:  EcliniqTextStyles.responsiveHeadlineBMedium(context).copyWith(
                 
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF424242),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}