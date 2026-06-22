

class Transaction {
  final String id;
  final String type; // "income" or "expense"
  final double amount;
  final String category;
  final String note;
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });
}