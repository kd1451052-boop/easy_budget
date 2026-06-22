import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'history.dart';
import 'transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final Box<Transaction> _box = Hive.box<Transaction>(TransactionRepository.boxName);

  /// Getter for all transactions sorted by date
  List<Transaction> get transactions {
    final list = _box.values.toList();
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  /// Adds a transaction to Hive and notifies UI
  Future<void> addTransaction(Transaction t) async {
    await _box.put(t.id, t);
    notifyListeners();
  }

  /// Deletes a transaction
  Future<void> deleteTransaction(Transaction t) async {
    await t.delete();
    notifyListeners();
  }

  /// Permanently deletes all transactions from storage and refreshes the UI
  Future<void> clearAllData() async {
    await _box.clear();
    notifyListeners();
  }

  // Logic for calculations
  double get totalIncome => _box.values
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => _box.values
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalBalance => totalIncome - totalExpense;

  // Filters transactions by a specific date (ignoring time)
  List<Transaction> getTransactionsForDate(DateTime date) {
    return _box.values.where((t) =>
        t.dateTime.year == date.year &&
        t.dateTime.month == date.month &&
        t.dateTime.day == date.day).toList();
  }
}