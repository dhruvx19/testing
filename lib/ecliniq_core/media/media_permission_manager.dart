import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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

      
      final photosStatus = await _requestPhotosPermission();


      
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
      
      return MediaPermissionStatus.error;
    }
  }

  
  static Future<MediaPermissionResult> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.status;

      

      
      if (status.isGranted || status.isLimited) {
        return MediaPermissionResult.granted;
      }

      
      if (status.isPermanentlyDenied) {
        
        return MediaPermissionResult.permanentlyDenied;
      }

      if (Platform.isIOS && status.isDenied) {
        
        return MediaPermissionResult.denied;
      }

      
      final newStatus = await Permission.camera.request();
      

      if (newStatus.isGranted || newStatus.isLimited) {
        return MediaPermissionResult.granted;
      } else if (newStatus.isPermanentlyDenied) {
        return MediaPermissionResult.permanentlyDenied;
      } else {
        return MediaPermissionResult.denied;
      }
    } catch (e) {
      
      
      return MediaPermissionResult.error;
    }
  }

  
  static Future<MediaPermissionResult> _requestPhotosPermission() async {
    try {
      final status = await Permission.photos.status;

      

      
      if (status.isGranted || status.isLimited) {
        return MediaPermissionResult.granted;
      }

      
      if (status.isPermanentlyDenied) {
        
        return MediaPermissionResult.permanentlyDenied;
      }
      if (Platform.isIOS && status.isDenied) {
        
        return MediaPermissionResult.denied;
      }

      
      final newStatus = await Permission.photos.request();
      

      if (newStatus.isGranted || newStatus.isLimited) {
        return MediaPermissionResult.granted;
      } else if (newStatus.isPermanentlyDenied) {
        return MediaPermissionResult.permanentlyDenied;
      } else {
        return MediaPermissionResult.denied;
      }
    } catch (e) {
      
      
      return MediaPermissionResult.error;
    }
  }

  
  static Future<bool> isCameraGranted() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> isPhotosGranted() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      return false;
    }
  }

  
  static Future<bool> isPermanentlyDenied(Permission permission) async {
    if (kIsWeb) return false;
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  
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

  
  static Future<MediaPermissionResult> requestPermission(
    Permission permission,
  ) async {
    if (kIsWeb) return MediaPermissionResult.granted;
    try {
      final status = await permission.status;

      

      
      if (status.isGranted || status.isLimited) {
        return MediaPermissionResult.granted;
      }

      
      if (status.isPermanentlyDenied) {
        
        return MediaPermissionResult.permanentlyDenied;
      }

      if (Platform.isIOS && status.isDenied) {
        
        return MediaPermissionResult.denied;
      }

      
      final newStatus = await permission.request();
      

      if (newStatus.isGranted || newStatus.isLimited) {
        return MediaPermissionResult.granted;
      } else if (newStatus.isPermanentlyDenied) {
        return MediaPermissionResult.permanentlyDenied;
      } else {
        return MediaPermissionResult.denied;
      }
    } catch (e) {
      
      return MediaPermissionResult.error;
    }
  }
}


enum MediaPermissionStatus {
  allGranted,
  partialGranted,
  someDenied,
  somePermanentlyDenied,
  error,
}


enum MediaPermissionResult { granted, denied, permanentlyDenied, error }
