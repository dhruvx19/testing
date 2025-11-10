class Transaction {
  final String type; // 'credit' or 'debit'
  final int amount;
  final DateTime date;

  Transaction({
    required this.type,
    required this.amount,
    required this.date,
  });
}

// Monthly Transaction Group
class MonthlyTransactions {
  final String month;
  final List<Transaction> transactions;
  bool isExpanded;

  MonthlyTransactions({
    required this.month,
    required this.transactions,
    this.isExpanded = false,
  });
}