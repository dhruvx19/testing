import 'package:ecliniq/ecliniq_api/models/wallet.dart';
import 'package:flutter/widgets.dart';
import '../model/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  WalletTransactionsData? transactionsData;
  bool isLoading;
  int selectedYear;
  final Function(int)? onYearChanged;
  final Map<int, bool> _expansionState = {}; // Track expansion state by index

  TransactionProvider({
    this.transactionsData,
    this.isLoading = false,
    this.selectedYear = 2025,
    this.onYearChanged,
  }) {
    // Initialize expansion states
    _initializeExpansionStates();
  }

  void updateData({
    WalletTransactionsData? newTransactionsData,
    bool? newIsLoading,
    int? newSelectedYear,
  }) {
    transactionsData = newTransactionsData ?? transactionsData;
    isLoading = newIsLoading ?? isLoading;
    selectedYear = newSelectedYear ?? selectedYear;
    _initializeExpansionStates();
    notifyListeners();
  }

  void _initializeExpansionStates() {
    final data = monthlyData;
    for (int i = 0; i < data.length; i++) {
      if (!_expansionState.containsKey(i)) {
        // Always expand the first month (latest/January)
        _expansionState[i] = i == 0;
      }
    }
    // Ensure first month is always expanded
    if (data.isNotEmpty) {
      _expansionState[0] = true;
    }
  }

  List<MonthlyTransactions> get monthlyData {
    if (isLoading || transactionsData == null) {
      return [];
    }

    // Convert API transactions to UI model
    final List<MonthlyTransactions> monthlyList = [];
    
    transactionsData!.transactions.forEach((monthKey, transactions) {
      final uiTransactions = transactions.map((tx) {
        return Transaction(
          type: tx.isCredit ? 'credit' : 'debit',
          amount: tx.amount.toInt(),
          date: tx.createdAt,
        );
      }).toList();

      monthlyList.add(
        MonthlyTransactions(
          month: monthKey,
          transactions: uiTransactions,
          isExpanded: _expansionState[monthlyList.length] ?? false,
        ),
      );
    });

    // Sort by date (newest first)
    monthlyList.sort((a, b) {
      if (a.transactions.isEmpty || b.transactions.isEmpty) return 0;
      return b.transactions.first.date.compareTo(a.transactions.first.date);
    });

    // Update expansion states after sorting
    for (int i = 0; i < monthlyList.length; i++) {
      monthlyList[i].isExpanded = _expansionState[i] ?? false;
    }

    return monthlyList;
  }

  void toggleExpansion(int index) {
    _expansionState[index] = !(_expansionState[index] ?? false);
    notifyListeners();
  }
}
