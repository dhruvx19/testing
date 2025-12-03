import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

/// Service wrapper for PhonePe Payment SDK
class PhonePeService {
  static final PhonePeService _instance = PhonePeService._internal();
  factory PhonePeService() => _instance;
  PhonePeService._internal();

  bool _isInitialized = false;
  String _environment = 'SANDBOX';
  String _packageName = 'com.phonepe.simulator';

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
  /// [request] - The base64 encoded payment request payload from backend
  /// [appSchema] - Your app's custom URL scheme for callback (e.g., 'ecliniq')
  Future<PhonePePaymentResult> startPayment({
    required String request,
    required String appSchema,
    String? packageName, // Optional: Not used currently, PhonePe SDK handles app selection
  }) async {
    if (!_isInitialized) {
      throw PhonePeException('PhonePe SDK not initialized. Call initialize() first.');
    }

    print('========== PHONEPE SERVICE: START PAYMENT ==========');
    print('Request (base64) length: ${request.length}');
    print('Request (first 100 chars): ${request.substring(0, request.length > 100 ? 100 : request.length)}');
    print('App schema: $appSchema');
    print('Environment: $_environment');
    print('Package name: ${packageName ?? "PhonePe SDK will handle"}');
    
    try {
      // PhonePe SDK startTransaction automatically:
      // 1. Opens PhonePe app (or simulator in sandbox)
      // 2. Shows payment method selector (UPI apps, UPI ID, Card, etc.)
      // 3. User completes payment
      // 4. Returns to app via deep link (appSchema)
      final response = await PhonePePaymentSdk.startTransaction(
        request, // base64 token from backend
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
      print('==========================================');
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