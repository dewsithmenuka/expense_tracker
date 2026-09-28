import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../utils/formatters.dart';

class NotificationProvider extends ChangeNotifier {
  static const _kRemOn = 'reminder_on';
  static const _kRemH = 'reminder_hour';
  static const _kRemM = 'reminder_minute';
  static const _kBudgetOn = 'budget_alerts_on';
  static const _kLevelPrefix = 'budget_level_';

  final SharedPreferences _prefs;
  final NotificationService _service;

  bool reminderEnabled;
  TimeOfDay reminderTime;
  bool budgetAlertsEnabled;

  NotificationProvider(this._prefs, this._service)
      : reminderEnabled = _prefs.getBool(_kRemOn) ?? false,
        reminderTime = TimeOfDay(
          hour: _prefs.getInt(_kRemH) ?? 20,
          minute: _prefs.getInt(_kRemM) ?? 0,
        ),
        budgetAlertsEnabled = _prefs.getBool(_kBudgetOn) ?? true {
    // Re-register the daily reminder on every app start (harmless: same id).
    if (reminderEnabled) _service.scheduleDailyReminder(reminderTime);
  }

  Future<bool> ensurePermission() => _service.requestPermission();

  /// Returns false if the user refused the notification permission.
  Future<bool> setReminderEnabled(bool on) async {
    if (on) {
      if (!await _service.requestPermission()) return false;
      await _service.scheduleDailyReminder(reminderTime);
    } else {
      await _service.cancelReminder();
    }
    reminderEnabled = on;
    await _prefs.setBool(_kRemOn, on);
    notifyListeners();
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    reminderTime = time;
    await _prefs.setInt(_kRemH, time.hour);
    await _prefs.setInt(_kRemM, time.minute);
    if (reminderEnabled) await _service.scheduleDailyReminder(time);
    notifyListeners();
  }

  Future<bool> setBudgetAlerts(bool on) async {
    if (on && !await _service.requestPermission()) return false;
    budgetAlertsEnabled = on;
    await _prefs.setBool(_kBudgetOn, on);
    notifyListeners();
    return true;
  }

  Future<void> sendTest() => _service.showNow(
        id: NotificationService.testId,
        title: 'Notifications are working 🎉',
        body: 'You will get reminders and budget alerts like this one.',
        channelId: 'daily_reminder',
        channelName: 'Daily reminder',
      );

  /// Call after an expense is saved. Fires at 80% and again at 100%.
  Future<void> checkBudget({
    required double spent,
    required double? budget,
    required String symbol,
  }) async {
    if (!budgetAlertsEnabled || budget == null || budget <= 0) return;

    final ratio = spent / budget;
    final level = ratio >= 1 ? 2 : (ratio >= 0.8 ? 1 : 0);
    if (level == 0) return;

    // The key includes the month AND the budget amount, so a new month or
    // a changed budget starts fresh.
    final now = DateTime.now();
    final key = '$_kLevelPrefix${now.year}_${now.month}_${budget.round()}';
    if ((_prefs.getInt(key) ?? 0) >= level) return; // already told them
    await _prefs.setInt(key, level);

    if (level == 2) {
      await _service.showNow(
        id: NotificationService.budgetOverId,
        title: 'Budget exceeded',
        body: "You've spent ${Fmt.format(spent, symbol)} of your "
            '${Fmt.format(budget, symbol)} monthly budget.',
      );
    } else {
      await _service.showNow(
        id: NotificationService.budgetWarnId,
        title: "You've used ${(ratio * 100).round()}% of your budget",
        body: '${Fmt.format(budget - spent, symbol)} left for the rest of the month.',
      );
    }
  }

  /// Used when the account is deleted.
  Future<void> resetAll() async {
    await _service.cancelAll();
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_kLevelPrefix))
        .toList()
      ..addAll([_kRemOn, _kRemH, _kRemM, _kBudgetOn]);
    for (final k in keys) {
      await _prefs.remove(k);
    }
    reminderEnabled = false;
    reminderTime = const TimeOfDay(hour: 20, minute: 0);
    budgetAlertsEnabled = true;
    notifyListeners();
  }
}