import 'dart:io';

/// Model representing a health file stored locally
class HealthFile {
  final String id;
  final String fileName;
  final String filePath; // Local file path
  final HealthFileType fileType; // Category type
  final DateTime createdAt;
  final int fileSize; // Size in bytes
  final String? mimeType;
  final String? recordFor; // Who the record is for
  final DateTime? fileDate; // Date of the file/document

  HealthFile({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
    required this.fileSize,
    this.mimeType,
    this.recordFor,
    this.fileDate,
  });

  /// Create from JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType.name,
      'createdAt': createdAt.toIso8601String(),
      'fileSize': fileSize,
      'mimeType': mimeType,
      'recordFor': recordFor,
      'fileDate': fileDate?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory HealthFile.fromJson(Map<String, dynamic> json) {
    return HealthFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileType: HealthFileType.values.firstWhere(
        (e) => e.name == json['fileType'],
        orElse: () => HealthFileType.others,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      fileSize: json['fileSize'] as int,
      mimeType: json['mimeType'] as String?,
      recordFor: json['recordFor'] as String?,
      fileDate: json['fileDate'] != null 
          ? DateTime.parse(json['fileDate'] as String) 
          : null,
    );
  }

  /// Create a copy with updated fields
  HealthFile copyWith({
    String? fileName,
    HealthFileType? fileType,
    String? recordFor,
    DateTime? fileDate,
  }) {
    return HealthFile(
      id: id,
      fileName: fileName ?? this.fileName,
      filePath: filePath,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt,
      fileSize: fileSize,
      mimeType: mimeType,
      recordFor: recordFor ?? this.recordFor,
      fileDate: fileDate ?? this.fileDate,
    );
  }

  /// Check if file still exists on disk
  bool exists() {
    try {
      final file = File(filePath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Get file extension
  String get extension {
    return fileName.split('.').last.toLowerCase();
  }

  /// Check if file is an image
  bool get isImage {
    return mimeType?.startsWith('image/') ?? false ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension);
  }
}

/// File categories/types
enum HealthFileType {
  labReports,
  scanImaging,
  prescriptions,
  invoices,
  vaccinations,
  others;

  String get displayName {
    switch (this) {
      case HealthFileType.labReports:
        return 'Lab Reports';
      case HealthFileType.scanImaging:
        return 'Scan / Imaging';
      case HealthFileType.prescriptions:
        return 'Prescriptions';
      case HealthFileType.invoices:
        return 'Invoices';
      case HealthFileType.vaccinations:
        return 'Vaccinations';
      case HealthFileType.others:
        return 'Others';
    }
  }
}

