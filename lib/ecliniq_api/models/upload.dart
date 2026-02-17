
class UploadUrlRequest {
  final String contentType;

  UploadUrlRequest({required this.contentType});

  Map<String, dynamic> toJson() {
    return {
      'contentType': contentType, 
    };
  }
}

class UploadUrlResponse {
  final bool success;
  final String message;
  final UploadUrlData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  UploadUrlResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory UploadUrlResponse.fromJson(Map<String, dynamic> json) {
    return UploadUrlResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? UploadUrlData.fromJson(json['data']) : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class UploadUrlData {
  final String uploadUrl;
  final String key;

  UploadUrlData({
    required this.uploadUrl,
    required this.key,
  });

  factory UploadUrlData.fromJson(Map<String, dynamic> json) {
    return UploadUrlData(
      uploadUrl: json['uploadUrl'] ?? '',
      key: json['key'] ?? '',
    );
  }
}
