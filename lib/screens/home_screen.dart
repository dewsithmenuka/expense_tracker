import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import '../widgets/budget_card.dart';
import '../widgets/expense_tile.dart';
import '../widgets/filter_bar.dart';
import '../widgets/state_views.dart';
import '../widgets/summary_header.dart';
import 'expense_form_screen.dart';
import '../widgets/cards_strip.dart';

/// A date heading in the list, with that day's total.
class _DayHeader {
  final DateTime day;
  final double total;
  const _DayHeader(this.day, this.total);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openForm(BuildContext context, [Expense? expense]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: expense)),
    );
  }

  /// Deletes right away and offers Undo for 5 seconds.
  void _deleteWithUndo(BuildContext context, Expense expense) {
    final provider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);

    provider.deleteExpense(expense.id).catchError((_) {
      messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't delete the expense. It was restored."),
      ));
    });

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Text('"${expense.title}" deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            // Re-saving with the SAME id brings the expense back
            onPressed: () => provider.addExpense(expense),
          ),
        ),
      );
  }

  /// Turns a flat expense list into: header, expense, expense, header, ...
  List<Object> _buildItems(List<Expense> expenses) {
    final totals = <DateTime, double>{};
    for (final e in expenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      totals[day] = (totals[day] ?? 0) + e.amount;
    }

    final items = <Object>[];
    DateTime? lastDay;
    for (final e in expenses) {
      final day = DateTime(e.date.year, e.date.month, e.date.day);
      if (day != lastDay) {
        items.add(_DayHeader(day, totals[day]!));
        lastDay = day;
      }
      items.add(e);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: switch (p.status) {
        LoadStatus.loading => const LoadingView(),
        LoadStatus.error => ErrorView(
            message: p.errorMessage ?? 'Unknown error',
            onRetry: p.retry,
          ),
        _ => _buildContent(context, p),
      },
    );
  }

  Widget _buildContent(BuildContext context, ExpenseProvider p) {
    final theme = Theme.of(context);
    final items = _buildItems(p.filteredExpenses);
    final noDataAtAll = p.status == LoadStatus.empty;

    return CustomScrollView(
      // Drag the list to close the keyboard.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        // 1. Gradient summary header + budget progress
        const SliverToBoxAdapter(child: SummaryHeader()),
        const SliverToBoxAdapter(child: BudgetCard()),
        const SliverToBoxAdapter(child: CardsStrip()),

        if (noDataAtAll)
          // 2a. Brand-new user: nothing to search or filter yet
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(onAdd: () => _openForm(context)),
          )
        else ...[
          // 2b. Title, search, chips and results summary
          const SliverToBoxAdapter(child: FilterBar()),

          if (items.isEmpty)
            // 3a. Nothing to show: filters found nothing, or this month is empty
            SliverFillRemaining(
              hasScrollBody: false,
              child: p.hasActiveFilters
                  ? NoResultsView(onClear: p.clearFilters)
                  : _NothingHere(
                      month: p.selectedMonth,
                      onAdd: () => _openForm(context),
                    ),
            )
          else
            // 3b. The grouped list
            SliverPadding(
              padding: const EdgeInsets.only(top: 4, bottom: 96), // room for the FAB
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];

                    if (item is _DayHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Fmt.dayLabel(item.day),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              context.money(item.total),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final expense = item as Expense;
                    return ExpenseTile(
                      expense: expense,
                      onTap: () => _openForm(context, expense),
                      onEdit: () => _openForm(context, expense),
                      onDelete: () => _deleteWithUndo(context, expense),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Shown when the selected month has no expenses (but other months do).
class _NothingHere extends StatelessWidget {
  final DateTime month;
  final VoidCallback onAdd;
  const _NothingHere({required this.month, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Nothing in ${Fmt.monthLabel(month)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('No expenses found here.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add an expense'),
            ),
          ],
        ),
      ),
    );
  }
}