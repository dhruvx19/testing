import 'dart:convert';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

/// Service wrapper for PhonePe Payment SDK
class PhonePeService {
  static final PhonePeService _instance = PhonePeService._internal();
  factory PhonePeService() => _instance;
  PhonePeService._internal();

  bool _isInitialized = false;
  String _environment = 'SANDBOX';
  String _packageName = 'com.phonepe.simulator';
  String? _merchantId; // Store merchantId for constructing payment payload

  /// Initialize PhonePe SDK
  /// [isProduction] - Set true for production, false for sandbox
  /// [merchantId] - Your PhonePe merchant ID
  /// [flowId] - Unique user ID or session identifier
  /// [enableLogs] - Enable SDK logging (recommended false for production)
  Future<bool> initialize({
    required bool isProduction,
    required String merchantId,
    required String flowId,
    bool enableLogs = false,
  }) async {
    if (_isInitialized) return true;

    // Validate required parameters
    if (merchantId.isEmpty) {
      throw PhonePeException('merchantId cannot be empty');
    }
    if (flowId.isEmpty) {
      throw PhonePeException('flowId cannot be empty. Pass a unique user/session identifier.');
    }

    try {
      _environment = isProduction ? 'PRODUCTION' : 'SANDBOX';
      _packageName = isProduction ? 'com.phonepe.app' : 'com.phonepe.simulator';
      _merchantId = merchantId; // Store merchantId for later use

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

  /// Start payment transaction
  /// 
  /// PhonePe SDK will automatically:
  /// - Open PhonePe app (or simulator in sandbox)
  /// - Show all payment options (UPI apps, UPI ID, Card, Net Banking)
  /// - User selects and completes payment
  /// - Returns to app via deep link
  /// 
  /// [requestPayload] - Base64-encoded payment payload from backend (preferred method)
  /// [token] - PhonePe SDK token from backend (fallback if requestPayload not available)
  /// [orderId] - PhonePe order ID from backend (fallback if requestPayload not available)
  /// [appSchema] - Your app's custom URL scheme for callback (e.g., 'ecliniq')
  Future<PhonePePaymentResult> startPayment({
    String? requestPayload,
    String? token,
    String? orderId,
    required String appSchema,
  }) async {
    if (!_isInitialized) {
      throw PhonePeException('PhonePe SDK not initialized. Call initialize() first.');
    }

    print('========== PHONEPE SERVICE: START PAYMENT ==========');
    print('Request payload present: ${requestPayload != null}');
    if (requestPayload != null) {
      print('Request payload length: ${requestPayload.length}');
      print('Request payload (first 100 chars): ${requestPayload.substring(0, requestPayload.length > 100 ? 100 : requestPayload.length)}');
    } else {
      print('Token length: ${token?.length ?? 0}');
      print('Order ID: $orderId');
      print('Merchant ID: $_merchantId');
    }
    print('App schema: $appSchema');
    print('Environment: $_environment');
    print('Expected package: $_packageName');
    
    try {
      String requestToSend;
      
      // Use requestPayload directly if available (preferred method as per PhonePe docs)
      // The backend provides requestPayload as base64-encoded string
      // PhonePe SDK expects JSON string (not base64), so we need to decode it
      if (requestPayload != null && requestPayload.isNotEmpty) {
        // Backend provides base64-encoded payload
        // PhonePe SDK expects JSON string, so decode base64 to get JSON string
        // This matches the article pattern: decode base64 -> get JSON -> pass JSON to SDK
        try {
          final decodedBytes = base64Decode(requestPayload);
          final jsonString = utf8.decode(decodedBytes);
          
          // Verify it's valid JSON by parsing it
          final decodedMap = jsonDecode(jsonString);
          print('Using requestPayload from backend (decoded from base64)');
          print('Decoded payload structure: ${decodedMap.keys}');
          
          // Pass the JSON string to SDK (not the base64)
          requestToSend = jsonString;
        } catch (e) {
          throw PhonePeException('Failed to decode requestPayload from base64: $e');
        }
      } else {
        // Fallback: Construct payload from token and orderId (legacy support)
        if (_merchantId == null || _merchantId!.isEmpty) {
          throw PhonePeException('Merchant ID not available. Please initialize SDK with merchantId first.');
        }
        
        // Validate token and orderId
        if (token == null || token.isEmpty) {
          throw PhonePeException('Payment token cannot be empty');
        }
        if (orderId == null || orderId.isEmpty) {
          throw PhonePeException('Order ID cannot be empty');
        }
        
        // Construct the payment payload
        // PhonePe SDK expects: Base64(JSON.stringify({orderId, merchantId, token, paymentMode}))
        final payload = {
          'orderId': orderId,
          'merchantId': _merchantId,
          'token': token,
          'paymentMode': {'type': 'PAY_PAGE'},
        };
        
        // Convert to JSON string
        final jsonString = jsonEncode(payload);
        print('Payment payload JSON: $jsonString');
        
        // Pass JSON string directly to SDK (not base64)
        requestToSend = jsonString;
        print('Using constructed payload from token/orderId');
      }
      
      print('===================================================');
      print('Sending to PhonePe SDK (JSON string):');
      print('Length: ${requestToSend.length}');
      print('First 200 chars: ${requestToSend.substring(0, requestToSend.length > 200 ? 200 : requestToSend.length)}');
      print('===================================================');
      
      // PhonePe SDK startTransaction automatically:
      // 1. Opens PhonePe app (or simulator in sandbox mode based on environment)
      // 2. Shows payment method selector (UPI apps, UPI ID, Card, etc.)
      // 3. User completes payment
      // 4. Returns to app via deep link (appSchema)
      // 
      // Note: PhonePe SDK expects JSON string (not base64), matching the article pattern
      final response = await PhonePePaymentSdk.startTransaction(
        requestToSend, // JSON string (decoded from base64 if using requestPayload)
        appSchema, // callback URL schema (e.g., 'ecliniq')
      );

      print('========== PHONEPE SDK RESPONSE ==========');
      print('Response: $response');
      print('Response type: ${response.runtimeType}');
      print('==========================================');
      
      return PhonePePaymentResult.fromSdkResult(response);
    } catch (e) {
      print('========== PHONEPE PAYMENT ERROR ==========');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      print('==========================================');
      
      // Check for specific error types and provide helpful guidance
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
            'Error details: $e'
          );
        } else {
          throw PhonePeException(
            'PhonePe app signature mismatch. Please ensure PhonePe app is installed and up to date. Error: $e'
          );
        }
      }
      
      if (errorString.contains('api mapping') || errorString.contains('config')) {
        throw PhonePeException(
          'PhonePe SDK configuration error. Please verify:\n'
          '1. Merchant ID is correct: M237OHQ3YCVAO_2511191950\n'
          '2. Environment is set to SANDBOX for testing\n'
          '3. PhonePe Simulator is installed\n\n'
          'Error: $e'
        );
      }
      
      // Check for specific Android SDK JSON parsing error
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
          'Error details: $e'
        );
      }
      
      throw PhonePeException('Failed to start payment: $e');
    }
  }


  /// Get the current environment
  String? get environment => _environment;

  /// Get the package name
  String? get packageName => _packageName;

  /// Check if SDK is initialized
  bool get isInitialized => _isInitialized;
}

/// Payment result from PhonePe SDK
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
    print('Parsing SDK result: $result');
    print('Result type: ${result.runtimeType}');
    
    // PhonePe SDK returns different formats:
    // - String: "SUCCESS", "FAILURE", "INCOMPLETE"
    // - Map: {"status": "SUCCESS", ...}
    
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
      status = (result['status'] ?? result['STATUS'] ?? 'INCOMPLETE').toString().toUpperCase();
      error = result['error']?.toString();
    } else {
      status = result.toString().toUpperCase();
    }

    // Normalize status
    final success = status.contains('SUCCESS') || status == 'COMPLETED';
    
    return PhonePePaymentResult(
      success: success,
      status: status,
      error: error,
      data: result,
    );
  }
}

/// Custom exception for PhonePe operations
class PhonePeException implements Exception {
  final String message;

  PhonePeException(this.message);

  @override
  String toString() => 'PhonePeException: $message';
}