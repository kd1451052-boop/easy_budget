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
  final List<SavingsGoal> _newlyReachedGoals = [];
  final Set<String> _notifiedGoalIds = {};

  StreamSubscription? _authSub;
  StreamSubscription? _transactionsSub;
  StreamSubscription? _budgetsSub;
  StreamSubscription? _savingsSub;
  String? _activeUid;
  bool _hasLoadedTransactions = false;
  bool _hasLoadedSavings = false;

  TransactionProvider() {
    _activeUid = FirebaseAuth.instance.currentUser?.uid;
    _initStreams();
    // Re-subscribe to Firestore streams only when the signed-in user's UID actually changes.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final newUid = user?.uid;
      if (newUid != _activeUid) {
        _activeUid = newUid;
        _hasLoadedTransactions = false;
        _hasLoadedSavings = false;
        _initStreams();
      }
    });
  }

  void _initStreams() {
    _transactionsSub?.cancel();
    _budgetsSub?.cancel();
    _savingsSub?.cancel();

    _transactionsSub = _repository.getTransactionsStream().listen(
      (data) {
        _transactions = data..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        _hasLoadedTransactions = true;
        _checkAndCompleteReachedGoals();
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Transactions stream error: $e'),
    );

    _budgetsSub = _repository.getBudgetsStream().listen(
      (data) {
        _budgets = data;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Budgets stream error: $e'),
    );

    _savingsSub = _repository.getSavingsGoalsStream().listen(
      (data) {
        _savingsGoals = data;
        for (final g in _savingsGoals) {
          if (g.isCompleted) {
            _notifiedGoalIds.add(g.id);
          }
        }
        _hasLoadedSavings = true;
        _checkAndCompleteReachedGoals();
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Savings goals stream error: $e'),
    );
  }

  /// Checks all active saving goals and marks any goal whose saved amount has met or
  /// exceeded its target amount as completed, moving it to B&S History and queuing
  /// a "Goal Reached!" celebration popup.
  void _checkAndCompleteReachedGoals({bool forceCheck = false}) {
    if (!forceCheck && (!_hasLoadedTransactions || !_hasLoadedSavings)) {
      return;
    }

    bool anyUpdated = false;
    final now = DateTime.now();

    for (int i = 0; i < _savingsGoals.length; i++) {
      final goal = _savingsGoals[i];
      if (goal.isCompleted) {
        _notifiedGoalIds.add(goal.id);
        continue;
      }
      if (goal.amount <= 0 || !goal.amount.isFinite) continue;

      final saved = getSavedAmountForGoal(goal);
      if (saved.isFinite && saved >= goal.amount) {
        final completedGoal = goal.copyWith(
          isCompleted: true,
          completedAt: now,
        );
        _savingsGoals[i] = completedGoal;
        anyUpdated = true;

        if (!_notifiedGoalIds.contains(goal.id)) {
          _notifiedGoalIds.add(goal.id);
          _newlyReachedGoals.add(completedGoal);
        }

        unawaited(_repository.saveSavingsGoal(completedGoal));
      }
    }

    if (anyUpdated) {
      _savingsGoals = [..._savingsGoals];
    }
  }

  /// Pops the next newly reached saving goal so the UI can display the "Goal Reached!" popup once.
  SavingsGoal? consumeNewlyReachedGoal() {
    if (_newlyReachedGoals.isEmpty) return null;
    return _newlyReachedGoals.removeAt(0);
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
    _checkAndCompleteReachedGoals(forceCheck: true);
    notifyListeners();
    await _repository.save(t);
  }

  /// Deletes a transaction
  Future<void> deleteTransaction(AppTransaction t) async {
    _transactions = _transactions.where((item) => item.id != t.id).toList();
    _checkAndCompleteReachedGoals(forceCheck: true);
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
    _checkAndCompleteReachedGoals(forceCheck: true);
    final updatedGoal = _savingsGoals.firstWhere(
      (item) => item.id == s.id,
      orElse: () => s,
    );
    notifyListeners();
    await _repository.saveSavingsGoal(updatedGoal);
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
    return _transactions
        .where(
          (t) =>
              t.dateTime.year == date.year &&
              t.dateTime.month == date.month &&
              t.dateTime.day == date.day,
        )
        .toList();
  }

  /// Calculates the amount spent towards a specific budget based on its period/fixed date
  double getSpentAmountForBudget(Budget budget) {
    final now = DateTime.now();
    return _transactions
        .where((t) {
          if (t.type != TransactionType.expense ||
              t.category != budget.category) {
            return false;
          }

          if (budget.isFixed && budget.targetDate != null) {
            // Includes all expenses before the target date
            return t.dateTime.isBefore(budget.targetDate!) ||
                t.dateTime.isAtSameMomentAs(budget.targetDate!);
          } else if (!budget.isFixed && budget.period != null) {
            if (budget.period == BudgetPeriod.weekly) {
              DateTime startOfWeek = now.subtract(
                Duration(days: now.weekday - 1),
              );
              startOfWeek = DateTime(
                startOfWeek.year,
                startOfWeek.month,
                startOfWeek.day,
              );
              return t.dateTime.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              );
            } else if (budget.period == BudgetPeriod.monthly) {
              return t.dateTime.year == now.year &&
                  t.dateTime.month == now.month;
            } else if (budget.period == BudgetPeriod.yearly) {
              return t.dateTime.year == now.year;
            }
          }
          return false;
        })
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  /// Calculates the amount saved towards a specific savings goal.
  /// For AI Product Saving Goals, saved progress adjusts dynamically with the main balance
  /// (plus any direct deposits to the goal's category).
  double getSavedAmountForGoal(SavingsGoal goal) {
    final now = DateTime.now();
    final categorySaved = _transactions
        .where((t) {
          if (t.type != TransactionType.expense || t.category != goal.category) {
            return false;
          }

          if (goal.isFixed && goal.targetDate != null) {
            return t.dateTime.isBefore(goal.targetDate!) ||
                t.dateTime.isAtSameMomentAs(goal.targetDate!);
          } else if (!goal.isFixed && goal.period != null) {
            if (goal.period == BudgetPeriod.weekly) {
              DateTime startOfWeek = now.subtract(
                Duration(days: now.weekday - 1),
              );
              startOfWeek = DateTime(
                startOfWeek.year,
                startOfWeek.month,
                startOfWeek.day,
              );
              return t.dateTime.isAfter(
                startOfWeek.subtract(const Duration(seconds: 1)),
              );
            } else if (goal.period == BudgetPeriod.monthly) {
              return t.dateTime.year == now.year &&
                  t.dateTime.month == now.month;
            } else if (goal.period == BudgetPeriod.yearly) {
              return t.dateTime.year == now.year;
            }
          }
          return false;
        })
        .fold(0.0, (sum, item) => sum + item.amount);

    final double computedSaved = goal.isAiProductGoal
        ? (totalBalance + categorySaved)
        : categorySaved;
    if (goal.isCompleted && computedSaved < goal.amount) {
      return goal.amount;
    }
    return computedSaved;
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

    final oldBudgets = _budgets
        .where((b) => b.createdAt.isBefore(oneYearAgo))
        .toList();
    for (var b in oldBudgets) {
      await deleteBudget(b);
    }

    final oldSavings = _savingsGoals
        .where((s) => s.createdAt.isBefore(oneYearAgo))
        .toList();
    for (var s in oldSavings) {
      await deleteSavingsGoal(s);
    }
  }
}
