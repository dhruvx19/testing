import 'dart:convert';

import 'package:ecliniq/ecliniq_api/models/wallet.dart';
import 'package:ecliniq/ecliniq_api/src/endpoints.dart';
import 'package:http/http.dart' as http;

/// Service for wallet-related API operations
/// @description Handles wallet balance retrieval and transaction history
class WalletService {
  /// Get wallet balance for the authenticated patient
  /// @description Retrieves the current wallet balance, total deposited amount, and currency
  /// @param authToken - Authentication token from AuthProvider
  /// @returns WalletBalanceResponse with balance data or error
  /// @throws Exception on network errors or invalid responses
  Future<WalletBalanceResponse> getBalance({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse(Endpoints.walletBalance);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return WalletBalanceResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return WalletBalanceResponse(
          success: false,
          message:
              responseData['message']?.toString() ??
              'Failed to fetch wallet balance: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return WalletBalanceResponse(
        success: false,
        message: 'Network error: $e',
        data: null,
        errors: e.toString(),
        meta: null,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get wallet transaction history for a specific year
  /// @description Retrieves wallet transactions grouped by month for the specified year
  /// @param authToken - Authentication token from AuthProvider
  /// @param year - Year to fetch transactions for (defaults to current year)
  /// @returns WalletTransactionsResponse with transaction data grouped by month or error
  /// @throws Exception on network errors or invalid responses
  Future<WalletTransactionsResponse> getTransactions({
    required String authToken,
    int? year,
  }) async {
    try {
      // Use current year if not specified
      final targetYear = year ?? DateTime.now().year;
      final url = Uri.parse(Endpoints.walletTransactions(targetYear));

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
        'x-access-token': authToken,
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return WalletTransactionsResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        return WalletTransactionsResponse(
          success: false,
          message:
              responseData['message']?.toString() ??
              'Failed to fetch wallet transactions: ${response.statusCode}',
          data: null,
          errors: response.body,
          meta: null,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      return WalletTransactionsResponse(
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



