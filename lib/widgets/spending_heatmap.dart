import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';
import 'section_card.dart';

/// Colour for a day: grey when nothing was spent, otherwise the theme colour
/// getting stronger as [ratio] (0..1) grows.
Color _heat(ColorScheme scheme, double ratio) {
  if (ratio <= 0) return Colors.grey.withAlpha(28);

  return scheme.primary.withAlpha((60 + 195 * ratio).round());
}

class SpendingHeatmapCard extends StatelessWidget {
  const SpendingHeatmapCard({super.key});

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Converts an enum value such as `foodAndDining`
  /// into a readable label such as `Food And Dining`.
  String _categoryLabel(dynamic category) {
    final name = category.toString().split('.').last;

    final result = name.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return result[0].toUpperCase() + result.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;

    final month = p.selectedMonth;
    final daily = p.dailyTotals;
    final days = p.daysInSelectedMonth;

    final maxDay = daily.values.fold<double>(
      0,
      (a, b) => a > b ? a : b,
    );

    // Monday = 0 ... Sunday = 6, so this is how many blank cells come first.
    final offset = DateTime(month.year, month.month, 1).weekday - 1;

    final rows = ((offset + days) / 7).ceil();

    final now = DateTime.now();

    return SectionCard(
      title: 'Spending calendar',
      subtitle: 'Darker days = more spent. Tap a day for details.',
      icon: Icons.calendar_month,
      child: Column(
        children: [
          Row(
            children: [
              for (final d in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          for (var r = 0; r < rows; r++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = r * 7 + c - offset + 1;

                        // Blank cell before the 1st / after the last day.
                        if (day < 1 || day > days) {
                          return const AspectRatio(
                            aspectRatio: 1,
                          );
                        }

                        final total = daily[day] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.all(2),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _DayCell(
                              day: day,
                              color: _heat(
                                scheme,
                                maxDay == 0 ? 0 : total / maxDay,
                              ),
                              isToday:
                                  p.isCurrentMonth && day == now.day,
                              isFuture:
                                  p.isCurrentMonth && day > now.day,
                              onTap: total > 0
                                  ? () => _showDaySheet(context, day)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 12),

          // Legend: Less [] [] [] [] More
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: muted,
                ),
              ),
              const SizedBox(width: 6),
              for (final r in const [0.0, 0.25, 0.5, 0.75, 1.0])
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: _heat(scheme, r),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 2),
              Text(
                'More',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final Color color;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.color,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // White text on strong colours, normal text on pale ones.
    final strong = color.a > 0.6;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(
                color: scheme.primary,
                width: 2,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Material(
          color: color,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                  color: strong
                      ? Colors.white
                      : scheme.onSurface.withAlpha(
                          isFuture ? 90 : 220,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing everything spent on one day.
void _showDaySheet(BuildContext context, int day) {
  final p = context.read<ExpenseProvider>();

  final list = p.monthExpenses
      .where((e) => e.date.day == day)
      .toList();

  final date = DateTime(
    p.selectedMonth.year,
    p.selectedMonth.month,
    day,
  );

  final total = list.fold<double>(
    0,
    (sum, e) => sum + e.amount,
  );

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMMM').format(date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      ctx.money(total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final e in list)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              e.category.color.withAlpha(40),
                          child: Icon(
                            _categoryIcon(e.category),
                            color: e.category.color,
                          ),
                        ),
                        title: Text(e.title),
                        subtitle: Text(
                          _categoryLabel(e.category),
                        ),
                        trailing: Text(
                          ctx.money(e.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Returns an icon for each category.
///
/// This avoids relying on an `icon` getter that does not currently
/// exist on ExpenseCategory.
IconData _categoryIcon(dynamic category) {
  final name = category.toString().split('.').last.toLowerCase();

  switch (name) {
    case 'food':
    case 'foodanddining':
    case 'restaurant':
      return Icons.restaurant;

    case 'transport':
    case 'transportation':
      return Icons.directions_car;

    case 'shopping':
      return Icons.shopping_bag;

    case 'entertainment':
      return Icons.movie;

    case 'bills':
    case 'utilities':
      return Icons.receipt_long;

    case 'health':
      return Icons.health_and_safety;

    case 'education':
      return Icons.school;

    case 'travel':
      return Icons.flight;

    case 'salary':
    case 'income':
      return Icons.account_balance_wallet;

    default:
      return Icons.category;
  }
}

/// Converts an enum value such as `foodAndDining`
/// into a readable label such as `Food And Dining`.
String _categoryLabel(dynamic category) {
  final name = category.toString().split('.').last;

  final result = name.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );

  return result[0].toUpperCase() + result.substring(1);
}

