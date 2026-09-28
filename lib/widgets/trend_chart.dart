import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import 'section_card.dart';

class MonthlyTrendCard extends StatelessWidget {
  const MonthlyTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final months = p.lastMonthsTotals(6);
    final maxValue =
        months.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final selected = p.selectedMonth;

    bool isSelected(DateTime m) =>
        m.year == selected.year && m.month == selected.month;

    return SectionCard(
      title: 'Last 6 months',
      subtitle: 'Tap a bar to jump to that month',
      icon: Icons.bar_chart_rounded,
      child: maxValue <= 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No spending recorded in the last 6 months.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.25,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final sel = isSelected(months[i].key);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM').format(months[i].key),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    sel ? FontWeight.bold : FontWeight.normal,
                                color: sel ? scheme.primary : scheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      // Only react to a finished tap, not to every finger move.
                      if (event is! FlTapUpEvent) return;
                      final i = response?.spot?.touchedBarGroupIndex;
                      if (i == null || i < 0 || i >= months.length) return;
                      context.read<ExpenseProvider>().setSelectedMonth(months[i].key);
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${DateFormat('MMM').format(months[groupIndex].key)}\n'
                          '${context.money(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: months[i].value,
                            width: 24,
                            color: isSelected(months[i].key)
                                ? scheme.primary
                                : scheme.primary.withAlpha(90),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}