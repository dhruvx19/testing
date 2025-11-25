import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/model/doctor_details.dart';
import 'package:http/http.dart' as http;

class PatientService {
  /// Get patient details for the authenticated user
  /// @param authToken - Authentication token from AuthProvider
  /// @returns PatientDetailsResponse with patient data or error
  Future<PatientDetailsResponse> getPatientDetails({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getPatientDetails);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PatientDetailsResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return PatientDetailsResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to fetch patient details: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return PatientDetailsResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Add a dependent for the authenticated patient
  /// @param authToken - Authentication token from AuthProvider
  /// @param request - AddDependentRequest with dependent details
  /// @returns AddDependentResponse with created dependent data or error
  Future<AddDependentResponse> addDependent({
    required String authToken,
    required AddDependentRequest request,
  }) async {
    try {
      final url = Uri.parse(Endpoints.addDependent);
      print('🌐 Calling add-dependent API: $url');
      print('📤 Request body: ${jsonEncode(request.toJson())}');
      print('🔑 Auth token present: ${authToken.isNotEmpty} (length: ${authToken.length})');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      print('📤 Sending POST request with authentication headers...');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return AddDependentResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return AddDependentResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to add dependent: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return AddDependentResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get all dependents for the authenticated patient
  /// @param authToken - Authentication token from AuthProvider
  /// @returns GetDependentsResponse with list of dependents or error
  Future<GetDependentsResponse> getDependents({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getDependents);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return GetDependentsResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return GetDependentsResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to fetch dependents: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return GetDependentsResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get favourite doctors for the authenticated patient
  /// @param authToken - Authentication token from AuthProvider
  /// @returns FavouriteDoctorsResponse with list of favourite doctors or error
  Future<FavouriteDoctorsResponse> getFavouriteDoctors({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getFavouriteDoctors);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return FavouriteDoctorsResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return FavouriteDoctorsResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to fetch favourite doctors: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return FavouriteDoctorsResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }
}

