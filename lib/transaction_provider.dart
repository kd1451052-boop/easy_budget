import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'history.dart';
import 'transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<AppTransaction> _transactions = [];
  List<Budget> _budgets = [];
  List<SavingsGoal> _savingsGoals = [];

  StreamSubscription? _authSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _budgetsSub;
  StreamSubscription? _savingsSub;

  TransactionProvider() {
    _initStreams();
    // Re-subscribe to Firestore streams whenever the user signs in, switches accounts, or logs out.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _initStreams();
    });
  }

  void _initStreams() {
    _transactionsSub?.cancel();
    _budgetsSub?.cancel();
    _savingsSub?.cancel();

    _transactionsSub = _repository.getTransactionsStream().listen((data) {
      _transactions = data..sort((a, b) => b.dateTime.compareTo(a.dateTime));
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
    _authSub?.cancel();
    _transactionsSub?.cancel();
    _budgetsSub?.cancel();
    _savingsSub?.cancel();
    super.dispose();
  }

  /// Getter for all transactions sorted by date
  List<AppTransaction> get transactions => _transactions;
  List<Budget> get budgets => _budgets;
  List<SavingsGoal> get savingsGoals => _savingsGoals;

  /// Adds a transaction (optimistically updates local state and persists to Firestore)
  Future<void> addTransaction(AppTransaction t) async {
    final existingIdx = _transactions.indexWhere((item) => item.id == t.id);
    if (existingIdx >= 0) {
      _transactions[existingIdx] = t;
    } else {
      _transactions = [..._transactions, t]
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    }
    notifyListeners();
    await _repository.save(t);
  }

  /// Deletes a transaction
  Future<void> deleteTransaction(AppTransaction t) async {
    _transactions = _transactions.where((item) => item.id != t.id).toList();
    notifyListeners();
    await _repository.delete(t);
  }

  Future<void> addBudget(Budget b) async {
    final existingIdx = _budgets.indexWhere((item) => item.id == b.id);
    if (existingIdx >= 0) {
      _budgets[existingIdx] = b;
    } else {
      _budgets = [..._budgets, b]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
    await _repository.saveBudget(b);
  }

  Future<void> deleteBudget(Budget b) async {
    _budgets = _budgets.where((item) => item.id != b.id).toList();
    notifyListeners();
    await _repository.deleteBudget(b);
  }

  Future<void> addSavingsGoal(SavingsGoal s) async {
    final existingIdx = _savingsGoals.indexWhere((item) => item.id == s.id);
    if (existingIdx >= 0) {
      _savingsGoals[existingIdx] = s;
    } else {
      _savingsGoals = [..._savingsGoals, s]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    notifyListeners();
    await _repository.saveSavingsGoal(s);
  }

  Future<void> deleteSavingsGoal(SavingsGoal s) async {
    _savingsGoals = _savingsGoals.where((item) => item.id != s.id).toList();
    notifyListeners();
    await _repository.deleteSavingsGoal(s);
  }

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
    _transactions.clear();
    _budgets.clear();
    _savingsGoals.clear();
    notifyListeners();
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

  /// Calculates the amount saved towards a specific savings goal.
  /// For AI Product Saving Goals, saved progress adjusts dynamically with the main balance
  /// (plus any direct deposits to the goal's category).
  double getSavedAmountForGoal(SavingsGoal goal) {
    final now = DateTime.now();
    final categorySaved = _transactions.where((t) {
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

    if (goal.isAiProductGoal) {
      // Adjust saved amount dynamically with the main balance (totalBalance).
      return totalBalance + categorySaved;
    }

    return categorySaved;
  }

  /// Calculates the effective daily saving rate for a goal based on AI plan or transaction history.
  double getEffectiveDailySavingRate(SavingsGoal goal) {
    if (goal.plannedDailySaving != null &&
        goal.plannedDailySaving!.isFinite &&
        goal.plannedDailySaving! > 0) {
      return goal.plannedDailySaving!;
    }
    // Fallback: estimate from historical average daily income or target / 30 days
    final incomeTotal = totalIncome;
    final expenseTotal = totalExpense;
    final net = incomeTotal - expenseTotal;
    final safeGoalAmount = goal.amount > 1.0 ? goal.amount : 1.0;
    if (net > 0) {
      return (net / 30.0).clamp(1.0, safeGoalAmount);
    }
    return (safeGoalAmount / 30.0).clamp(1.0, double.infinity);
  }

  /// Calculates the dynamic number of days left to achieve a savings goal.
  /// If the user makes more expense transactions or goes into a negative main balance,
  /// the remaining gap increases and adds more days to achieve the saving goal.
  int getDynamicDaysLeftForGoal(SavingsGoal goal) {
    final savedSoFar = getSavedAmountForGoal(goal);
    final remainingNeeded = goal.amount - savedSoFar;
    if (!remainingNeeded.isFinite || remainingNeeded <= 0) {
      return 0;
    }

    final dailyRate = getEffectiveDailySavingRate(goal);
    if (dailyRate.isFinite && dailyRate > 0) {
      final ratio = remainingNeeded / dailyRate;
      if (ratio.isFinite) {
        return ratio.ceil().clamp(0, 36500);
      }
    }

    if (goal.targetDate != null) {
      final diff = goal.targetDate!.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    }
    return 30;
  }

  /// Returns how many extra days were added because of a negative balance or new expenses.
  int getExtraDaysAddedFromBalance(SavingsGoal goal) {
    if (totalBalance >= 0) return 0;
    final dailyRate = getEffectiveDailySavingRate(goal);
    if (!dailyRate.isFinite || dailyRate <= 0) return 0;
    final ratio = totalBalance.abs() / dailyRate;
    if (!ratio.isFinite) return 0;
    return ratio.ceil().clamp(0, 36500);
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