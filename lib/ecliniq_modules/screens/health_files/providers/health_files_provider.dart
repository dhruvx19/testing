import 'package:flutter/foundation.dart';
import '../models/health_file_model.dart';
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
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get files by type (null means all types)
  List<HealthFile> getFilesByType(HealthFileType? fileType, {String? recordFor}) {
    Iterable<HealthFile> files = _allFiles;
    
    // Filter by file type if provided
    if (fileType != null) {
      files = files.where((file) => file.fileType == fileType);
    }
    
    // Filter by recordFor if provided
    if (recordFor != null && recordFor.isNotEmpty) {
      files = files.where((file) => file.recordFor == recordFor);
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
      notifyListeners();
      return false;
    }
  }

  /// Delete a file
  Future<bool> deleteFile(HealthFile file) async {
    try {
      final success = await _storageService.deleteFile(file);
      if (success) {
        _allFiles.removeWhere((f) => f.id == file.id);
        _invalidateCache();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to delete file: $e';
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
    await loadFiles();
  }
}

