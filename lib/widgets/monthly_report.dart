import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';

// ---------------------------------------------------------------------------
// Month picker bottom sheet
// ---------------------------------------------------------------------------

Future<void> showMonthPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _MonthPickerSheet(),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet();

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = context.read<ExpenseProvider>().selectedMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final now = DateTime.now();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _year > p.firstYear ? () => setState(() => _year--) : null,
                ),
                Text('$_year',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _year < now.year ? () => setState(() => _year++) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                for (var m = 1; m <= 12; m++)
                  _MonthCell(
                    label: DateFormat('MMM').format(DateTime(_year, m)),
                    enabled: !DateTime(_year, m)
                        .isAfter(DateTime(now.year, now.month)),
                    selected: p.selectedMonth.year == _year &&
                        p.selectedMonth.month == m,
                    hasData: p.hasDataIn(_year, m),
                    onTap: () {
                      p.setSelectedMonth(DateTime(_year, m));
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 6),
                Text('Has expenses', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool selected;
  final bool hasData;
  final VoidCallback onTap;

  const _MonthCell({
    required this.label,
    required this.enabled,
    required this.selected,
    required this.hasData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected
        ? scheme.onPrimary
        : enabled
            ? scheme.onSurface
            : scheme.onSurface.withAlpha(90);

    return Material(
      color: selected ? scheme.primary : Colors.grey.withAlpha(30),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasData
                      ? (selected ? scheme.onPrimary : scheme.primary)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly report card (Profile tab)
// ---------------------------------------------------------------------------

class MonthlyReportCard extends StatelessWidget {
  final VoidCallback onViewExpenses;
  const MonthlyReportCard({super.key, required this.onViewExpenses});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final total = p.monthTotal;
    final change = p.monthChangePercent;
    final biggest = p.biggestExpense;
    final cats = p.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tile(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Month selector ----
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: p.previousMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showMonthPicker(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          Fmt.monthYearLong(p.selectedMonth),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: p.canGoNext ? p.nextMonth : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ---- Total + change ----
          Text('Total spent',
              style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          Text(
            context.money(total),
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (change != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    change >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: change >= 0 ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${change.abs().toStringAsFixed(0)}% '
                    '${change >= 0 ? 'more' : 'less'} than '
                    '${Fmt.monthName(p.previousMonthDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          if (p.monthCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.event_busy_outlined,
                        size: 40, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text('No expenses in ${Fmt.monthLabel(p.selectedMonth)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: muted)),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.receipt_long,
                    label: 'Transactions',
                    value: '${p.monthCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.show_chart,
                    label: 'Daily average',
                    value: context.money(p.dailyAverage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.event_available,
                    label: 'Active days',
                    value: '${p.activeDays}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.arrow_upward,
                    label: 'Biggest expense',
                    value: biggest == null ? '—' : context.money(biggest.amount),
                    sub: biggest?.title,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('By category',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            for (final e in cats)
              _CategoryRow(
                category: e.key,
                amount: e.value,
                share: total == 0 ? 0 : e.value / total,
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onViewExpenses,
                icon: const Icon(Icons.list_alt),
                label: Text('View ${Fmt.monthLabel(p.selectedMonth)} expenses'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          if (sub != null)
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: muted, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double share; // 0..1

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.share,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = category.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withAlpha(40),
                child: Icon(category.icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(category.label)),
              Text(context.money(amount),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                width: 44,
                child: Text(
                  '${(share * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              backgroundColor: color.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}