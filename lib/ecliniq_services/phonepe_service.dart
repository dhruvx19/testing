import 'dart:convert';
import 'dart:io';
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
  /// [request] - The base64 encoded payment request payload
  /// [appSchema] - Your app's custom URL scheme for callback
  Future<PhonePePaymentResult> startPayment({
    required String request,
    required String appSchema,
  }) async {
    if (!_isInitialized) {
      throw PhonePeException('PhonePe SDK not initialized. Call initialize() first.');
    }

    print('========== PHONEPE SERVICE: START PAYMENT ==========');
    print('Request (base64) length: ${request.length}');
    print('Request (first 100 chars): ${request.substring(0, request.length > 100 ? 100 : request.length)}');
    print('App schema: $appSchema');
    print('Environment: $_environment');
    print('Package name: $_packageName');
    print('====================================================');

    try {
      final response = await PhonePePaymentSdk.startTransaction(request, appSchema);
      
      print('========== PHONEPE SDK RAW RESPONSE ==========');
      print('Response type: ${response.runtimeType}');
      print('Response: $response');
      print('==============================================');

      if (response != null) {
        // Cast Map<dynamic, dynamic> to Map<String, dynamic>
        final Map<String, dynamic> responseMap = Map<String, dynamic>.from(response);
        
        final status = responseMap['status']?.toString() ?? '';
        final error = responseMap['error']?.toString();

        return PhonePePaymentResult(
          success: status == 'SUCCESS',
          status: status,
          error: error,
          data: responseMap,
        );
      }

      return PhonePePaymentResult(
        success: false,
        status: 'INCOMPLETE',
        error: 'Flow incomplete - no response received',
      );
    } catch (e) {
      throw PhonePeException('Failed to start payment: $e');
    }
  }

  /// Get list of installed UPI apps
  Future<List<UpiAppInfo>> getInstalledUpiApps() async {
    try {
      if (Platform.isAndroid) {
        return await _getUpiAppsForAndroid();
      } else {
        return await _getUpiAppsForIOS();
      }
    } catch (e) {
      throw PhonePeException('Failed to get installed UPI apps: $e');
    }
  }

  Future<List<UpiAppInfo>> _getUpiAppsForAndroid() async {
    final apps = await PhonePePaymentSdk.getUpiAppsForAndroid();
    if (apps == null) return [];

    final List<dynamic> decoded = json.decode(apps);
    return decoded.map((app) => UpiAppInfo.fromJson(app)).toList();
  }

  Future<List<UpiAppInfo>> _getUpiAppsForIOS() async {
    final apps = await PhonePePaymentSdk.getInstalledUpiAppsForiOS();
    if (apps == null) return [];

    return apps
        .whereType<String>()
        .map((name) => UpiAppInfo(applicationName: name))
        .toList();
  }

  /// Check if PhonePe app is installed
  Future<bool> isPhonePeInstalled() async {
    try {
      final apps = await getInstalledUpiApps();
      return apps.any((app) =>
          app.applicationName?.toUpperCase() == 'PHONEPE' ||
          app.packageName == 'com.phonepe.app');
    } catch (e) {
      return false;
    }
  }

  /// Get the appropriate package name based on environment
  String get packageName => _packageName;

  /// Check if SDK is initialized
  bool get isInitialized => _isInitialized;

  /// Current environment
  String get environment => _environment;
}

/// Payment result from PhonePe SDK
class PhonePePaymentResult {
  final bool success;
  final String status;
  final String? error;
  final Map<String, dynamic>? data;

  PhonePePaymentResult({
    required this.success,
    required this.status,
    this.error,
    this.data,
  });

  @override
  String toString() => 'PhonePePaymentResult(success: $success, status: $status, error: $error)';
}

/// UPI App information
class UpiAppInfo {
  final String? applicationName;
  final String? version;
  final String? packageName;

  UpiAppInfo({this.applicationName, this.version, this.packageName});

  factory UpiAppInfo.fromJson(Map<String, dynamic> json) {
    return UpiAppInfo(
      applicationName: json['applicationName'],
      version: json['version'],
      packageName: json['packageName'],
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