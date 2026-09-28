import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/expense.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _db.collection('expenses');

  /// Live stream of a user's expenses, newest first.
  Stream<List<Expense>> streamExpenses(String userId) {
    return _expenses
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      // Sorted here (not in the query) so no Firestore index is needed.
      final list = snap.docs.map(Expense.fromDocument).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addExpense(Expense expense) async {
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    await _expenses.doc(id).set(expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenses.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expenses.doc(expenseId).delete();
  }

  Future<Expense?> getExpense(String expenseId) async {
    final doc = await _expenses.doc(expenseId).get();
    if (!doc.exists) return null;
    return Expense.fromDocument(doc);
  }
    /// Writes many expenses at once (demo-data generator).
  /// A Firestore batch is limited to 500 operations, so we send 400 at a time.
  Future<void> addExpensesBatch(List<Expense> expenses) async {
    for (var i = 0; i < expenses.length; i += 400) {
      final batch = _db.batch();
      for (final e in expenses.skip(i).take(400)) {
        final id = e.id.isEmpty ? _uuid.v4() : e.id;
        batch.set(_expenses.doc(id), e.toMap());
      }
      await batch.commit();
    }
  }

  Future<void> deleteExpensesBatch(List<String> ids) async {
    for (var i = 0; i < ids.length; i += 400) {
      final batch = _db.batch();
      for (final id in ids.skip(i).take(400)) {
        batch.delete(_expenses.doc(id));
      }
      await batch.commit();
    }
  }

  /// Sets (or clears, with null) the card on many expenses at once.
  Future<void> setCardForExpenses(List<String> ids, String? cardId) async {
    for (var i = 0; i < ids.length; i += 400) {
      final batch = _db.batch();
      for (final id in ids.skip(i).take(400)) {
        batch.update(_expenses.doc(id), {'cardId': cardId});
      }
      await batch.commit();
    }
  }
}