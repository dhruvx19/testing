import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../ecliniq_api/health_file_model.dart';

/// Service for managing local file storage for health files
class LocalFileStorageService {
  static const String _filesKey = 'health_files_list';
  static const String _filesDirectoryName = 'health_files';

  /// Get the directory where health files are stored
  Future<Directory> getFilesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filesDir = Directory(path.join(appDir.path, _filesDirectoryName));
    
    if (!await filesDir.exists()) {
      await filesDir.create(recursive: true);
    }
    
    return filesDir;
  }

  /// Save a file to local storage
  /// 
  /// [file] - The file to save (from image picker or file picker)
  /// [fileType] - The category of the file
  /// [fileName] - Optional custom file name, if not provided uses original name
  /// 
  /// Returns the saved HealthFile model
  Future<HealthFile> saveFile({
    required File file,
    required HealthFileType fileType,
    String? fileName,
  }) async {
    try {
      // Generate unique file ID
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get file info
      final originalName = fileName ?? path.basename(file.path);
      final fileExtension = path.extension(originalName);
      final mimeType = _getMimeType(fileExtension);
      
      // Create new file name with timestamp to avoid conflicts
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final newFileName = '${fileType.name}_$timestamp$fileExtension';
      
      // Get target directory
      final filesDir = await getFilesDirectory();
      final targetFile = File(path.join(filesDir.path, newFileName));
      
      // Copy file to app directory
      await file.copy(targetFile.path);
      
      // Get file size
      final fileSize = await targetFile.length();
      
      // Create HealthFile model
      final healthFile = HealthFile(
        id: fileId,
        fileName: originalName,
        filePath: targetFile.path,
        fileType: fileType,
        createdAt: DateTime.now(),
        fileSize: fileSize,
        mimeType: mimeType,
      );
      
      // Save metadata to SharedPreferences
      await _saveFileMetadata(healthFile);
      
      return healthFile;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  /// Save file from bytes (for camera captures)
  Future<HealthFile> saveFileFromBytes({
    required List<int> bytes,
    required HealthFileType fileType,
    required String fileName,
    String? mimeType,
  }) async {
    try {
      final fileId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get target directory
      final filesDir = await getFilesDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileExtension = path.extension(fileName);
      final newFileName = '${fileType.name}_$timestamp$fileExtension';
      final targetFile = File(path.join(filesDir.path, newFileName));
      
      // Write bytes to file
      await targetFile.writeAsBytes(bytes);
      
      // Create HealthFile model
      final healthFile = HealthFile(
        id: fileId,
        fileName: fileName,
        filePath: targetFile.path,
        fileType: fileType,
        createdAt: DateTime.now(),
        fileSize: bytes.length,
        mimeType: mimeType ?? 'image/jpeg',
      );
      
      // Save metadata
      await _saveFileMetadata(healthFile);
      
      return healthFile;
    } catch (e) {
      throw Exception('Failed to save file from bytes: $e');
    }
  }

  /// Get all saved files
  Future<List<HealthFile>> getAllFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getString(_filesKey);
      
      if (filesJson == null || filesJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> filesList = jsonDecode(filesJson);
      final files = filesList
          .map((json) => HealthFile.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Filter out files that no longer exist
      final existingFiles = <HealthFile>[];
      for (final file in files) {
        if (file.exists()) {
          existingFiles.add(file);
        } else {
          // File was deleted, remove from metadata
          await _removeFileMetadata(file.id);
        }
      }
      
      // Update metadata if files were removed
      if (existingFiles.length != files.length) {
        await _saveAllFilesMetadata(existingFiles);
      }
      
      return existingFiles;
    } catch (e) {
      return [];
    }
  }

  /// Get files by type
  Future<List<HealthFile>> getFilesByType(HealthFileType fileType) async {
    final allFiles = await getAllFiles();
    return allFiles.where((file) => file.fileType == fileType).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  /// Get file count by type
  Future<int> getFileCountByType(HealthFileType fileType) async {
    final files = await getFilesByType(fileType);
    return files.length;
  }

  /// Delete a file
  Future<bool> deleteFile(HealthFile healthFile) async {
    try {
      bool physicalFileDeleted = false;
      
      // Try to delete physical file first
      final file = File(healthFile.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
          physicalFileDeleted = true;
        } catch (e) {
          // Log error but continue to remove metadata
          print('Error deleting physical file: $e');
          // Try to delete anyway - file might be locked but we should still remove metadata
        }
      } else {
        // File doesn't exist, consider it deleted
        physicalFileDeleted = true;
      }
      
      // Always remove from metadata, even if physical file deletion failed
      // This ensures the file is removed from the UI
      await _removeFileMetadata(healthFile.id);
      
      return true; // Return true if metadata was removed successfully
    } catch (e) {
      print('Error in deleteFile: $e');
      return false;
    }
  }

  /// Get recently uploaded files (last 10)
  Future<List<HealthFile>> getRecentlyUploadedFiles({int limit = 10}) async {
    final allFiles = await getAllFiles();
    allFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return allFiles.take(limit).toList();
  }

  /// Save file metadata to SharedPreferences
  Future<void> saveFileMetadata(HealthFile healthFile) async {
    final allFiles = await getAllFiles();
    
    // Check if file with same ID exists and update it
    final existingIndex = allFiles.indexWhere((f) => f.id == healthFile.id);
    if (existingIndex != -1) {
      allFiles[existingIndex] = healthFile;
    } else {
      allFiles.add(healthFile);
    }
    
    await _saveAllFilesMetadata(allFiles);
  }
  
  // Keep private method for backward compatibility
  @Deprecated('Use saveFileMetadata instead')
  Future<void> _saveFileMetadata(HealthFile healthFile) async {
    return saveFileMetadata(healthFile);
  }

  /// Save all files metadata
  Future<void> _saveAllFilesMetadata(List<HealthFile> files) async {
    final prefs = await SharedPreferences.getInstance();
    final filesJson = jsonEncode(files.map((f) => f.toJson()).toList());
    await prefs.setString(_filesKey, filesJson);
  }

  /// Remove file metadata
  Future<void> _removeFileMetadata(String fileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getString(_filesKey);
      
      if (filesJson == null || filesJson.isEmpty) {
        return;
      }
      
      final List<dynamic> filesList = jsonDecode(filesJson);
      final files = filesList
          .map((json) => HealthFile.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Remove the file with matching ID
      files.removeWhere((f) => f.id == fileId);
      
      // Save updated list
      await _saveAllFilesMetadata(files);
    } catch (e) {
      print('Error removing file metadata: $e');
      rethrow;
    }
  }

  /// Get MIME type from file extension
  String? _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }

  /// Clear all files (for testing/reset)
  Future<void> clearAllFiles() async {
    try {
      final filesDir = await getFilesDirectory();
      if (await filesDir.exists()) {
        await filesDir.delete(recursive: true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filesKey);
    } catch (e) {
      // Ignore errors
    }
  }
}

