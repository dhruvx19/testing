import 'dart:io';
import 'dart:typed_data';
import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/models/upload.dart';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
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
      
      final response = await EcliniqHttpClient.post(
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

  
  Future<bool> uploadImageToS3({
    required String uploadUrl,
    required File imageFile,
    required String contentType,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      final response = await EcliniqHttpClient.put(
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

  
  Future<bool> uploadImageBytesToS3({
    required String uploadUrl,
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    try {
      final response = await EcliniqHttpClient.put(
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

  
  Future<PatientDetailsResponse> savePatientDetails({
    required String authToken,
    required PatientDetailsRequest request,
  }) async {
    try {
      final url = Uri.parse(Endpoints.patientDetails); 

      final response = await EcliniqHttpClient.post(
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

  
  String getContentTypeFromFile(File file) {
    final mimeType = lookupMimeType(file.path);
    return mimeType ?? 'image/jpeg'; 
  }

  
  Future<String?> uploadImageComplete({
    required String authToken,
    required File imageFile,
  }) async {
    try {
      final contentType = getContentTypeFromFile(imageFile);
      
      final uploadUrlResponse = await generateUploadUrl(
        authToken: authToken,
        contentType: contentType,
      );

      if (!uploadUrlResponse.success || uploadUrlResponse.data == null) {
        throw Exception('Failed to get upload URL: ${uploadUrlResponse.message}');
      }

      final uploadSuccess = await uploadImageToS3(
        uploadUrl: uploadUrlResponse.data!.uploadUrl,
        imageFile: imageFile,
        contentType: contentType,
      );

      if (!uploadSuccess) {
        throw Exception('Failed to upload image to S3');
      }

      return uploadUrlResponse.data!.key;
    } catch (e) {
      throw Exception('Complete upload failed: $e');
    }
  }

  
  Future<String?> uploadImageBytesComplete({
    required String authToken,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final mimeType = lookupMimeType(fileName);
      final contentType = mimeType ?? 'image/jpeg';
      
      final uploadUrlResponse = await generateUploadUrl(
        authToken: authToken,
        contentType: contentType,
      );

      if (!uploadUrlResponse.success || uploadUrlResponse.data == null) {
        throw Exception('Failed to get upload URL: ${uploadUrlResponse.message}');
      }

      final uploadSuccess = await uploadImageBytesToS3(
        uploadUrl: uploadUrlResponse.data!.uploadUrl,
        imageBytes: imageBytes,
        contentType: contentType,
      );

      if (!uploadSuccess) {
        throw Exception('Failed to upload image to S3');
      }

      return uploadUrlResponse.data!.key;
    } catch (e) {
      throw Exception('Complete upload failed: $e');
    }
  }
}