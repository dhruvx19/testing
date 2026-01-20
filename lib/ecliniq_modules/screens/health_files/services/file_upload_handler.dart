import 'dart:io';

import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:image_picker/image_picker.dart';
import '../../../../ecliniq_api/health_file_model.dart';
import 'local_file_storage_service.dart';

/// Service for handling file uploads from camera, gallery, or file picker
class FileUploadHandler {
  final ImagePicker _imagePicker = ImagePicker();
  final LocalFileStorageService _storageService = LocalFileStorageService();

  /// Take a photo using camera
  /// Note: Permission should be checked before calling this method
  /// Returns the file path - file will be saved later when user confirms
  Future<String?> takePhoto() async {
    try {
      // Pick image from camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        return null;
      }

      // Return file path - don't save yet
      return image.path;
    } catch (e) {
      throw Exception('Failed to take photo: ${e.toString()}');
    }
  }

  /// Pick image from gallery
  /// Note: Permission should be checked before calling this method
  /// Returns the file path - file will be saved later when user confirms
  Future<String?> pickImageFromGallery() async {
    try {
      // Pick image from gallery
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        return null;
      }

      // Return file path - don't save yet
      return image.path;
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  /// Pick file from device storage
  /// Returns the file path and name - file will be saved later when user confirms
  Future<Map<String, String>?> pickFile() async {
    try {
      // File picker handles its own permissions on modern systems
      final result = await file_picker.FilePicker.platform.pickFiles(
        type: file_picker.FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic',
          'pdf',
          'doc', 'docx',
        ],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      // Return file path and name - don't save yet
      return {
        'path': result.files.single.path!,
        'name': result.files.single.name,
      };
    } catch (e) {
      throw Exception('Failed to pick file: ${e.toString()}');
    }
  }

  /// Handle upload based on source type
  /// Returns file path (and name for files) - file will be saved later when user confirms
  Future<Map<String, String>?> handleUpload({
    required UploadSource source,
  }) async {
    switch (source) {
      case UploadSource.camera:
        final path = await takePhoto();
        if (path == null) return null;
        return {
          'path': path,
          'name': 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        };
      case UploadSource.gallery:
        final path = await pickImageFromGallery();
        if (path == null) return null;
        final fileName = path.split('/').last;
        return {
          'path': path,
          'name': fileName.isEmpty 
              ? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg' 
              : fileName,
        };
      case UploadSource.files:
        return await pickFile();
    }
  }
}

/// Upload source types
enum UploadSource {
  camera,
  gallery,
  files,
}