import 'package:hive/hive.dart';
import 'history.dart';

/// A central class to handle all database interactions.
/// This keeps the UI logic separate from data storage logic (Separation of Concerns).
class TransactionRepository {
  static const String boxName = 'transactions';

  /// Registers adapters and opens the Hive box. Called once in main.dart.
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(TransactionTypeAdapter());
    await Hive.openBox<Transaction>(boxName);
  }

  /// Getter for the opened Hive box.
  Box<Transaction> get _box => Hive.box<Transaction>(boxName);

  List<Transaction> getAll() {
    return _box.values.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
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