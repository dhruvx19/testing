import 'dart:convert';
import 'package:ecliniq/ecliniq_api/models/doctor.dart';
import 'package:ecliniq/ecliniq_api/models/doctor_booking_response.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DoctorService {
  /// Get top doctors based on location
  Future<TopDoctorsResponse> getTopDoctors({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(Endpoints.topDoctors);

      final requestBody = TopDoctorsRequest(
        latitude: latitude,
        longitude: longitude,
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return TopDoctorsResponse.fromJson(responseData);
      } else {
        return TopDoctorsResponse(
          success: false,
          message: 'Failed to fetch doctors: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error in getTopDoctors: $e');
      return TopDoctorsResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get filtered doctors
  Future<FilterDoctorsResponse> getFilteredDoctors(
      FilterDoctorsRequest request) async {
    try {
      final url = Uri.parse(Endpoints.filteredDoctors);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return FilterDoctorsResponse.fromJson(responseData);
      } else {
        return FilterDoctorsResponse(
          success: false,
          message: 'Failed to fetch doctors: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error in getFilteredDoctors: $e');
      return FilterDoctorsResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get doctor details by ID for patient
  Future<DoctorDetailsResponse> getDoctorDetailsById({
    required String doctorId,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.doctorDetailsById(doctorId));

      final headers = <String, String>{'Content-Type': 'application/json'};

      // Include auth token if provided
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return DoctorDetailsResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return DoctorDetailsResponse(
          success: false,
          message: responseData['message'] ??
              'Failed to fetch doctor details: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error in getDoctorDetailsById: $e');
      return DoctorDetailsResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get doctor details for booking
  Future<DoctorBookingDetailsResponse> getDoctorDetailsForBooking({
    required String doctorId,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.doctorDetailsForBooking(doctorId));

      final headers = <String, String>{'Content-Type': 'application/json'};

      // Include auth token if provided
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return DoctorBookingDetailsResponse.fromJson(responseData);
      } else {
        return DoctorBookingDetailsResponse(
          success: false,
          message: 'Failed to fetch doctor details: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('Error in getDoctorDetailsForBooking: $e');
      return DoctorBookingDetailsResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }
}
