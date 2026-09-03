import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'history.dart';

/// A central class to handle all database interactions using Cloud Firestore.
/// This keeps the UI logic separate from data storage logic.
class TransactionRepository {
  static const String transactionsCol = 'transactions';
  static const String budgetsCol = 'budgets';
  static const String savingsGoalsCol = 'savings_goals';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  Stream<List<AppTransaction>> getTransactionsStream() {
    final userDoc = _userDoc;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection(transactionsCol).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AppTransaction.fromMap(doc.data(), doc.id)).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    });
  }

  Stream<List<Budget>> getBudgetsStream() {
    final userDoc = _userDoc;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection(budgetsCol).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Budget.fromMap(doc.data(), doc.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Stream<List<SavingsGoal>> getSavingsGoalsStream() {
    final userDoc = _userDoc;
    if (userDoc == null) return Stream.value([]);
    return userDoc.collection(savingsGoalsCol).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SavingsGoal.fromMap(doc.data(), doc.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> save(AppTransaction transaction) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.collection(transactionsCol).doc(transaction.id).set(transaction.toMap());
  }

  Future<void> update(AppTransaction transaction) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.collection(transactionsCol).doc(transaction.id).update(transaction.toMap());
  }

  Future<void> delete(AppTransaction transaction) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.collection(transactionsCol).doc(transaction.id).delete();
  }

  Future<void> saveBudget(Budget budget) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.collection(budgetsCol).doc(budget.id).set(budget.toMap());
  }

  Future<void> deleteBudget(Budget budget) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.collection(budgetsCol).doc(budget.id).delete();
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.collection(savingsGoalsCol).doc(goal.id).set(goal.toMap());
  }

  Future<void> deleteSavingsGoal(SavingsGoal goal) async {
    final userDoc = _userDoc;
    if (userDoc == null) return;
    await userDoc.collection(savingsGoalsCol).doc(goal.id).delete();
  }
}