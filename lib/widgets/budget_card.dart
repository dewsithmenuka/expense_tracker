import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';
import 'profile_dialogs.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = context.watch<BudgetProvider>().monthlyBudget;
    final p = context.watch<ExpenseProvider>();
    final spent = p.monthTotal;

    // ---- No budget yet: gentle prompt ----
    if (budget == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Material(
          color: AppColors.tile(context),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => showBudgetDialog(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.savings_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set a monthly budget',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Get alerts before you overspend',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ---- Budget set: progress ----
    final ratio = spent / budget;
    final color = ratio >= 1
        ? theme.colorScheme.error
        : ratio >= 0.8
            ? Colors.orange
            : theme.colorScheme.primary;
    final left = budget - spent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Material(
        color: AppColors.tile(context),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showBudgetDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('${Fmt.monthLabel(p.selectedMonth)} budget',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${(ratio * 100).round()}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0).toDouble(),
                    minHeight: 10,
                    backgroundColor: color.withAlpha(35),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${context.money(spent)} of ${context.money(budget)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      left >= 0
                          ? '${context.money(left)} left'
                          : 'Over by ${context.money(-left)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}