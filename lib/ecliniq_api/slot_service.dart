import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/slot.dart';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class SlotService {
  Future<SlotResponse> findSlotsByDoctorAndDate({
    required String doctorId,
    required String date,
    String? hospitalId,
    String? clinicId,
  }) async {
    try {
      final url = Uri.parse(Endpoints.getSlotsByDate);

      final requestBody = FindSlotsRequest(
        doctorId: doctorId,
        date: date,
        hospitalId: hospitalId,
        clinicId: clinicId,
      );

      final response = await EcliniqHttpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return SlotResponse.fromJson(responseData);
      } else {
        return SlotResponse(
          success: false,
          message: 'Failed to fetch slots: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return SlotResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<WeeklySlotResponse> findWeeklySlots({
    required String doctorId,
    String? hospitalId,
    String? clinicId,
  }) async {
    try {
      final url = Uri.parse(Endpoints.findWeeklySlots);

      final requestBody = FindWeeklySlotsRequest(
        doctorId: doctorId,
        hospitalId: hospitalId,
        clinicId: clinicId,
      );

      final response = await EcliniqHttpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return WeeklySlotResponse.fromJson(responseData);
      } else {
        return WeeklySlotResponse(
          success: false,
          message: 'Failed to fetch weekly slots: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return WeeklySlotResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<HoldTokenResponse> holdToken({
    required String slotId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.holdToken);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final requestBody = HoldTokenRequest(slotId: slotId);

      final response = await EcliniqHttpClient.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return HoldTokenResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return HoldTokenResponse(
          success: false,
          message: responseData['message'] ??
              'Failed to hold token: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return HoldTokenResponse(
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

