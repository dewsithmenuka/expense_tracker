import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../utils/demo_data.dart';

enum LoadStatus { loading, loaded, error, empty }

class ExpenseProvider extends ChangeNotifier {
  final FirestoreService _service;

  /// Signed-in user's uid ('' when signed out). Changed via [setUser].
  String userId = '';

  ExpenseProvider({required FirestoreService service})
      : _service = service;

  StreamSubscription<List<Expense>>? _subscription;

  List<Expense> _allExpenses = [];

  LoadStatus status = LoadStatus.loading;

  String? errorMessage;

  /// The month shown on Home and in the Profile report (always day 1).
  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // Filter state (Phase 5)
  ExpenseCategory? filterCategory;
  DateTimeRange? filterDateRange;
  String searchQuery = '';

  /// Called by ChangeNotifierProxyProvider whenever the login changes.
  ///
  /// It runs during a widget build, so it must NOT call notifyListeners();
  /// the stream's first event notifies the UI a moment later instead.
  void setUser(String? uid) {
    final newId = uid ?? '';

    if (newId == userId) return;

    userId = newId;

    _subscription?.cancel();
    _subscription = null;

    _allExpenses = [];
    errorMessage = null;

    filterCategory = null;
    filterDateRange = null;
    searchQuery = '';

    final now = DateTime.now();
    selectedMonth = DateTime(now.year, now.month);

    if (newId.isEmpty) {
      status = LoadStatus.empty;
      return;
    }

    _subscribe();
  }

  void _subscribe() {
    status = LoadStatus.loading;

    _subscription = _service.streamExpenses(userId).listen(
      (expenses) {
        _allExpenses = expenses;

        status = expenses.isEmpty
            ? LoadStatus.empty
            : LoadStatus.loaded;

        errorMessage = null;

        notifyListeners();
      },
      onError: (err) {
        status = LoadStatus.error;
        errorMessage = err.toString();
        notifyListeners();
      },
    );
  }

  void retry() {
    _subscription?.cancel();

    if (userId.isNotEmpty) {
      _subscribe();
    }

    notifyListeners();
  }

  List<Expense> get allExpenses => _allExpenses;

  // ---------- Month selection ----------

  bool get isCurrentMonth {
    final n = DateTime.now();

    return selectedMonth.year == n.year &&
        selectedMonth.month == n.month;
  }

  bool get canGoNext => selectedMonth.isBefore(
        DateTime(
          DateTime.now().year,
          DateTime.now().month,
        ),
      );

  void setSelectedMonth(DateTime m) {
    selectedMonth = DateTime(m.year, m.month);
    notifyListeners();
  }

  void previousMonth() => setSelectedMonth(
        DateTime(
          selectedMonth.year,
          selectedMonth.month - 1,
        ),
      );

  void nextMonth() {
    if (canGoNext) {
      setSelectedMonth(
        DateTime(
          selectedMonth.year,
          selectedMonth.month + 1,
        ),
      );
    }
  }

  bool hasDataIn(int year, int month) => _allExpenses.any(
        (e) =>
            e.date.year == year &&
            e.date.month == month,
      );

  int get firstYear {
    if (_allExpenses.isEmpty) {
      return DateTime.now().year;
    }

    return _allExpenses
        .map((e) => e.date.year)
        .reduce((a, b) => a < b ? a : b);
  }

  // ---------- Numbers for the selected month ----------

  List<Expense> _inMonth(DateTime m) => _allExpenses
      .where(
        (e) =>
            e.date.year == m.year &&
            e.date.month == m.month,
      )
      .toList();

  List<Expense> get monthExpenses => _inMonth(selectedMonth);

  double get monthTotal => monthExpenses.fold(
        0.0,
        (sum, e) => sum + e.amount,
      );

  /// Total for the real calendar month (ignores the month picker).
  double get thisMonthTotal {
    final now = DateTime.now();

    return _inMonth(
      DateTime(now.year, now.month),
    ).fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
  }

