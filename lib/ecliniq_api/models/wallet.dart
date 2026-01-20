/// Wallet balance data model
class WalletBalanceData {
  final double balance;
  final double totalDeposited;
  final String currency;

  WalletBalanceData({
    required this.balance,
    required this.totalDeposited,
    required this.currency,
  });

  factory WalletBalanceData.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return WalletBalanceData(
      balance: parseDouble(json['balance']),
      totalDeposited: parseDouble(json['totalDeposited']),
      currency: json['currency']?.toString() ?? 'INR',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'totalDeposited': totalDeposited,
      'currency': currency,
    };
  }
}

/// Wallet balance response model
class WalletBalanceResponse {
  final bool success;
  final String message;
  final WalletBalanceData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  WalletBalanceResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    return WalletBalanceResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? WalletBalanceData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
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

/// Wallet transaction model
class WalletTransaction {
  final String id;
  final String type; // 'DEBIT' or 'TOPUP'
  final double amount;
  final String description;
  final DateTime createdAt;
  final double balanceAfter;
  final String status;
  final String referenceType;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.balanceAfter,
    required this.status,
    required this.referenceType,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper to safely parse DateTime
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      try {
        final timeStr = value is String ? value : value.toString();
        return DateTime.parse(timeStr);
      } catch (e) {
        return DateTime.now();
      }
    }

    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: parseDouble(json['amount']),
      description: json['description']?.toString() ?? '',
      createdAt: parseDateTime(json['createdAt']),
      balanceAfter: parseDouble(json['balanceAfter']),
      status: json['status']?.toString() ?? '',
      referenceType: json['referenceType']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'balanceAfter': balanceAfter,
      'status': status,
      'referenceType': referenceType,
    };
  }

  /// Check if transaction is a credit (TOPUP)
  bool get isCredit => type.toUpperCase() == 'TOPUP';

  /// Check if transaction is a debit
  bool get isDebit => type.toUpperCase() == 'DEBIT';

  /// Check if transaction is completed
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
}

/// Wallet transactions data model (grouped by month)
class WalletTransactionsData {
  final double balance;
  final double totalDeposited;
  final String currency;
  final int year;
  final Map<String, List<WalletTransaction>> transactions;

  WalletTransactionsData({
    required this.balance,
    required this.totalDeposited,
    required this.currency,
    required this.year,
    required this.transactions,
  });

  factory WalletTransactionsData.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Parse transactions map
    Map<String, List<WalletTransaction>> parseTransactions(
        Map<String, dynamic>? transactionsJson) {
      if (transactionsJson == null) return {};

      final Map<String, List<WalletTransaction>> result = {};
      transactionsJson.forEach((key, value) {
        if (value is List) {
          result[key] = value
              .map((item) => WalletTransaction.fromJson(
                  item as Map<String, dynamic>))
              .toList();
        }
      });

      return result;
    }

    return WalletTransactionsData(
      balance: parseDouble(json['balance']),
      totalDeposited: parseDouble(json['totalDeposited']),
      currency: json['currency']?.toString() ?? 'INR',
      year: json['year'] is int
          ? json['year']
          : json['year'] != null
              ? int.tryParse(json['year'].toString()) ?? DateTime.now().year
              : DateTime.now().year,
      transactions: parseTransactions(
          json['transactions'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> transactionsJson = {};
    transactions.forEach((key, value) {
      transactionsJson[key] = value.map((tx) => tx.toJson()).toList();
    });

    return {
      'balance': balance,
      'totalDeposited': totalDeposited,
      'currency': currency,
      'year': year,
      'transactions': transactionsJson,
    };
  }

  /// Get all transactions as a flat list sorted by date (newest first)
  List<WalletTransaction> get allTransactions {
    final List<WalletTransaction> all = [];
    transactions.forEach((month, txList) {
      all.addAll(txList);
    });
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// Get transactions for a specific month
  List<WalletTransaction> getTransactionsForMonth(String month) {
    return transactions[month] ?? [];
  }

  /// Get all month keys sorted chronologically (newest first)
  List<String> get months {
    final months = transactions.keys.toList();
    // Sort months in reverse chronological order
    months.sort((a, b) {
      try {
        final dateA = DateTime.parse(a);
        final dateB = DateTime.parse(b);
        return dateB.compareTo(dateA);
      } catch (e) {
        // If parsing fails, use string comparison
        return b.compareTo(a);
      }
    });
    return months;
  }
}

/// Wallet transactions response model
class WalletTransactionsResponse {
  final bool success;
  final String message;
  final WalletTransactionsData? data;
  final dynamic errors;
  final dynamic meta;
  final String timestamp;

  WalletTransactionsResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
    required this.timestamp,
  });

  factory WalletTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return WalletTransactionsResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? WalletTransactionsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      meta: json['meta'],
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
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



