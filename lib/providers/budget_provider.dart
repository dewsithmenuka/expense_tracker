import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/budget_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetService _service;
  BudgetProvider({required BudgetService service}) : _service = service;

  String userId = '';
  double? monthlyBudget; // null = no budget set
  StreamSubscription<double?>? _sub;

  /// Follows the logged-in user (called by ChangeNotifierProxyProvider,
  /// during a build, so no notifyListeners() here).
  void setUser(String? uid) {
    final id = uid ?? '';
    if (id == userId) return;
    userId = id;
    _sub?.cancel();
    _sub = null;
    monthlyBudget = null;
    if (id.isEmpty) return;

    _sub = _service.streamBudget(id).listen(
      (value) {
        monthlyBudget = value;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  /// Returns null on success, or an error message.
  Future<String?> setBudget(double? value) async {
    if (userId.isEmpty) return 'You are not signed in.';
    try {
      await _service
          .setBudget(userId, value)
          .timeout(const Duration(seconds: 8));
      return null;
    } on TimeoutException {
      return null; // offline: Firestore keeps it queued and syncs later
    } catch (_) {
      return 'Could not save the budget. Please try again.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}