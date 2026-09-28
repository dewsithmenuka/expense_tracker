import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'app_style.dart';
import 'formatters.dart';

class Insight {
  final IconData icon;
  final Color color;
  final String text;
  const Insight(this.icon, this.color, this.text);
}

/// Looks at the selected month and returns up to 5 short observations.
/// [money] formats amounts in the user's currency.
List<Insight> buildInsights(
  ExpenseProvider p, {
  required String Function(double) money,
  double? budget,
}) {
  final out = <Insight>[];
  if (p.monthCount == 0) return out;

  final total = p.monthTotal;
  final prevName = Fmt.monthName(p.previousMonthDate);
  // For the current month we compare the same days, so say so.
  final vs = p.isCurrentMonth ? 'the same days of $prevName' : prevName;

  // 1. Projection: where this month is heading (current month only)
  if (p.isCurrentMonth) {
    final today = DateTime.now().day;
    final days = p.daysInSelectedMonth;
    if (today >= 3 && today < days) {
      final projected = total / today * days;
      var text = "At this pace you'll spend about ${money(projected)} by month end";
      Color color = Colors.teal;
      IconData icon = Icons.speed;

      if (budget != null && budget > 0) {
        if (projected > budget) {
          text += ', which is ${money(projected - budget)} over your budget.';
          color = Colors.red;
          icon = Icons.warning_amber_rounded;
        } else {
          text += ', within your ${money(budget)} budget.';
          color = Colors.green;
          icon = Icons.check_circle_outline;
        }
      } else {
        text += '.';
      }
      out.add(Insight(icon, color, text));
    }
  }

  // 2. Overall change vs the previous month
  final change = p.monthChangePercent;
  if (change != null && change.abs() >= 1) {
    final up = change > 0;
    out.add(Insight(
      up ? Icons.trending_up : Icons.trending_down,
      up ? Colors.orange : Colors.green,
      'You spent ${change.abs().round()}% ${up ? 'more' : 'less'} than $vs.',
    ));
  }

  // 3. The category that changed the most (must be a meaningful change)
  final now = p.byCategory;
  final before = p.previousPeriodByCategory;
  ExpenseCategory? moverCat;
  double moverDiff = 0;
  for (final e in now.entries) {
    final prev = before[e.key] ?? 0;
    if (prev <= 0) continue;
    final diff = e.value - prev;
    // Ignore small wiggles: need 20% change AND 5% of the month's total.
    if (diff.abs() / prev < 0.2 || diff.abs() < total * 0.05) continue;
    if (moverCat == null || diff.abs() > moverDiff.abs()) {
      moverCat = e.key;
      moverDiff = diff;
    }
  }
  if (moverCat != null) {
    final up = moverDiff > 0;
    final pct = (moverDiff.abs() / before[moverCat]! * 100).round();
    out.add(Insight(
      moverCat.icon,
      moverCat.color,
      '${moverCat.label} is ${up ? 'up' : 'down'} $pct% '
      '(${money(moverDiff.abs())} ${up ? 'more' : 'less'}) compared with $vs.',
    ));
  }

  // 4. Which category takes the biggest slice
  final top = p.topCategory;
  if (top != null && now.length > 1) {
    final share = (top.value / total * 100).round();
    out.add(Insight(
      top.key.icon,
      top.key.color,
      '${top.key.label} takes $share% of your spending (${money(top.value)}).',
    ));
  }

  // 5. The priciest day
  final daily = p.dailyTotals;
  if (daily.length >= 2) {
    final peak = daily.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final date = DateTime(p.selectedMonth.year, p.selectedMonth.month, peak.key);
    out.add(Insight(
      Icons.local_fire_department_outlined,
      Colors.deepOrange,
      'Your priciest day was ${DateFormat('EEEE, d MMM').format(date)}: '
      '${money(peak.value)}.',
    ));
  }

  // 6. Weekend vs weekday spending per day
  final y = p.selectedMonth.year;
  final m = p.selectedMonth.month;
  final lastDay = p.isCurrentMonth ? DateTime.now().day : p.daysInSelectedMonth;
  var weekendDays = 0, weekdayDays = 0;
  var weekendSum = 0.0, weekdaySum = 0.0;
  for (var d = 1; d <= lastDay; d++) {
    final spent = daily[d] ?? 0;
    if (DateTime(y, m, d).weekday >= DateTime.saturday) {
      weekendDays++;
      weekendSum += spent;
    } else {
      weekdayDays++;
      weekdaySum += spent;
    }
  }
  if (weekendDays >= 2 && weekdayDays >= 3) {
    final weekendAvg = weekendSum / weekendDays;
    final weekdayAvg = weekdaySum / weekdayDays;
    if (weekendAvg > 0 && weekdayAvg > 0) {
      final ratio = weekendAvg / weekdayAvg;
      if (ratio >= 1.25) {
        out.add(Insight(
          Icons.weekend_outlined,
          Colors.purple,
          'You spend ${((ratio - 1) * 100).round()}% more per day on weekends.',
        ));
      } else if (ratio <= 0.8) {
        out.add(Insight(
          Icons.work_outline,
          Colors.blue,
          'Weekdays cost you ${((1 / ratio - 1) * 100).round()}% more per day '
          'than weekends.',
        ));
      }
    }
  }

  return out.take(5).toList();
}