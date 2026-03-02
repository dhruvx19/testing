import 'dart:convert';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

class PhonePeService {
  static final PhonePeService _instance = PhonePeService._internal();
  factory PhonePeService() => _instance;
  PhonePeService._internal();

  bool _isInitialized = false;
  String _environment = 'PRODUCTION';
  String _packageName = 'com.phonepe.simulator';
  String? _merchantId;

  Future<bool> initialize({
    required bool isProduction,
    required String merchantId,
    required String flowId,
    bool enableLogs = false,
  }) async {
    if (_isInitialized) return true;

    if (merchantId.isEmpty) {
      throw PhonePeException('merchantId cannot be empty');
    }
    if (flowId.isEmpty) {
      throw PhonePeException(
        'flowId cannot be empty. Pass a unique user/session identifier.',
      );
    }

    try {
      _environment = 'PRODUCTION';
      _packageName = isProduction ? 'com.phonepe.app' : 'com.phonepe.simulator';
      _merchantId = merchantId;

      final isInitialized = await PhonePePaymentSdk.init(
        _environment,
        merchantId,
        flowId,
        enableLogs,
      );

      _isInitialized = isInitialized ?? false;
      return _isInitialized;
    } catch (e) {
      throw PhonePeException('Failed to initialize PhonePe SDK: $e');
    }
  }

  Future<PhonePePaymentResult> startPayment({
    String? requestPayload,
    String? token,
    String? orderId,
    required String appSchema,
    String? targetUpiPackage,
  }) async {
    if (!_isInitialized) {
      throw PhonePeException(
        'PhonePe SDK not initialized. Call initialize() first.',
      );
    }

    try {
      String requestToSend;

      if (requestPayload != null && requestPayload.isNotEmpty) {
        try {
          final decodedBytes = base64Decode(requestPayload);
          final jsonString = utf8.decode(decodedBytes);

          // The backend already encodes the correct paymentMode into the payload.
          // We only override here as a safety net if somehow the backend sent PAY_PAGE
          // but the frontend knows a specific UPI app was chosen.
          final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
          final isRealUpiPackage = targetUpiPackage != null &&
              targetUpiPackage.isNotEmpty &&
              targetUpiPackage != 'standard_pay_page' &&
              targetUpiPackage != 'WALLET';

          if (isRealUpiPackage) {
            // Only override if the backend payload doesn't already have UPI_INTENT
            final existingMode = decodedMap['paymentMode'];
            if (existingMode is! Map ||
                (existingMode as Map)['type'] != 'UPI_INTENT') {
              decodedMap['paymentMode'] = {
                'type': 'UPI_INTENT',
                'targetAppPackageName': targetUpiPackage,
              };
            }
          }

          requestToSend = jsonEncode(decodedMap);
        } catch (e) {
          throw PhonePeException(
            'Failed to decode requestPayload from base64: $e',
          );
        }
      } else {
        if (_merchantId == null || _merchantId!.isEmpty) {
          throw PhonePeException(
            'Merchant ID not available. Please initialize SDK with merchantId first.',
          );
        }

        if (token == null || token.isEmpty) {
          throw PhonePeException('Payment token cannot be empty');
        }
        if (orderId == null || orderId.isEmpty) {
          throw PhonePeException('Order ID cannot be empty');
        }

        final payload = <String, dynamic>{
          'orderId': orderId,
          'merchantId': _merchantId,
          'token': token,
          'paymentMode': (targetUpiPackage != null && targetUpiPackage.isNotEmpty)
              ? {
                  'type': 'UPI_INTENT',
                  'targetAppPackageName': targetUpiPackage,
                }
              : {
                  'type': 'PAY_PAGE',
                },
        };

        final jsonString = jsonEncode(payload);

        requestToSend = jsonString;
      }

      final response = await PhonePePaymentSdk.startTransaction(
        requestToSend,
        appSchema,
      );

      return PhonePePaymentResult.fromSdkResult(response);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('signature') ||
          errorString.contains('package') ||
          errorString.contains('signature_mismatched')) {
        if (_environment == 'SANDBOX') {
          throw PhonePeException(
            'PhonePe Simulator not found or signature mismatch.\n\n'
            'Please ensure:\n'
            '1. PhonePe Simulator app is installed from Play Store\n'
            '2. Package name: com.phonepe.simulator\n'
            '3. The simulator app is up to date\n\n'
            'If the real PhonePe app is installed, you may need to uninstall it temporarily for sandbox testing.\n\n'
            'Error details: $e',
          );
        } else {
          throw PhonePeException(
            'PhonePe app signature mismatch. Please ensure PhonePe app is installed and up to date. Error: $e',
          );
        }
      }

      if (errorString.contains('api mapping') ||
          errorString.contains('config')) {
        throw PhonePeException(
          'PhonePe SDK configuration error. Please verify:\n'
          '1. Merchant ID is correct\n'
          '2. Environment is set correctly\n'
          '3. PhonePe app is installed\n\n'
          'Error: $e',
        );
      }

      e.toString().toLowerCase();
      if (errorString.contains('cannot be converted to jsonobject') ||
          errorString.contains('jsonobject')) {
        throw PhonePeException(
          'PhonePe SDK Error: Invalid request format.\n\n'
          'This appears to be a bug in the PhonePe Flutter plugin where the Android SDK '
          'is trying to parse the base64 string as JSON without decoding it first.\n\n'
          'Please ensure:\n'
          '1. You are using the latest version of phonepe_payment_sdk\n'
          '2. PhonePe Simulator is installed and up to date\n'
          '3. The backend is sending a properly base64-encoded JSON payload\n\n'
          'Error details: $e',
        );
      }

      throw PhonePeException('Failed to start payment: $e');
    }
  }

  String? get environment => _environment;

  String? get packageName => _packageName;

  bool get isInitialized => _isInitialized;
}

class PhonePePaymentResult {
  final bool success;
  final String status;
  final String? error;
  final dynamic data;

  PhonePePaymentResult({
    required this.success,
    required this.status,
    this.error,
    this.data,
  });

  factory PhonePePaymentResult.fromSdkResult(dynamic result) {
    if (result == null) {
      return PhonePePaymentResult(
        success: false,
        status: 'INCOMPLETE',
        error: 'Payment was cancelled or failed',
      );
    }

    String status = 'INCOMPLETE';
    String? error;

    if (result is String) {
      status = result.toUpperCase();
    } else if (result is Map) {
      status = (result['status'] ?? result['STATUS'] ?? 'INCOMPLETE')
          .toString()
          .toUpperCase();
      error = result['error']?.toString();
    } else {
      status = result.toString().toUpperCase();
    }

    final success = status.contains('SUCCESS') || status == 'COMPLETED';

    return PhonePePaymentResult(
      success: success,
      status: status,
      error: error,
      data: result,
    );
  }
}

class PhonePeException implements Exception {
  final String message;

  PhonePeException(this.message);

  @override
  String toString() => 'PhonePeException: $message';
}