import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../ecliniq_api/health_file_model.dart';
import '../services/local_file_storage_service.dart';

/// Provider for managing health files state
class HealthFilesProvider extends ChangeNotifier {
  final LocalFileStorageService _storageService = LocalFileStorageService();
  
  List<HealthFile> _allFiles = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<HealthFileType, int>? _fileCountCache;
  List<HealthFile>? _recentFilesCache;

  List<HealthFile> get allFiles => _allFiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<HealthFile> _searchResults = [];
  List<HealthFile> get searchResults => _searchResults;

  void searchFiles(String query) {
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      final lowercaseQuery = query.toLowerCase();
      _searchResults = _allFiles.where((file) {
        return file.fileName.toLowerCase().contains(lowercaseQuery) ||
            (file.recordFor != null && 
             file.recordFor!.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }
    notifyListeners();
  }

  /// Initialize and load all files
  Future<void> loadFiles() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      _allFiles = await _storageService.getAllFiles();
      _allFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _invalidateCache();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load files: $e';
      debugPrint('❌ Error loading files: $e');
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get files by type (null means all types)
  /// Can filter by single recordFor (String) or multiple names (List<String>)
  List<HealthFile> getFilesByType(
    HealthFileType? fileType, {
    String? recordFor,
    List<String>? selectedNames,
  }) {
    Iterable<HealthFile> files = _allFiles;
    
    // Filter by file type if provided
    if (fileType != null) {
      files = files.where((file) => file.fileType == fileType);
    }
    
    // Filter by recordFor (single) if provided (for backward compatibility)
    if (recordFor != null && recordFor.isNotEmpty) {
      files = files.where((file) => file.recordFor == recordFor);
    }
    
    // Filter by multiple selected names if provided
    if (selectedNames != null && selectedNames.isNotEmpty) {
      files = files.where((file) {
        if (file.recordFor == null || file.recordFor!.isEmpty) {
          return false;
        }
        return selectedNames.contains(file.recordFor);
      });
    }
    
    final result = files.toList();
    result.sort((a, b) {
      // Sort by fileDate if available, otherwise by createdAt
      final dateA = a.fileDate ?? a.createdAt;
      final dateB = b.fileDate ?? b.createdAt;
      return dateB.compareTo(dateA);
    });
    
    return result;
  }

  /// Get all unique recordFor values for a given file type (null means all types)
  List<String> getRecordForOptions(HealthFileType? fileType) {
    Iterable<HealthFile> files = _allFiles;
    
    // Filter by file type if provided
    if (fileType != null) {
      files = files.where((file) => file.fileType == fileType);
    }
    
    final recordForSet = files
        .where((file) => file.recordFor != null && file.recordFor!.isNotEmpty)
        .map((file) => file.recordFor!)
        .toSet();
    return recordForSet.toList()..sort();
  }

  /// Get file count by type (cached for performance)
  int getFileCountByType(HealthFileType fileType) {
    _fileCountCache ??= {};
    return _fileCountCache!.putIfAbsent(
      fileType,
      () => _allFiles.where((file) => file.fileType == fileType).length,
    );
  }

  /// Get recently uploaded files (cached for performance)
  List<HealthFile> getRecentlyUploadedFiles({int limit = 10}) {
    if (_recentFilesCache != null && _recentFilesCache!.length >= limit) {
      return _recentFilesCache!.take(limit).toList();
    }
    // Files are already sorted by createdAt desc, so just take the first N
    _recentFilesCache = _allFiles.take(limit).toList();
    return _recentFilesCache!;
  }

  /// Add a new file
  Future<bool> addFile(HealthFile file) async {
    try {
      // Save to storage
      await _storageService.saveFileMetadata(file);
      
      // Reload to get fresh data
      await loadFiles();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add file: $e';
      debugPrint('❌ Error adding file: $e');
      notifyListeners();
      return false;
    }
  }
  
  /// Update an existing file
  Future<bool> updateFile(HealthFile file) async {
    try {
      // Save updated metadata to storage
      await _storageService.saveFileMetadata(file);
      
      // Reload to get fresh data
      await loadFiles();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update file: $e';
      debugPrint('❌ Error updating file: $e');
      notifyListeners();
      return false;
    }
  }

  /// Delete a file - removes both physical file and metadata
  Future<bool> deleteFile(HealthFile file) async {
    try {
      debugPrint('🗑️ Attempting to delete file: ${file.fileName}');
      debugPrint('📁 File path: ${file.filePath}');
      debugPrint('🆔 File ID: ${file.id}');
      
      // Step 1: Try to delete physical file
      bool physicalFileDeleted = false;
      final physicalFile = File(file.filePath);
      
      try {
        final exists = await physicalFile.exists();
        debugPrint('📋 Physical file exists: $exists');
        
        if (exists) {
          await physicalFile.delete();
          physicalFileDeleted = true;
          debugPrint('✅ Physical file deleted successfully');
        } else {
          debugPrint('⚠️ Physical file not found, will remove from database');
        }
      } catch (fileError) {
        debugPrint('⚠️ Error deleting physical file: $fileError');
        debugPrint('   Continuing with metadata deletion...');
        // Continue anyway - we still want to remove from database
      }
      
      // Step 2: Delete metadata from storage service
      final metadataDeleted = await _storageService.deleteFile(file);
      debugPrint('📝 Metadata deletion result: $metadataDeleted');
      
      if (!metadataDeleted) {
        debugPrint('❌ Failed to delete metadata from storage service');
        return false;
      }
      
      // Step 3: Remove from local list
      final initialCount = _allFiles.length;
      _allFiles.removeWhere((f) => f.id == file.id);
      final finalCount = _allFiles.length;
      debugPrint('📊 Files before: $initialCount, after: $finalCount');
      
      // Step 4: Invalidate cache
      _invalidateCache();
      debugPrint('🔄 Cache invalidated');
      
      // Step 5: Notify listeners to update UI
      notifyListeners();
      debugPrint('📢 Listeners notified');
      
      debugPrint('✅ File deletion completed successfully');
      return true;
      
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to delete file: $e';
      debugPrint('❌ Error deleting file: $e');
      debugPrint('Stack trace: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Invalidate cache when files change
  void _invalidateCache() {
    _fileCountCache = null;
    _recentFilesCache = null;
  }

  /// Refresh files from storage
  Future<void> refresh() async {
    debugPrint('🔄 Refreshing files from storage...');
    await loadFiles();
  }
  
  /// Clear all error messages
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}