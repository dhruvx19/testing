import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/appointment.dart';
import 'package:ecliniq/ecliniq_api/src/api_client.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class AppointmentService {
  Future<BookAppointmentResponse> bookAppointment({
    required BookAppointmentRequest request,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.bookAppointment);

      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      final response = await EcliniqHttpClient.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return BookAppointmentResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return BookAppointmentResponse(
          success: false,
          message:
              responseData['message']?.toString() ??
              'Failed to book appointment: ${response.statusCode}',
          data: null,
          errors: responseData['errors'] ?? response.body,
          meta: responseData['meta'],
          timestamp: responseData['timestamp'] ?? DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return BookAppointmentResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<AppointmentListResponse> getScheduledAppointments({
    required String authToken,
    String? type,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.scheduledAppointments);
      final url = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          if (type != null) 'type': type,
        },
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AppointmentListResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return AppointmentListResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to fetch scheduled appointments: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return AppointmentListResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<AppointmentListResponse> getAppointmentHistory({
    required String authToken,
    String? type,
  }) async {
    try {
      final uri = Uri.parse(Endpoints.appointmentHistory);
      final url = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          if (type != null) 'type': type,
        },
      );

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AppointmentListResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return AppointmentListResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to fetch appointment history: ${response.statusCode}',
          data: [],
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return AppointmentListResponse(
        success: false,
        message: 'Network error: $e',
        data: [],
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<AppointmentDetailResponse> getAppointmentDetail({
    required String appointmentId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.appointmentDetail(appointmentId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return AppointmentDetailResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return AppointmentDetailResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to fetch appointment details: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return AppointmentDetailResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<CancelAppointmentResponse> cancelAppointment({
    required String appointmentId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.cancelAppointment(appointmentId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      
      final body = jsonEncode({
        'appointmentId': appointmentId,
      });

      final response = await EcliniqHttpClient.post(url, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return CancelAppointmentResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return CancelAppointmentResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to cancel appointment: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return CancelAppointmentResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<RescheduleAppointmentResponse> rescheduleAppointment({
    required RescheduleAppointmentRequest request,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.rescheduleAppointment);

      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      final response = await EcliniqHttpClient.put(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return RescheduleAppointmentResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return RescheduleAppointmentResponse(
          success: false,
          message:
              responseData['message']?.toString() ??
              'Failed to reschedule appointment: ${response.statusCode}',
          data: null,
          errors: responseData['errors'] ?? response.body,
          meta: responseData['meta'],
          timestamp: responseData['timestamp'] ?? DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return RescheduleAppointmentResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<VerifyAppointmentResponse> verifyAppointment({
    required VerifyAppointmentRequest request,
    String? authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.verifyAppointment);

      final headers = <String, String>{'Content-Type': 'application/json'};

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
        headers['x-access-token'] = authToken;
      }

      final response = await EcliniqHttpClient.post(
        url,
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return VerifyAppointmentResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return VerifyAppointmentResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to verify appointment: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return VerifyAppointmentResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<Map<String, dynamic>> rateAppointment({
    required String appointmentId,
    required int rating,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.rateAppointment(appointmentId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final body = jsonEncode({
        'rating': rating,
      });

      final response = await EcliniqHttpClient.put(url, headers: headers, body: body);

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message']?.toString() ?? 'Appointment rated successfully',
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message']?.toString() ?? 'Failed to rate appointment: ${response.statusCode}',
        'data': null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> getBannersForHome({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.bannersForHome);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message']?.toString() ?? 'Banners fetched successfully',
          'data': responseData['data'],
          'errors': responseData['errors'],
          'meta': responseData['meta'],
          'timestamp': responseData['timestamp'] ?? DateTime.now().toIso8601String(),
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message']?.toString() ?? 'Failed to fetch banners: ${response.statusCode}',
          'data': null,
          'errors': response.body,
          'meta': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'data': null,
        'errors': e.toString(),
        'meta': null,
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}

extension AppointmentEtaExtension on AppointmentService {
  Future<Map<String, dynamic>?> getEtaStatus({
    required String appointmentId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.etaStatus(appointmentId));
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await EcliniqHttpClient.get(url, headers: headers);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        
        final msg = body['message'] as Map<String, dynamic>?;
        if (msg == null) return null;
        return {
          'appointmentId': msg['appointmentId'],
          'appointmentStatus': msg['appointmentStatus'],
          'tokenNo': msg['tokenNo'],
          'slotStatus': msg['slotStatus'],
          'timestamp': body['timestamp'], 
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
