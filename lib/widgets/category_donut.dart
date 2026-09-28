import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';
import 'section_card.dart';

class CategoryDonutCard extends StatefulWidget {
  const CategoryDonutCard({super.key});

  @override
  State<CategoryDonutCard> createState() => _CategoryDonutCardState();
}

class _CategoryDonutCardState extends State<CategoryDonutCard> {
  int _touched = -1; // index of the slice under the finger, -1 = none

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
    final muted = theme.colorScheme.onSurfaceVariant;

    final total = p.monthTotal;

    final entries = p.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty || total <= 0) {
      return const SizedBox.shrink();
    }

    final touched = (_touched >= 0 && _touched < entries.length)
        ? entries[_touched]
        : null;

    return SectionCard(
      title: 'Spending by category',
      subtitle: 'Touch a slice to see the details',
      icon: Icons.donut_large,
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 3,
                    centerSpaceRadius: 70,
                    sections: [
                      for (var i = 0; i < entries.length; i++)
                        PieChartSectionData(
                          value: entries[i].value,
                          color: entries[i].key.color,
                          radius: i == _touched ? 44 : 36,
                          showTitle: false,
                        ),
                    ],
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        final index =
                            (!event.isInterestedForInteractions ||
                                    response?.touchedSection == null)
                                ? -1
                                : response!
                                    .touchedSection!
                                    .touchedSectionIndex;

                        if (index != _touched) {
                          setState(() => _touched = index);
                        }
                      },
                    ),
                  ),
                ),

                // Centre label.
                // IgnorePointer lets touches reach the chart.
                IgnorePointer(
                  child: SizedBox(
                    width: 120,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            touched == null
                                ? 'Total'
                                : _categoryLabel(touched.key),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                          Text(
                            context.money(touched?.value ?? total),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (touched != null)
                            Text(
                              '${(touched.value / total * 100).round()}% of total',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final e in entries)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: e.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_categoryLabel(e.key)} '
                      '${(e.value / total * 100).round()}%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

