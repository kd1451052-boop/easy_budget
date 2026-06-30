import 'package:hive/hive.dart';
import 'history.dart';

/// A central class to handle all database interactions.
/// This keeps the UI logic separate from data storage logic (Separation of Concerns).
class TransactionRepository {
  static const String boxName = 'transactions';
  static const String budgetBoxName = 'budgets';
  static const String savingsBoxName = 'savings_goals';

  /// Registers adapters and opens the Hive box. Called once in main.dart.
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionTypeAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(BudgetPeriodAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(BudgetAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(SavingsGoalAdapter());
    await Hive.openBox<Transaction>(boxName);
    await Hive.openBox<Budget>(budgetBoxName);
    await Hive.openBox<SavingsGoal>(savingsBoxName);
  }

  /// Getter for the opened Hive box.
  Box<Transaction> get _box => Hive.box<Transaction>(boxName);
  Box<Budget> get _budgetBox => Hive.box<Budget>(budgetBoxName);
  Box<SavingsGoal> get _savingsBox => Hive.box<SavingsGoal>(savingsBoxName);

  List<Transaction> getAll() {
    return _box.values.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Budget> getAllBudgets() {
    return _budgetBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<SavingsGoal> getAllSavingsGoals() {
    return _savingsBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Creates a new entry in the database.
  Future<void> save(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
  }

  /// Updates an existing entry.
  Future<void> update(Transaction transaction) async {
    await transaction.save();
  }

  Future<void> delete(Transaction transaction) async {
    await transaction.delete();
  }

  Future<void> saveBudget(Budget budget) async {
    await _budgetBox.put(budget.id, budget);
  }

  Future<void> deleteBudget(Budget budget) async {
    await budget.delete();
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    await _savingsBox.put(goal.id, goal);
  }

  Future<void> deleteSavingsGoal(SavingsGoal goal) async {
    await goal.delete();
  }

  /// Aggregates all transactions to calculate the current wallet balance.
  double getTotalBalance() {
    return _box.values.fold(0.0, (sum, item) => sum + (item.type == TransactionType.income ? item.amount : -item.amount));
  }

  double getTotalIncome() {
    return _box.values.where((tx) => tx.type == TransactionType.income).fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalExpense() {
    return _box.values.where((tx) => tx.type == TransactionType.expense).fold(0.0, (sum, item) => sum + item.amount);
  }
}