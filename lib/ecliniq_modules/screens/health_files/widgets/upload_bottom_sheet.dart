import 'dart:io';
import 'package:ecliniq/ecliniq_core/router/route.dart';
import 'package:ecliniq/ecliniq_icons/icons.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/edit_doc_details.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/models/health_file_model.dart';
import 'package:ecliniq/ecliniq_modules/screens/health_files/services/file_upload_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadBottomSheet extends StatefulWidget {
  final Function()? onFileUploaded;

  const UploadBottomSheet({
    super.key,
    this.onFileUploaded,
  });

  @override
  State<UploadBottomSheet> createState() => _UploadBottomSheetState();
}

class _UploadBottomSheetState extends State<UploadBottomSheet> {
  final FileUploadHandler _uploadHandler = FileUploadHandler();
  bool _isUploading = false;

  Future<void> _handleUpload(UploadSource source) async {
  final parentContext = Navigator.of(context, rootNavigator: true).context;
  
  // Close upload bottom sheet first
  if (mounted) {
    Navigator.pop(context);
  }

  // Small delay to ensure bottom sheet is fully closed
  await Future.delayed(const Duration(milliseconds: 300));

  // Check permissions for both iOS and Android
  // On iOS: Check permission first, if granted open gallery directly, if not let image_picker request it
  // On Android: Check and request permission manually
  if (!kIsWeb) {
    // Determine which permission is needed
    Permission? requiredPermission;
    String permissionTitle = 'Permission Required';
    String permissionMessage = '';

    switch (source) {
      case UploadSource.camera:
        requiredPermission = Permission.camera;
        permissionTitle = 'Camera Permission';
        permissionMessage = 'We need access to your camera to take photos of your health documents';
        break;
      case UploadSource.gallery:
        requiredPermission = Permission.photos;
        permissionTitle = 'Photo Library Access';
        permissionMessage = 'We need access to your photo library to select health documents and images';
        break;
      case UploadSource.files:
        // File picker handles its own permissions
        break;
    }

    // Handle permission if required
    if (requiredPermission != null) {
      try {
        // Get current permission status
        PermissionStatus status = await requiredPermission.status;
        
          // Check and request permission for both platforms
          if (!status.isGranted && !status.isLimited) {
            // Permission not granted, try requesting it
            status = await requiredPermission.request();
            
            // Check result after request
            if (status.isPermanentlyDenied) {
              // Permission was permanently denied, show settings dialog
              _showPermissionDeniedDialog(parentContext, permissionTitle, permissionMessage);
              return;
            }
            
            if (status.isDenied) {
              // User denied but not permanently - show retry option
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Text('$permissionTitle is required to continue'),
                  action: SnackBarAction(
                    label: 'Retry',
                    onPressed: () => _handleUpload(source),
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
              return;
            }
            
            // If still not granted after request, something went wrong
            if (!status.isGranted && !status.isLimited) {
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(
                  content: Text('Cannot proceed without $permissionTitle'),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
          }
        
        // Permission is granted or limited (both are OK) - proceed
        // On iOS: If not granted yet, image_picker will request it automatically when called
      } catch (e) {
        print('Permission check error: $e');
        ScaffoldMessenger.of(parentContext).showSnackBar(
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
  BuildContext? loadingDialogContext;
  
  try {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (dialogContext) {
          loadingDialogContext = dialogContext;
          return WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }

    setState(() => _isUploading = true);

    // Upload file - image_picker will handle iOS permissions automatically
    HealthFile? healthFile;
    try {
      healthFile = await _uploadHandler.handleUpload(
        source: source,
        fileType: HealthFileType.others,
      );
    } catch (e) {
      // Handle permission errors from image_picker on iOS
      if (!kIsWeb && Platform.isIOS && e.toString().contains('permission')) {
        String permissionTitle = '';
        String permissionMessage = '';
        
        switch (source) {
          case UploadSource.camera:
            permissionTitle = 'Camera Permission';
            permissionMessage = 'We need access to your camera to take photos of your health documents';
            break;
          case UploadSource.gallery:
            permissionTitle = 'Photo Library Access';
            permissionMessage = 'We need access to your photo library to select health documents and images';
            break;
          default:
            break;
        }
        
        // Close loading dialog
        if (loadingDialogContext != null && mounted) {
          try {
            Navigator.of(loadingDialogContext!, rootNavigator: true).pop();
          } catch (_) {}
        }
        
        // Check permission status to see if it's permanently denied
        if (source == UploadSource.camera || source == UploadSource.gallery) {
          Permission? permission = source == UploadSource.camera 
              ? Permission.camera 
              : Permission.photos;
          
          final status = await permission.status;
          
          if (status.isPermanentlyDenied) {
            _showPermissionDeniedDialog(parentContext, permissionTitle, permissionMessage);
          } else {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              SnackBar(
                content: Text('$permissionTitle is required to continue'),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => _handleUpload(source),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text('Failed to access: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        return;
      }
      
      // Re-throw if not a permission error
      rethrow;
    }

    // Close loading dialog BEFORE navigating
    if (loadingDialogContext != null) {
      try {
        if (Navigator.of(parentContext, rootNavigator: true).canPop()) {
          Navigator.of(parentContext, rootNavigator: true).pop();
        }
        loadingDialogContext = null;
        // Small delay to ensure dialog is fully dismissed
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('Error closing loading dialog: $e');
        loadingDialogContext = null;
      }
    }

    if (healthFile != null) {
      // Ensure loading is dismissed and state is reset before navigation
      if (mounted) {
        setState(() => _isUploading = false);
      }
      
      // Ensure dialog is fully dismissed before navigation
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate to edit page
      final updatedFile = await EcliniqRouter.push<HealthFile>(
        EditDocumentDetailsPage(healthFile: healthFile),
      );
      
      if (updatedFile != null) {
        // Add a small delay before calling refresh to prevent scroll issues
        await Future.delayed(const Duration(milliseconds: 300));
        widget.onFileUploaded?.call();
      }
    } else {
      // User cancelled
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
            content: Text('Upload cancelled'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  } catch (e) {
    // Close loading dialog on error
    if (loadingDialogContext != null) {
      try {
        Navigator.of(parentContext, rootNavigator: true).pop(loadingDialogContext);
        loadingDialogContext = null;
      } catch (_) {
        try {
          if (mounted && Navigator.of(parentContext, rootNavigator: true).canPop()) {
            Navigator.of(parentContext, rootNavigator: true).pop();
          }
        } catch (_) {}
      }
    }

    // Show error
    if (mounted) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    // Ensure loading state is reset
    if (mounted) {
      setState(() => _isUploading = false);
    }
    
    // Final safety check to close any remaining dialogs
    if (loadingDialogContext != null) {
      try {
        if (Navigator.of(parentContext, rootNavigator: true).canPop()) {
          Navigator.of(parentContext, rootNavigator: true).pop();
        }
      } catch (_) {}
    }
  }
}


  void _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
            onPressed: () => Navigator.pop(context),
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
              Navigator.pop(context);
              await openAppSettings();
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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
                SvgPicture.asset(
                  icon.assetPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF424242),
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
