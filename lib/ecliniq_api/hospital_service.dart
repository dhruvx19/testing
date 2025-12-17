// lib/ecliniq_api/hospital_service.dart

import 'dart:convert';
import 'package:ecliniq/ecliniq_api/models/hospital.dart';
import 'package:ecliniq/ecliniq_api/models/hospital_doctor_model.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class HospitalService {
  // Private auth token storage (optional - can use dependency injection instead)
  String? _authToken;

  /// Set authentication token for the service
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get stored auth token
  String? get authToken => _authToken;


  Future<TopHospitalsResponse> getTopHospitals({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(Endpoints.topHospitals);

      final requestBody = TopHospitalsRequest(
        latitude: latitude,
        longitude: longitude,
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TopHospitalsResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        return TopHospitalsResponse(
          success: false,
          message: 'Invalid location coordinates',
          data: [],
          errors: 'Bad request',
          meta: {'statusCode': 400},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode >= 500) {
        return TopHospitalsResponse(
          success: false,
          message: 'Server error: Please try again later',
          data: [],
          errors: 'Internal server error',
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        return TopHospitalsResponse(
          success: false,
          message: 'Failed to fetch hospitals: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on http.ClientException catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on FormatException catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Invalid response format from server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<TopHospitalsResponse> getAllHospitals({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getAllHospitals);

      final requestBody = {
        "latitude": latitude,
        "longitude": longitude,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TopHospitalsResponse.fromJson(responseData);
      } else {
        return TopHospitalsResponse(
          success: false,
          message: 'Failed to fetch hospitals: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  
  Future<HospitalDetailsResponse> getHospitalDetails({
    required String hospitalId,
  }) async {
    // Validate hospital ID
    if (hospitalId.isEmpty) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Hospital ID is required',
        data: null,
        errors: 'Missing hospital ID',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    try {
      final url = Uri.parse(Endpoints.hospitalDetails(hospitalId));

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return HospitalDetailsResponse.fromJson(responseData);
      } else if (response.statusCode == 404) {
        return HospitalDetailsResponse(
          success: false,
          message: 'Hospital not found',
          data: null,
          errors: 'Hospital ID does not exist',
          meta: {'statusCode': 404},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode >= 500) {
        return HospitalDetailsResponse(
          success: false,
          message: 'Server error: Please try again later',
          data: null,
          errors: 'Internal server error',
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        return HospitalDetailsResponse(
          success: false,
          message: 'Failed to fetch hospital details: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on http.ClientException catch (e) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on FormatException catch (e) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Invalid response format from server',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return HospitalDetailsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<TopDoctorsResponse> getHospitalDoctors({
    required String hospitalId,
    required String authToken,
  }) async {
    // Validate hospital ID
    if (hospitalId.isEmpty) {
      return TopDoctorsResponse(
        success: false,
        message: 'Hospital ID is required',
        data: [],
        errors: 'Missing hospital ID',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    // Validate auth token
    if (authToken.isEmpty) {
      return TopDoctorsResponse(
        success: false,
        message: 'Authentication token is required',
        data: [],
        errors: 'Missing authentication token',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    try {
      final url = Uri.parse(Endpoints.getAllDoctorHospital(hospitalId));

      // Prepare headers with authentication
      // Using both Authorization Bearer and x-access-token for compatibility
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      // Make the API request
      final response = await http.get(url, headers: headers);

      // Handle different response status codes
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TopDoctorsResponse.fromJson(responseData);
      } else if (response.statusCode == 401) {
        return TopDoctorsResponse(
          success: false,
          message: 'Unauthorized: Invalid or expired authentication token',
          data: [],
          errors: 'Authentication failed',
          meta: {'statusCode': 401},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode == 403) {
        return TopDoctorsResponse(
          success: false,
          message: 'Forbidden: You do not have access to this resource',
          data: [],
          errors: 'Access denied',
          meta: {'statusCode': 403},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode == 404) {
        return TopDoctorsResponse(
          success: false,
          message: 'Hospital not found',
          data: [],
          errors: 'Hospital ID does not exist',
          meta: {'statusCode': 404},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else if (response.statusCode >= 500) {
        return TopDoctorsResponse(
          success: false,
          message: 'Server error: Please try again later',
          data: [],
          errors: 'Internal server error',
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        return TopDoctorsResponse(
          success: false,
          message: 'Failed to fetch doctors: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: {'statusCode': response.statusCode},
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } on http.ClientException catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Network error: Unable to connect to server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on FormatException catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Invalid response format from server',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Unexpected error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }


  Future<TopHospitalsResponse> searchHospitals({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    if (query.isEmpty) {
      return TopHospitalsResponse(
        success: false,
        message: 'Search query is required',
        data: [],
        errors: 'Empty search query',
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    try {
      // Implement search endpoint when available
      // For now, fetch all hospitals and filter locally
      final response = await getTopHospitals(
        latitude:  28.6139,
        longitude:  77.209,
      );

      if (response.success) {
        final filteredHospitals = response.data.where((hospital) {
          return hospital.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

        return TopHospitalsResponse(
          success: true,
          message: 'Hospitals filtered successfully',
          data: filteredHospitals,
          errors: null,
          meta: {'searchQuery': query, 'resultsCount': filteredHospitals.length},
          timestamp: DateTime.now().toIso8601String(),
        );
      }

      return response;
    } catch (e) {
      return TopHospitalsResponse(
        success: false,
        message: 'Search failed: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }


  Future<TopDoctorsResponse> getDoctorsBySpecialization({
    required String hospitalId,
    required String specialization,
    required String authToken,
  }) async {
    try {
      final response = await getHospitalDoctors(
        hospitalId: hospitalId,
        authToken: authToken,
      );

      if (response.success) {
        final filteredDoctors = response.data.where((doctor) {
          return doctor.specializations.any(
            (spec) => spec.toLowerCase().contains(specialization.toLowerCase()),
          );
        }).toList();

        return TopDoctorsResponse(
          success: true,
          message: 'Doctors filtered by specialization',
          data: filteredDoctors,
          errors: null,
          meta: {
            'specialization': specialization,
            'resultsCount': filteredDoctors.length,
          },
          timestamp: DateTime.now().toIso8601String(),
        );
      }

      return response;
    } catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Failed to filter doctors: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }


  Future<TopDoctorsResponse> getAvailableDoctors({
    required String hospitalId,
    required String authToken,
  }) async {
    try {
      final response = await getHospitalDoctors(
        hospitalId: hospitalId,
        authToken: authToken,
      );

      if (response.success) {
        final availableDoctors = response.data.where((doctor) {
          return doctor.availability != null &&
              (doctor.availability!.availableTokens ?? 0) > 0;
        }).toList();

        return TopDoctorsResponse(
          success: true,
          message: 'Available doctors fetched successfully',
          data: availableDoctors,
          errors: null,
          meta: {'availableCount': availableDoctors.length},
          timestamp: DateTime.now().toIso8601String(),
        );
      }

      return response;
    } catch (e) {
      return TopDoctorsResponse(
        success: false,
        message: 'Failed to fetch available doctors: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }
}