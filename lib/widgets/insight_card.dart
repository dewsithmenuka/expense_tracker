import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import '../utils/insights.dart';
import 'section_card.dart';

class SmartInsightsCard extends StatelessWidget {
  const SmartInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final budget = context.watch<BudgetProvider>().monthlyBudget;
    final theme = Theme.of(context);
    final month = Fmt.monthLabel(p.selectedMonth);

    final insights = buildInsights(
      p,
      money: (v) => context.money(v),
      budget: budget,
    );

    return SectionCard(
      title: 'Smart insights',
      subtitle: 'Based on your $month spending',
      icon: Icons.lightbulb_outline,
      iconColor: Colors.amber.shade700,
      child: insights.isEmpty
          ? Text(
              'No expenses in $month yet. Add some and your insights will appear here.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          : Column(
              children: [
                for (final i in insights)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: i.color.withAlpha(35),
                          child: Icon(i.icon, size: 18, color: i.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(i.text, style: theme.textTheme.bodyMedium),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}