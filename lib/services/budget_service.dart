import 'package:cloud_firestore/cloud_firestore.dart';

/// The budget lives in users/{uid}.monthlyBudget so it syncs across devices.
class BudgetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Stream<double?> streamBudget(String uid) => _doc(uid)
      .snapshots()
      .map((s) => (s.data()?['monthlyBudget'] as num?)?.toDouble());

  /// Pass null to remove the budget.
  Future<void> setBudget(String uid, double? value) => _doc(uid).set(
        {'monthlyBudget': value ?? FieldValue.delete()},
        SetOptions(merge: true),
      );
}