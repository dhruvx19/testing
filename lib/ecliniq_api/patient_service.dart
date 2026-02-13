import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/patient.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:ecliniq/ecliniq_modules/screens/profile/my_doctors/model/doctor_details.dart';
import 'package:http/http.dart' as http;

class PatientService {
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

      final response = await http.get(url, headers: headers);

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

  Future<AddDependentResponse> addDependent({
    required String authToken,
    required AddDependentRequest request,
  }) async {
    try {
      final url = Uri.parse(Endpoints.addDependent);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );


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

      final response = await http.get(url, headers: headers);

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
          self: null,
          dependents: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return GetDependentsResponse(
        success: false,
        message: 'Network error: $e',
        self: null,
        dependents: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  
  
  
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

      final response = await http.get(url, headers: headers);

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

  
  
  
  
  Future<PatientDetailsResponse> updateNotificationPreferences({
    required String authToken,
    required Map<String, dynamic> prefs,
  }) async {
    try {
      final url = Uri.parse(Endpoints.updateNotificationPreferences);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(prefs),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData is Map<String, dynamic> &&
            responseData['success'] == true &&
            responseData['data'] is Map<String, dynamic> &&
            (responseData['data']['data'] is Map<String, dynamic> ||
                responseData['data'] is Map<String, dynamic>)) {
          final normalized =
              responseData['data']['data'] ?? responseData['data'];
          return PatientDetailsResponse(
            success: true,
            message: responseData['message'] ?? 'Updated successfully',
            data: PatientDetailsData.fromJson(normalized),
            errors: null,
            meta: null,
            timestamp:
                responseData['timestamp'] ?? DateTime.now().toIso8601String(),
          );
        }
        return PatientDetailsResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return PatientDetailsResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to update preferences: ${response.statusCode}',
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

  // Delete dependent
  Future<DeleteDependentResponse> deleteDependent({
    required String authToken,
    required String dependentId,
  }) async {
    try {
      final url = Uri.parse(Endpoints.deleteDependent(dependentId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return DeleteDependentResponse(
          success: true,
          message: responseData['message'] ?? 'Dependent deleted successfully',
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        final responseData = jsonDecode(response.body);
        return DeleteDependentResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to delete dependent: ${response.statusCode}',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return DeleteDependentResponse(
        success: false,
        message: 'Network error: $e',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  
  Future<Map<String, dynamic>> addFavouriteDoctor({
    required String authToken,
    required String doctorId,
  }) async {
    try {
      final url = Uri.parse(Endpoints.addFavouriteDoctor(doctorId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add favourite doctor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  
  Future<Map<String, dynamic>> removeFavouriteDoctor({
    required String authToken,
    required String doctorId,
  }) async {
    try {
      final url = Uri.parse(Endpoints.removeFavouriteDoctor(doctorId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to remove favourite doctor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
