import 'dart:io';

import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/models/health_file_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/services/file_upload_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ecliniq/ecliniq_utils/widgets/ecliniq_loader.dart';

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
      if (requiredPermission != null) {
        try {
          PermissionStatus status = await requiredPermission.status;

          if (!status.isGranted && !status.isLimited) {
            status = await requiredPermission.request();

            if (status.isPermanentlyDenied) {
              // Store pending upload source to resume after settings
              _pendingUploadSource = source;
              _showPermissionDeniedDialog(
                safeContext,
                permissionTitle,
                permissionMessage,
                source: source,
              );
              return;
            }

            if (status.isDenied) {
              ScaffoldMessenger.of(safeContext).showSnackBar(
                SnackBar(
                  content: Text('$permissionTitle is required to continue'),
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
              return;
            }

            if (!status.isGranted && !status.isLimited) {
              ScaffoldMessenger.of(safeContext).showSnackBar(
                SnackBar(
                  content: Text('Cannot proceed without $permissionTitle'),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
          }
        } catch (e) {
          debugPrint('Permission check error: $e');
          ScaffoldMessenger.of(safeContext).showSnackBar(
            SnackBar(
              content: Text('Permission error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
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
            child: const Center(child: EcliniqLoader()),
          );
        },
      );

      if (mounted) {
        setState(() => _isUploading = true);
      }

      // Upload file
      HealthFile? healthFile;
      try {
        healthFile = await _uploadHandler.handleUpload(
          source: source,
          fileType: HealthFileType.others,
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

          // Check permission status
          if (source == UploadSource.camera || source == UploadSource.gallery) {
            Permission permission = source == UploadSource.camera
                ? Permission.camera
                : Permission.photos;

            final status = await permission.status;

            if (status.isPermanentlyDenied) {
              _showPermissionDeniedDialog(
                safeContext,
                iosPermissionTitle,
                iosPermissionMessage,
              );
            } else {
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

      if (healthFile != null) {
        if (mounted) {
          setState(() => _isUploading = false);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        final updatedFile = await Navigator.of(safeContext, rootNavigator: true)
            .push<HealthFile>(
              MaterialPageRoute(
                builder: (context) =>
                    EditDocumentDetailsPage(healthFile: healthFile!),
              ),
            );

        // Always refresh to show the uploaded file, even if user cancelled editing
        // The file was already saved when picked from gallery
        if (widget.onFileUploaded != null) {
          await widget.onFileUploaded!();
        }
        
        // Add a small delay to ensure file system operations are complete
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Refresh again to ensure UI is updated
        if (widget.onFileUploaded != null) {
          await widget.onFileUploaded!();
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF424242),
          ),
        ),
        content: Text(
          message.isEmpty
              ? 'Permission is permanently denied. Please enable it in app settings to continue.'
              : '$message\n\nPermission is permanently denied. Please enable it in app settings to continue.',
          style: const TextStyle(
            fontSize: 16,
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
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
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
            child: const Text(
              'Open Settings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
      
      final status = await requiredPermission.status;
      if (status.isGranted || status.isLimited) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload From',
            style: TextStyle(
              fontSize: 18,
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
                SvgPicture.asset(icon.assetPath, width: 24, height: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
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
