import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'history.dart';
import 'transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final Box<Transaction> _box = Hive.box<Transaction>(TransactionRepository.boxName);
  final Box<Budget> _budgetBox = Hive.box<Budget>(TransactionRepository.budgetBoxName);
  final Box<SavingsGoal> _savingsBox = Hive.box<SavingsGoal>(TransactionRepository.savingsBoxName);

  TransactionProvider() {
    cleanUpOldHistory();
  }

  /// Getter for all transactions sorted by date
  List<Transaction> get transactions {
    final list = _box.values.toList();
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  List<Budget> get budgets {
    final list = _budgetBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<SavingsGoal> get savingsGoals {
    final list = _savingsBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Future<void> addBudget(Budget b) async {
    await _budgetBox.put(b.id, b);
    notifyListeners();
  }

  Future<void> deleteBudget(Budget b) async {
    await b.delete();
    notifyListeners();
  }

  Future<void> addSavingsGoal(SavingsGoal s) async {
    await _savingsBox.put(s.id, s);
    notifyListeners();
  }

  Future<void> deleteSavingsGoal(SavingsGoal s) async {
    await s.delete();
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

  /// Calculates the amount spent towards a specific budget based on its period/fixed date
  double getSpentAmountForBudget(Budget budget) {
    final now = DateTime.now();
    return _box.values.where((t) {
      if (t.type != TransactionType.expense || t.category != budget.category) return false;
      
      if (budget.isFixed && budget.targetDate != null) {
        // Includes all expenses before the target date
        return t.dateTime.isBefore(budget.targetDate!) || t.dateTime.isAtSameMomentAs(budget.targetDate!);
      } else if (!budget.isFixed && budget.period != null) {
        if (budget.period == BudgetPeriod.weekly) {
          DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return t.dateTime.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
        } else if (budget.period == BudgetPeriod.monthly) {
          return t.dateTime.year == now.year && t.dateTime.month == now.month;
        } else if (budget.period == BudgetPeriod.yearly) {
          return t.dateTime.year == now.year;
        }
      }
      return false;
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculates the amount saved towards a specific savings goal
  /// Assumes we track "expense" transactions into the savings category as money put towards savings.
  double getSavedAmountForGoal(SavingsGoal goal) {
    final now = DateTime.now();
    return _box.values.where((t) {
      if (t.type != TransactionType.expense || t.category != goal.category) return false;
      
      if (goal.isFixed && goal.targetDate != null) {
        return t.dateTime.isBefore(goal.targetDate!) || t.dateTime.isAtSameMomentAs(goal.targetDate!);
      } else if (!goal.isFixed && goal.period != null) {
        if (goal.period == BudgetPeriod.weekly) {
          DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return t.dateTime.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
        } else if (goal.period == BudgetPeriod.monthly) {
          return t.dateTime.year == now.year && t.dateTime.month == now.month;
        } else if (goal.period == BudgetPeriod.yearly) {
          return t.dateTime.year == now.year;
        }
      }
      return false;
    }).fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Deletes budgets and savings goals that are older than 1 year.
  Future<void> cleanUpOldHistory() async {
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    
    final oldBudgets = _budgetBox.values.where((b) => b.createdAt.isBefore(oneYearAgo)).toList();
    for (var b in oldBudgets) {
      await b.delete();
    }
    
    final oldSavings = _savingsBox.values.where((s) => s.createdAt.isBefore(oneYearAgo)).toList();
    for (var s in oldSavings) {
      await s.delete();
    }
    
    if (oldBudgets.isNotEmpty || oldSavings.isNotEmpty) {
      notifyListeners();
    }
  }
}