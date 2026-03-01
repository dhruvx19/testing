import 'dart:convert';
import 'dart:io';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // Always update these fields, even if already initialized
    _merchantId = merchantId;
    _environment = isProduction ? 'PRODUCTION' : 'SANDBOX';
    _packageName = isProduction ? 'com.phonepe.app' : 'com.phonepe.simulator';

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
    String? intentUrl,
    String? iosIntentUrl,
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

      print('===== PHONEPE SERVICE LOG =====');
      print('Incoming intentUrl (Android): $intentUrl');
      print('Incoming iosIntentUrl (iOS): $iosIntentUrl');
      print('Target App Package: $targetUpiPackage');

      // PRIORITY 0: Direct UPI Intent (Deep Link)
      // Pick the platform-correct URL: iOS uses app-specific schemes, Android uses upi://
      final platformIntentUrl = Platform.isIOS ? (iosIntentUrl ?? intentUrl) : intentUrl;

      print('Platform is iOS: ${Platform.isIOS}');
      print('Resolved platformIntentUrl to use: $platformIntentUrl');
      print('===============================');

      if (platformIntentUrl != null && platformIntentUrl.isNotEmpty) {
        final uri = Uri.parse(platformIntentUrl);
        print('Checking if can launch: $uri');
        if (!await canLaunchUrl(uri)) {
          print('FAILED: Cannot launch URI: $uri');
          throw PhonePeException(
            'No UPI application found on this device to complete the transaction.\n\n'
            'Please install PhonePe, GPay, or any other UPI app.',
          );
        }

        print('Attempting to launch URI externally...');
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('Launch result: $launched');

        return PhonePePaymentResult(
          success: launched,
          status: launched ? 'OPENED' : 'FAILED',
          error: launched ? null : 'Failed to launch UPI application',
        );
      }

      print('No valid intent URL found, falling back to PhonePe SDK flow...');
      // PRIORITY 1: Use the backend-provided payload if available.
      // This is the safest way as it preserves the token's original signature.
      if (requestPayload != null && requestPayload.isNotEmpty) {
        requestToSend = requestPayload;
      }
      // PRIORITY 2: Manual build if backend didn't provide a payload blob
      else if (token != null && orderId != null && _merchantId != null) {
        final payload = <String, dynamic>{
          'orderId': orderId,
          'token': token,
          'merchantId': _merchantId,
          'paymentMode': (targetUpiPackage != null && targetUpiPackage.isNotEmpty)
              ? {
                  'type': 'UPI_INTENT',
                  if (Platform.isAndroid) 'targetAppPackageName': targetUpiPackage,
                  if (Platform.isIOS) 'targetApp': targetUpiPackage,
                }
              : {'type': 'PAY_PAGE'},
          if (Platform.isAndroid && targetUpiPackage != null)
            'targetAppPackageName': targetUpiPackage,
        };
        requestToSend = base64.encode(utf8.encode(jsonEncode(payload)));
      } else {
        throw PhonePeException('Insufficient data (missing payload or merchant context)');
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
      status = (result['status'] ?? result['STATUS'] ?? result['resultCode'] ?? 'INCOMPLETE')
          .toString()
          .toUpperCase();
      error = (result['error'] ?? result['message'] ?? result['errorMessage'] ?? result['ERROR'])?.toString();
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
