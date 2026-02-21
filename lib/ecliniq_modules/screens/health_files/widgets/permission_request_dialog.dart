import 'package:ecliniq/ecliniq_ui/lib/tokens/styles.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


class PermissionRequestDialog extends StatelessWidget {
  final Permission permission;
  final String title;
  final String message;
  final String? imageIcon;
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const PermissionRequestDialog({
    super.key,
    required this.permission,
    required this.title,
    required this.message,
    this.imageIcon,
    this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                _getIconForPermission(permission),
                size: 40,
                color: const Color(0xFF2372EC),
              ),
            ),
            const SizedBox(height: 24),

            
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            
            Text(
              message,
              style:  EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
               
                color: Color(0xFF8E8E8E),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDenied?.call();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:  Text(
                      'Cancel',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
                   
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final status = await permission.request();
                      
                      if (status.isGranted || status.isLimited) {
                        onGranted?.call();
                      } else if (status.isPermanentlyDenied) {
                        
                        _showSettingsDialog(context);
                      } else {
                        onDenied?.call();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2372EC),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:  Text(
                      'Continue',
                      style: EcliniqTextStyles.responsiveTitleXLarge(context).copyWith(
             
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForPermission(Permission permission) {
    if (permission == Permission.camera) {
      return Icons.camera_alt;
    } else if (permission == Permission.photos || permission == Permission.storage) {
      return Icons.photo_library;
    }
    return Icons.folder;
  }

  void _showSettingsDialog(BuildContext context) {
    final dialogTitle = title; 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$dialogTitle is permanently denied. Please enable it in app settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2372EC),
              foregroundColor: Colors.white,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

