import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../ecliniq_api/health_file_model.dart';
import '../services/local_file_storage_service.dart';


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

  
  Future<void> loadFiles() async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      _allFiles = await _storageService.getAllFiles();
      // Sort from newest to oldest (most recent first) - using fileDate or createdAt
      _allFiles.sort((a, b) {
        final dateA = a.fileDate ?? a.createdAt;
        final dateB = b.fileDate ?? b.createdAt;
        return dateB.compareTo(dateA); // Newest first
      });
      _invalidateCache();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load files: $e';
      
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  
  
  List<HealthFile> getFilesByType(
    HealthFileType? fileType, {
    String? recordFor,
    List<String>? selectedNames,
  }) {
    Iterable<HealthFile> files = _allFiles;
    
    
    if (fileType != null) {
      files = files.where((file) => file.fileType == fileType);
    }
    
    
    if (recordFor != null && recordFor.isNotEmpty) {
      files = files.where((file) => file.recordFor == recordFor);
    }
    
    
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
      
      final dateA = a.fileDate ?? a.createdAt;
      final dateB = b.fileDate ?? b.createdAt;
      return dateB.compareTo(dateA);
    });
    
    return result;
  }

  
  List<String> getRecordForOptions(HealthFileType? fileType) {
    Iterable<HealthFile> files = _allFiles;
    
    
    if (fileType != null) {
      files = files.where((file) => file.fileType == fileType);
    }
    
    final recordForSet = files
        .where((file) => file.recordFor != null && file.recordFor!.isNotEmpty)
        .map((file) => file.recordFor!)
        .toSet();
    return recordForSet.toList()..sort();
  }

  
  int getFileCountByType(HealthFileType fileType) {
    _fileCountCache ??= {};
    return _fileCountCache!.putIfAbsent(
      fileType,
      () => _allFiles.where((file) => file.fileType == fileType).length,
    );
  }

  
  List<HealthFile> getRecentlyUploadedFiles({int limit = 10}) {
    if (_recentFilesCache != null && _recentFilesCache!.length >= limit) {
      return _recentFilesCache!.take(limit).toList();
    }
    
    _recentFilesCache = _allFiles.take(limit).toList();
    return _recentFilesCache!;
  }

  
  Future<bool> addFile(HealthFile file) async {
    try {
      
      await _storageService.saveFileMetadata(file);
      
      
      await loadFiles();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add file: $e';
      
      notifyListeners();
      return false;
    }
  }
  
  
  Future<bool> updateFile(HealthFile file) async {
    try {
      
      await _storageService.saveFileMetadata(file);
      
      
      await loadFiles();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update file: $e';
      
      notifyListeners();
      return false;
    }
  }

  
  Future<bool> deleteFile(HealthFile file) async {
    try {
      
      
      
      
      
      bool physicalFileDeleted = false;
      final physicalFile = File(file.filePath);
      
      try {
        final exists = await physicalFile.exists();
        
        
        if (exists) {
          await physicalFile.delete();
          physicalFileDeleted = true;
          
        } else {
          
        }
      } catch (fileError) {
        
        
        
      }
      
      
      final metadataDeleted = await _storageService.deleteFile(file);
      
      
      if (!metadataDeleted) {
        
        return false;
      }
      
      
      final initialCount = _allFiles.length;
      _allFiles.removeWhere((f) => f.id == file.id);
      final finalCount = _allFiles.length;
      
      
      
      _invalidateCache();
      
      
      
      notifyListeners();
      
      
      
      return true;
      
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to delete file: $e';
      
      
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  
  void _invalidateCache() {
    _fileCountCache = null;
    _recentFilesCache = null;
  }

  
  Future<void> refresh() async {
    
    await loadFiles();
  }
  
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}