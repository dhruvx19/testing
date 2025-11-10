import 'package:flutter/widgets.dart';
import '../model/transaction_model.dart';

class TransactionProvider extends ChangeNotifier {
  final List<MonthlyTransactions> _monthlyData = [
    MonthlyTransactions(
      month: 'September, 2025',
      transactions: [
        Transaction(
          type: 'credit',
          amount: 20,
          date: DateTime(2025, 9, 20, 12, 7),
        ),
        Transaction(
          type: 'debit',
          amount: 20,
          date: DateTime(2025, 9, 20, 12, 7),
        ),
        Transaction(
          type: 'credit',
          amount: 15,
          date: DateTime(2025, 9, 18, 10, 30),
        ),
      ],
    ),
    MonthlyTransactions(
      month: 'August, 2025',
      transactions: [
        Transaction(
          type: 'debit',
          amount: 30,
          date: DateTime(2025, 8, 15, 14, 20),
        ),
        Transaction(
          type: 'credit',
          amount: 50,
          date: DateTime(2025, 8, 10, 9, 15),
        ),
        Transaction(
          type: 'debit',
          amount: 10,
          date: DateTime(2025, 8, 5, 16, 45),
        ),
      ],
    ),
    MonthlyTransactions(
      month: 'April, 2025',
      transactions: [
        Transaction(
          type: 'credit',
          amount: 100,
          date: DateTime(2025, 4, 25, 11, 30),
        ),
        Transaction(
          type: 'debit',
          amount: 25,
          date: DateTime(2025, 4, 20, 13, 15),
        ),
        Transaction(
          type: 'credit',
          amount: 40,
          date: DateTime(2025, 4, 10, 10, 0),
        ),
        Transaction(
          type: 'debit',
          amount: 15,
          date: DateTime(2025, 4, 5, 15, 30),
        ),
      ],
    ),
  ];

  List<MonthlyTransactions> get monthlyData => _monthlyData;

  void toggleExpansion(int index) {
    _monthlyData[index].isExpanded = !_monthlyData[index].isExpanded;
    notifyListeners();
  }
}
