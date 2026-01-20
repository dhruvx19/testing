import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:permission_handler/permission_handler.dart';

class MediaPermissionManager {
  static Future<MediaPermissionStatus> requestAllPermissions() async {
    if (kIsWeb) {
      return MediaPermissionStatus.allGranted;
    }

    try {
      final cameraStatus = await _requestCameraPermission();

      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Request photos permission
      final photosStatus = await _requestPhotosPermission();


      // Determine overall status
      if (cameraStatus == MediaPermissionResult.granted &&
          photosStatus == MediaPermissionResult.granted) {
        return MediaPermissionStatus.allGranted;
      } else if (cameraStatus == MediaPermissionResult.permanentlyDenied ||
          photosStatus == MediaPermissionResult.permanentlyDenied) {
        return MediaPermissionStatus.somePermanentlyDenied;
      } else if (cameraStatus == MediaPermissionResult.denied ||
          photosStatus == MediaPermissionResult.denied) {
        return MediaPermissionStatus.someDenied;
      } else {
        return MediaPermissionStatus.partialGranted;
      }
    } catch (e) {
      debugPrint('Error in requestAllPermissions: $e');
      return MediaPermissionStatus.error;
    }
  }

  /// Request camera permission
  static Future<MediaPermissionResult> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;

      debugPrint('Camera permission current status: $status');

      // If already granted or limited, return granted
      if (status.isGranted || status.isLimited) {
        return MediaPermissionResult.granted;
      }

      // If permanently denied, return permanently denied (user must go to Settings)
      if (status.isPermanentlyDenied) {
        debugPrint('Camera permission is permanently denied');
        return MediaPermissionResult.permanentlyDenied;
      }

      if (Platform.isIOS && status.isDenied) {
        debugPrint(
          'Camera permission was previously denied on iOS. User must grant in Settings.',
        );
        return MediaPermissionResult.denied;
      }

      debugPrint(
        'Requesting camera permission. Current status: $status, isNotDetermined:',
      );
      final newStatus = await Permission.camera.request();
      debugPrint('Camera permission request result: $newStatus');

      if (newStatus.isGranted || newStatus.isLimited) {
        return MediaPermissionResult.granted;
      } else if (newStatus.isPermanentlyDenied) {
        return MediaPermissionResult.permanentlyDenied;
      } else {
        return MediaPermissionResult.denied;
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('Error requesting camera permission: $e');
      return MediaPermissionResult.error;
    }
  }

  /// Request photos permission
  static Future<MediaPermissionResult> _requestPhotosPermission() async {
    try {
      final status = await Permission.photos.status;

      debugPrint('Photos permission current status: $status');

      // If already granted or limited, return granted
      if (status.isGranted || status.isLimited) {
        return MediaPermissionResult.granted;
      }

      // If permanently denied, return permanently denied (user must go to Settings)
      if (status.isPermanentlyDenied) {
        debugPrint('Photos permission is permanently denied');
        return MediaPermissionResult.permanentlyDenied;
      }
      if (Platform.isIOS && status.isDenied) {
        debugPrint(
          'Photos permission was previously denied on iOS. User must grant in Settings.',
        );
        return MediaPermissionResult.denied;
      }

      debugPrint(
        'Requesting photos permission. Current status: $status, isNotDetermined: ',
      );
      final newStatus = await Permission.photos.request();
      debugPrint('Photos permission request result: $newStatus');

      if (newStatus.isGranted || newStatus.isLimited) {
        return MediaPermissionResult.granted;
      } else if (newStatus.isPermanentlyDenied) {
        return MediaPermissionResult.permanentlyDenied;
      } else {
        return MediaPermissionResult.denied;
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('Error requesting photos permission: $e');
      return MediaPermissionResult.error;
    }
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraGranted() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      return false;
    }
  }

  /// Check if photos permission is granted
  static Future<bool> isPhotosGranted() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      return false;
    }
  }

  /// Check if a specific permission is permanently denied
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    if (kIsWeb) return false;
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// Get permission status for a specific permission
  static Future<MediaPermissionResult> getPermissionStatus(
    Permission permission,
  ) async {
    if (kIsWeb) return MediaPermissionResult.granted;
    try {
      final status = await permission.status;
      if (status.isGranted || status.isLimited) {
        return MediaPermissionResult.granted;
      } else if (status.isPermanentlyDenied) {
        return MediaPermissionResult.permanentlyDenied;
      } else if (status.isDenied) {
        return MediaPermissionResult.denied;
      } else {
        return MediaPermissionResult.denied;
      }
    } catch (e) {
      return MediaPermissionResult.error;
    }
  }

  /// Request a specific permission
  static Future<MediaPermissionResult> requestPermission(
    Permission permission,
  ) async {
    if (kIsWeb) return MediaPermissionResult.granted;
    try {
      final status = await permission.status;

      debugPrint('Permission $permission current status: $status');

      // If already granted or limited, return granted
      if (status.isGranted || status.isLimited) {
        return MediaPermissionResult.granted;
      }

      // If permanently denied, return permanently denied (user must go to Settings)
      if (status.isPermanentlyDenied) {
        debugPrint('Permission $permission is permanently denied');
        return MediaPermissionResult.permanentlyDenied;
      }

      if (Platform.isIOS && status.isDenied) {
        debugPrint(
          'Permission $permission was previously denied on iOS. User must grant in Settings.',
        );
        return MediaPermissionResult.denied;
      }

      debugPrint('Requesting permission $permission. Current status: $status');
      final newStatus = await permission.request();
      debugPrint('Permission $permission request result: $newStatus');

      if (newStatus.isGranted || newStatus.isLimited) {
        return MediaPermissionResult.granted;
      } else if (newStatus.isPermanentlyDenied) {
        return MediaPermissionResult.permanentlyDenied;
      } else {
        return MediaPermissionResult.denied;
      }
    } catch (e) {
      debugPrint('Error requesting permission $permission: $e');
      return MediaPermissionResult.error;
    }
  }
}

/// Overall status of media permissions
enum MediaPermissionStatus {
  allGranted,
  partialGranted,
  someDenied,
  somePermanentlyDenied,
  error,
}

/// Result of a single permission request
enum MediaPermissionResult { granted, denied, permanentlyDenied, error }