  DateTime get previousMonthDate => DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );

  double get previousMonthTotal =>
      _inMonth(previousMonthDate).fold(
        0.0,
        (sum, e) => sum + e.amount,
      );

  /// null when the previous month has no data to compare with.
  /// Uses the SAME span of days, so a half-finished month is compared
  /// fairly (see previousPeriodTotal).
  double? get monthChangePercent {
    final prev = previousPeriodTotal;

    if (prev == 0) return null;

    return (monthTotal - prev) / prev * 100;
  }

  int get monthCount => monthExpenses.length;

  int get activeDays =>
      monthExpenses.map((e) => e.date.day).toSet().length;

  double get dailyAverage {
    final days = isCurrentMonth
        ? DateTime.now().day
        : DateTime(
            selectedMonth.year,
            selectedMonth.month + 1,
            0,
          ).day;

    return monthTotal / days;
  }

  Map<ExpenseCategory, double> get byCategory {
    final map = <ExpenseCategory, double>{};

    for (final e in monthExpenses) {
      map[e.category] =
          (map[e.category] ?? 0) + e.amount;
    }

    return map;
  }

  MapEntry<ExpenseCategory, double>? get topCategory {
    final map = byCategory;

    if (map.isEmpty) return null;

    return map.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
  }

  Expense? get biggestExpense {
    final list = monthExpenses;

    if (list.isEmpty) return null;

    return list.reduce(
      (a, b) => a.amount >= b.amount ? a : b,
    );
  }

  // ---------- Extra numbers for the Insights tab ----------

  /// Previous month's expenses over the SAME days as the selected month
  /// so far. Comparing a half-finished month with a whole one would
  /// always look like "you spent less".
  List<Expense> get _previousPeriodExpenses {
    final list = _inMonth(previousMonthDate);

    if (!isCurrentMonth) return list;

    final today = DateTime.now().day;

    return list.where((e) => e.date.day <= today).toList();
  }

  double get previousPeriodTotal =>
      _previousPeriodExpenses.fold(
        0.0,
        (sum, e) => sum + e.amount,
      );

  Map<ExpenseCategory, double> get previousPeriodByCategory {
    final map = <ExpenseCategory, double>{};

    for (final e in _previousPeriodExpenses) {
      map[e.category] =
          (map[e.category] ?? 0) + e.amount;
    }

    return map;
  }

  /// day-of-month -> total spent that day (selected month).
  Map<int, double> get dailyTotals {
    final map = <int, double>{};

    for (final e in monthExpenses) {
      map[e.date.day] =
          (map[e.date.day] ?? 0) + e.amount;
    }

    return map;
  }

  int get daysInSelectedMonth =>
      DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
        0,
      ).day;

  /// Totals for the last [count] calendar months, oldest first, ending
  /// at the REAL current month (so the bar chart doesn't shift around
  /// when you pick another month).
  List<MapEntry<DateTime, double>> lastMonthsTotals(int count) {
    final now = DateTime.now();

    return List.generate(count, (i) {
      final m = DateTime(
        now.year,
        now.month - (count - 1 - i),
      );

      final total = _inMonth(m).fold(
        0.0,
        (sum, e) => sum + e.amount,
      );

      return MapEntry(m, total);
    });
  }

  // ---------- Filters ----------

  /// Shows the selected month, unless the user searches or picks a
  /// custom date range - then we look across ALL expenses.
  List<Expense> get filteredExpenses {
    final searching = searchQuery.trim().isNotEmpty;

    final base =
        (filterDateRange == null && !searching)
            ? monthExpenses
            : _allExpenses;

    return base.where((e) {
      if (filterCategory != null &&
          e.category != filterCategory) {
        return false;
      }

      if (filterDateRange != null) {
        final start = filterDateRange!.start;

        final endExclusive = DateTime(
          filterDateRange!.end.year,
          filterDateRange!.end.month,
          filterDateRange!.end.day + 1,
        );

        if (e.date.isBefore(start) ||
            !e.date.isBefore(endExclusive)) {
          return false;
        }
      }

      if (searching) {
        final q = searchQuery.toLowerCase();

        final inTitle =
            e.title.toLowerCase().contains(q);

        final inNote =
            (e.note ?? '').toLowerCase().contains(q);

        if (!inTitle && !inNote) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// True when any search text, category or date range is applied.
  bool get hasActiveFilters =>
      filterCategory != null ||
      filterDateRange != null ||
      searchQuery.trim().isNotEmpty;

  /// Search and date-range look across ALL months, while a category
  /// filter on its own stays inside the selected month.
  /// The UI uses this to explain what the user is looking at.
  bool get filtersSpanAllMonths =>
      filterDateRange != null ||
      searchQuery.trim().isNotEmpty;

  void setFilterCategory(ExpenseCategory? category) {
    filterCategory = category;
    notifyListeners();
  }

  void setFilterDateRange(DateTimeRange? range) {
    filterDateRange = range;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    filterCategory = null;
    filterDateRange = null;
    searchQuery = '';

    notifyListeners();
  }

  // ---------- Write operations ----------

  Future<void> addExpense(Expense expense) =>
      _service.addExpense(expense);

  Future<void> updateExpense(Expense expense) =>
      _service.updateExpense(expense);

  /// Optimistic delete: remove locally first, put it back if Firestore fails.
  Future<void> deleteExpense(String id) async {
    final index = _allExpenses.indexWhere(
      (e) => e.id == id,
    );

    if (index == -1) return;

    final removed = _allExpenses[index];

    _allExpenses = List.of(_allExpenses)
      ..removeAt(index);

    status = _allExpenses.isEmpty
        ? LoadStatus.empty
        : LoadStatus.loaded;

    notifyListeners();

    try {
      await _service
          .deleteExpense(id)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Offline: Firestore keeps the delete queued and syncs it later.
    } catch (_) {
      _allExpenses = [..._allExpenses, removed]
        ..sort(
          (a, b) => b.date.compareTo(a.date),
        );

      status = LoadStatus.loaded;

      notifyListeners();

      rethrow;
    }
  }
    // ---------- Bulk operations (demo data, card removal) ----------

  /// null = success, otherwise a message ready to show the user.
  Future<String?> _bulk(Future<void> Function() action) async {
    try {
      await action().timeout(const Duration(seconds: 20));
      return null;
    } on TimeoutException {
      return null; // offline: Firestore queues the writes and syncs later
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<String?> addManyExpenses(List<Expense> list) =>
      _bulk(() => _service.addExpensesBatch(list));

  bool get hasDemoData => _allExpenses.any((e) => e.id.startsWith(demoIdPrefix));

  Future<String?> removeDemoData() {
    final ids = _allExpenses
        .where((e) => e.id.startsWith(demoIdPrefix))
        .map((e) => e.id)
        .toList();
    if (ids.isEmpty) return Future.value(null);
    return _bulk(() => _service.deleteExpensesBatch(ids));
  }

  /// Called before a card is deleted: its expenses stay, but become
  /// "Cash / no card", so nothing points at a card that no longer exists.
  Future<String?> detachCard(String cardId) {
    final ids =
        _allExpenses.where((e) => e.cardId == cardId).map((e) => e.id).toList();
    if (ids.isEmpty) return Future.value(null);
    return _bulk(() => _service.setCardForExpenses(ids, null));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}