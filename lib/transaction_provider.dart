import 'dart:async';
import 'package:flutter/material.dart';
import 'history.dart';
import 'transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<AppTransaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];

  StreamSubscription? _transactionsSub;
  StreamSubscription? _budgetsSub;
  StreamSubscription? _savingsSub;

  TransactionProvider() {
    _initStreams();
  }

  void _initStreams() {
    _transactionsSub = _repository.getTransactionsStream().listen((data) {
      _transactions = data;
      notifyListeners();
    });

    _budgetsSub = _repository.getBudgetsStream().listen((data) {
      _budgets = data;
      notifyListeners();
    });

    _savingsSub = _repository.getSavingsGoalsStream().listen((data) {
      _savingsGoals = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _transactionsSub?.cancel();
    _budgetsSub?.cancel();
    _savingsSub?.cancel();
    super.dispose();
  }

  /// Getter for all transactions sorted by date
  List<AppTransaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get savingsGoals => _savingsGoals;

  /// Adds a transaction
  Future<void> addTransaction(AppTransaction t) async {
    await _repository.save(t);
  }

  /// Deletes a transaction
  Future<void> deleteTransaction(AppTransaction t) async {
    await _repository.delete(t);
  }

  Future<void> addBudget(Budget b) async {
    await _repository.saveBudget(b);
  }

  Future<void> deleteBudget(Budget b) async {
    await _repository.deleteBudget(b);
  }

  Future<void> addSavingsGoal(SavingsGoal s) async {
    await _repository.saveSavingsGoal(s);
  }

  Future<void> deleteSavingsGoal(SavingsGoal s) async {
    await _repository.deleteSavingsGoal(s);
  }

  /// Permanently deletes all transactions from storage and refreshes the UI
  Future<void> clearAllData() async {
    for (var t in _transactions) {
      await _repository.delete(t);
    }
    for (var b in _budgets) {
      await _repository.deleteBudget(b);
    }
    for (var s in _savingsGoals) {
      await _repository.deleteSavingsGoal(s);
    }
  }

  // Logic for calculations
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalBalance => totalIncome - totalExpense;

  // Filters transactions by a specific date (ignoring time)
  List<AppTransaction> getTransactionsForDate(DateTime date) {
    return _transactions.where((t) =>
        t.dateTime.year == date.year &&
        t.dateTime.month == date.month &&
        t.dateTime.day == date.day).toList();
  }

  /// Calculates the amount spent towards a specific budget based on its period/fixed date
  double getSpentAmountForBudget(Budget budget) {
    final now = DateTime.now();
    return _transactions.where((t) {
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
    return _transactions.where((t) {
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
    
    final oldBudgets = _budgets.where((b) => b.createdAt.isBefore(oneYearAgo)).toList();
    for (var b in oldBudgets) {
      await deleteBudget(b);
    }
    
    final oldSavings = _savingsGoals.where((s) => s.createdAt.isBefore(oneYearAgo)).toList();
    for (var s in oldSavings) {
      await deleteSavingsGoal(s);
    }
  }
}