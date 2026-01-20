// lib/services/upload_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:ecliniq/ecliniq_api/models/upload.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';

class UploadService {
  
  Future<UploadUrlResponse> generateUploadUrl({
    required String authToken,
    required String contentType,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getUrl);
      
      final request = UploadUrlRequest(contentType: contentType);
      
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(request.toJson()),
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return UploadUrlResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to generate upload URL: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating upload URL: $e');
    }
  }

  /// Upload image to S3 using presigned URL
  Future<bool> uploadImageToS3({
    required String uploadUrl,
    required File imageFile,
    required String contentType,
  }) async {
    try {
      
      final bytes = await imageFile.readAsBytes();
      
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: bytes,
      );

      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Error uploading image to S3: $e');
    }
  }

  /// Upload image from bytes to S3 using presigned URL
  Future<bool> uploadImageBytesToS3({
    required String uploadUrl,
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: imageBytes,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error uploading image bytes to S3: $e');
    }
  }

  /// Save patient details with profile photo
  Future<PatientDetailsResponse> savePatientDetails({
    required String authToken,
    required PatientDetailsRequest request,
  }) async {
    try {
      final url = Uri.parse(Endpoints.patientDetails); // Replace with your actual endpoint

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return PatientDetailsResponse.fromJson(responseData);
      } else {
        throw Exception('Failed to save patient details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving patient details: $e');
    }
  }

  /// Get content type from file
  String getContentTypeFromFile(File file) {
    final mimeType = lookupMimeType(file.path);
    return mimeType ?? 'image/jpeg'; // Default to jpeg if can't determine
  }

  /// Complete image upload flow
  Future<String?> uploadImageComplete({
    required String authToken,
    required File imageFile,
  }) async {
    try {
      
      // Step 1: Get content type
      final contentType = getContentTypeFromFile(imageFile);
      
      // Step 2: Generate upload URL
      final uploadUrlResponse = await generateUploadUrl(
        authToken: authToken,
        contentType: contentType,
      );

      if (!uploadUrlResponse.success || uploadUrlResponse.data == null) {
        throw Exception('Failed to get upload URL: ${uploadUrlResponse.message}');
      }


      // Step 3: Upload to S3
      final uploadSuccess = await uploadImageToS3(
        uploadUrl: uploadUrlResponse.data!.uploadUrl,
        imageFile: imageFile,
        contentType: contentType,
      );

      if (!uploadSuccess) {
        throw Exception('Failed to upload image to S3');
      }

      
      // Return the key for use in patient details
      return uploadUrlResponse.data!.key;
    } catch (e) {
      throw Exception('Complete upload failed: $e');
    }
  }

  /// Complete image upload flow from bytes
  Future<String?> uploadImageBytesComplete({
    required String authToken,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      // Step 1: Get content type from filename
      final mimeType = lookupMimeType(fileName);
      final contentType = mimeType ?? 'image/jpeg';
      
      // Step 2: Generate upload URL
      final uploadUrlResponse = await generateUploadUrl(
        authToken: authToken,
        contentType: contentType,
      );

      if (!uploadUrlResponse.success || uploadUrlResponse.data == null) {
        throw Exception('Failed to get upload URL: ${uploadUrlResponse.message}');
      }

      // Step 3: Upload to S3
      final uploadSuccess = await uploadImageBytesToS3(
        uploadUrl: uploadUrlResponse.data!.uploadUrl,
        imageBytes: imageBytes,
        contentType: contentType,
      );

      if (!uploadSuccess) {
        throw Exception('Failed to upload image to S3');
      }

      // Return the key for use in patient details
      return uploadUrlResponse.data!.key;
    } catch (e) {
      throw Exception('Complete upload failed: $e');
    }
  }
}