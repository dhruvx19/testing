import 'dart:convert';
import 'dart:async';

import 'package:ecliniq/ecliniq_api/models/payment.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  Future<PaymentStatusResponse> checkPaymentStatus(
    String merchantTransactionId,
  ) async {
    try {
      final url = Uri.parse(Endpoints.paymentStatus(merchantTransactionId));

      final headers = <String, String>{'Content-Type': 'application/json'};

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PaymentStatusResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return PaymentStatusResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to check payment status: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return PaymentStatusResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get payment details for an appointment
  Future<PaymentDetailResponse> getPaymentDetails({
    required String appointmentId,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.paymentDetails(appointmentId));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PaymentDetailResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return PaymentDetailResponse(
          success: false,
          message:
              responseData['message'] ??
              'Failed to fetch payment details: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return PaymentDetailResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<PaymentStatusData?> pollPaymentUntilComplete(
    String merchantTransactionId, {
    int maxAttempts = 20,
    Duration interval = const Duration(seconds: 3),
    void Function(PaymentStatusData)? onStatusUpdate,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await checkPaymentStatus(merchantTransactionId);

        if (response.success && response.data != null) {
          final statusData = response.data!;

          // Notify caller of status update
          onStatusUpdate?.call(statusData);

          // Check if terminal state reached
          if (statusData.isTerminal) {
            return statusData;
          }
        }

        // Wait before next attempt
        if (attempt < maxAttempts - 1) {
          await Future.delayed(interval);
        }
      } catch (e) {
        // On error, wait and retry unless it's the last attempt
        if (attempt == maxAttempts - 1) {
          rethrow;
        }
        await Future.delayed(interval);
      }
    }

    // Timeout reached
    return null;
  }
}
