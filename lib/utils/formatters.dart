import 'package:flutter/widgets.dart' show BuildContext;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class Fmt {
  static final NumberFormat _money = NumberFormat('#,##0.00');

  /// "$1,250.00" or "CHF 1,250.00" (multi-letter symbols get a space).
  static String format(double value, String symbol) {
    final gap = symbol.length > 1 ? ' ' : '';
    return '$symbol$gap${_money.format(value)}';
  }

  static String monthName(DateTime d) => DateFormat('MMMM').format(d);

  static String monthYearShort(DateTime d) => DateFormat('MMM yyyy').format(d);

  /// "October" for the current year, "October 2025" for other years.
  static String monthLabel(DateTime d) => d.year == DateTime.now().year
      ? DateFormat('MMMM').format(d)
      : DateFormat('MMMM yyyy').format(d);

  static String monthYearLong(DateTime d) => DateFormat('MMMM yyyy').format(d);

  /// "Today", "Yesterday", or "Mon, 5 Oct".
  static String dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final day = DateTime.utc(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(d);
  }
    /// The user's chosen currency symbol (listens, so widgets refresh on change).
  static String symbolOf(BuildContext context) =>
      Provider.of<SettingsProvider>(context).currencySymbol;
}

/// Use inside build methods: `context.money(1234.5)`.
/// It listens to SettingsProvider, so the widget refreshes when the
/// currency changes.
extension MoneyContext on BuildContext {
  String money(double value) =>
      Fmt.format(value, Provider.of<SettingsProvider>(this).currencySymbol);
}