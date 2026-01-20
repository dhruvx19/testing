class BookingPaymentData {
  final String appointmentId;
  final String status;
  final bool paymentRequired;
  final String? paymentId;
  final String merchantTransactionId;
  final double totalAmount;
  final double walletAmount;
  final double gatewayAmount;
  final String provider;
  final String? token;
  final String? orderId;
  final String? requestPayload;
  final DateTime? expiresAt;

  BookingPaymentData({
    required this.appointmentId,
    required this.status,
    required this.paymentRequired,
    this.paymentId,
    required this.merchantTransactionId,
    required this.totalAmount,
    required this.walletAmount,
    required this.gatewayAmount,
    required this.provider,
    this.token,
    this.orderId,
    this.requestPayload,
    this.expiresAt,
  });

  factory BookingPaymentData.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? {};

    final paymentToken = payment['token'] as String?;
    final requestPayload = payment['requestPayload'] as String?;

    return BookingPaymentData(
      appointmentId: json['appointmentId'] as String? ?? '',
      status: json['status'] as String? ?? 'CREATED',
      paymentRequired: json['paymentRequired'] as bool? ?? false,
      paymentId: payment['paymentId'] as String?,
      merchantTransactionId: payment['merchantTransactionId'] as String? ?? '',
      totalAmount: _parseDouble(payment['totalAmount']),
      walletAmount: _parseDouble(payment['walletAmount']),
      gatewayAmount: _parseDouble(payment['gatewayAmount']),
      provider: payment['provider'] as String? ?? 'GATEWAY',
      token: paymentToken,
      orderId: payment['orderId'] as String?,
      requestPayload: requestPayload,
      expiresAt: payment['expiresAt'] != null
          ? DateTime.tryParse(payment['expiresAt'] as String)
          : null,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'appointmentId': appointmentId,
      'status': status,
      'paymentRequired': paymentRequired,
      'payment': {
        'paymentId': paymentId,
        'merchantTransactionId': merchantTransactionId,
        'totalAmount': totalAmount.toString(),
        'walletAmount': walletAmount.toString(),
        'gatewayAmount': gatewayAmount.toString(),
        'provider': provider,
        'token': token,
        'orderId': orderId,
        'requestPayload': requestPayload,
        'expiresAt': expiresAt?.toIso8601String(),
      },
    };
  }

  bool get requiresGateway => paymentRequired && gatewayAmount > 0;

  bool get isWalletOnly =>
      paymentRequired && gatewayAmount == 0 && walletAmount > 0;

  bool get isGatewayOnly =>
      paymentRequired && walletAmount == 0 && gatewayAmount > 0;

  bool get isHybrid => paymentRequired && walletAmount > 0 && gatewayAmount > 0;
}

/// Payment status data
class PaymentStatusData {
  final String? paymentId;
  final String merchantTransactionId;
  final String status;
  final String? appointmentId;
  final double amount;
  final String checkedAt;

  PaymentStatusData({
    this.paymentId,
    required this.merchantTransactionId,
    required this.status,
    this.appointmentId,
    required this.amount,
    required this.checkedAt,
  });

  factory PaymentStatusData.fromJson(Map<String, dynamic> json) {
    toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return PaymentStatusData(
      paymentId: json['paymentId']?.toString(),
      merchantTransactionId: json['merchantTransactionId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      appointmentId: json['appointmentId']?.toString(),
      amount: toDouble(json['amount']),
      checkedAt:
          json['checkedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (paymentId != null) 'paymentId': paymentId,
      'merchantTransactionId': merchantTransactionId,
      'status': status,
      if (appointmentId != null) 'appointmentId': appointmentId,
      'amount': amount,
      'checkedAt': checkedAt,
    };
  }

  /// Check if payment is in a terminal state
  bool get isTerminal {
    return [
      'SUCCEEDED',
      'COMPLETED',
      'FAILED',
      'EXPIRED',
      'CANCELLED',
    ].contains(status);
  }

  /// Check if payment was successful
  bool get isSuccess {
    return status == 'SUCCEEDED' || status == 'COMPLETED';
  }
}

/// Payment status response
class PaymentStatusResponse {
  final bool success;
  final String message;
  final PaymentStatusData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  PaymentStatusResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? PaymentStatusData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp:
          json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}

/// Payment detail data
class PaymentDetailData {
  final String id;
  final String merchantTransactionId;
  final double totalAmount;
  final double walletAmount;
  final double gatewayAmount;
  final String provider;
  final String status;
  final String? gatewayName;
  final String? gatewayOrderId;
  final String? gatewayTransactionId;
  final String? processedAt;
  final String? expiresAt;

  PaymentDetailData({
    required this.id,
    required this.merchantTransactionId,
    required this.totalAmount,
    required this.walletAmount,
    required this.gatewayAmount,
    required this.provider,
    required this.status,
    this.gatewayName,
    this.gatewayOrderId,
    this.gatewayTransactionId,
    this.processedAt,
    this.expiresAt,
  });

  factory PaymentDetailData.fromJson(Map<String, dynamic> json) {
    toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return PaymentDetailData(
      id: json['id']?.toString() ?? '',
      merchantTransactionId: json['merchantTransactionId']?.toString() ?? '',
      totalAmount: toDouble(json['totalAmount']),
      walletAmount: toDouble(json['walletAmount']),
      gatewayAmount: toDouble(json['gatewayAmount']),
      provider: json['provider']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      gatewayName: json['gatewayName']?.toString(),
      gatewayOrderId: json['gatewayOrderId']?.toString(),
      gatewayTransactionId: json['gatewayTransactionId']?.toString(),
      processedAt: json['processedAt']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantTransactionId': merchantTransactionId,
      'totalAmount': totalAmount,
      'walletAmount': walletAmount,
      'gatewayAmount': gatewayAmount,
      'provider': provider,
      'status': status,
      if (gatewayName != null) 'gatewayName': gatewayName,
      if (gatewayOrderId != null) 'gatewayOrderId': gatewayOrderId,
      if (gatewayTransactionId != null)
        'gatewayTransactionId': gatewayTransactionId,
      if (processedAt != null) 'processedAt': processedAt,
      if (expiresAt != null) 'expiresAt': expiresAt,
    };
  }
}

/// Payment details response
class PaymentDetailResponse {
  final bool success;
  final String message;
  final PaymentDetailData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  PaymentDetailResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory PaymentDetailResponse.fromJson(Map<String, dynamic> json) {
    return PaymentDetailResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? PaymentDetailData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp:
          json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data!.toJson(),
      'errors': errors,
      'meta': meta,
      'timestamp': timestamp,
    };
  }
}
