import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';

/// "5 Oct – 12 Oct", or with the year when it isn't the current year.
String _rangeLabel(DateTimeRange r) {
  final now = DateTime.now();
  final sameYear = r.start.year == now.year && r.end.year == now.year;
  final f = DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy');
  final a = f.format(r.start);
  final b = f.format(r.end);
  return a == b ? a : '$a – $b';
}

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If the provider already holds a query, show it in the field.
    _controller.text = context.read<ExpenseProvider>().searchQuery;
    _controller.addListener(_refresh);
  }

  // Rebuild whenever the text changes, so the little "x" button
  // appears and disappears correctly.
  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  // ---------------- Date range ----------------

  Widget _option(BuildContext ctx, IconData icon, String label, String value,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  Future<void> _pickDate() async {
    final p = context.read<ExpenseProvider>();

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _option(ctx, Icons.view_week_outlined, 'Last 7 days', 'week'),
            _option(ctx, Icons.date_range_outlined, 'Last 30 days', 'days30'),
            _option(ctx, Icons.calendar_today_outlined, 'This month', 'thisMonth'),
            _option(ctx, Icons.history, 'Last month', 'lastMonth'),
            _option(ctx, Icons.edit_calendar_outlined, 'Custom range…', 'custom'),
            if (p.filterDateRange != null)
              _option(ctx, Icons.close, 'Clear date filter', 'clear',
                  color: Theme.of(ctx).colorScheme.error),
          ],
        ),
      ),
    );

    // The sheet was closed with an await, so make sure we're still on screen.
    if (choice == null || !mounted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTimeRange? range;

    switch (choice) {
      case 'week':
        range = DateTimeRange(
          start: DateTime(today.year, today.month, today.day - 6),
          end: today,
        );
      case 'days30':
        range = DateTimeRange(
          start: DateTime(today.year, today.month, today.day - 29),
          end: today,
        );
      case 'thisMonth':
        range = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: today,
        );
      case 'lastMonth':
        range = DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0), // day 0 = last day of prev month
        );
      case 'custom':
        range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: today,
          initialDateRange: p.filterDateRange,
          helpText: 'Filter by date',
        );
      case 'clear':
        p.setFilterDateRange(null);
        return;
    }

    if (range != null) p.setFilterDateRange(range);
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // If the filters were cleared from outside (the "Clear all" button, or
    // switching account), empty the text field to match.
    if (p.searchQuery.isEmpty && _controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.clear();
      });
    }

    final results = p.filteredExpenses;
    final count = results.length;
    final total = results.fold<double>(0, (sum, e) => sum + e.amount);
    final active = p.hasActiveFilters;
    final range = p.filterDateRange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Title ----
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            'Expense history',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        // ---- Search field ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _controller,
            onChanged: p.setSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search title or note (all months)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        p.setSearchQuery('');
                      },
                    ),
              filled: true,
              fillColor: AppColors.tile(context),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ---- Chips: date + categories (scrolls sideways) ----
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Date chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InputChip(
                  avatar: Icon(
                    Icons.date_range,
                    size: 18,
                    color: range != null ? scheme.primary : null,
                  ),
                  label: Text(range == null ? 'Any date' : _rangeLabel(range)),
                  selected: range != null,
                  showCheckmark: false,
                  selectedColor: scheme.primaryContainer,
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _pickDate();
                  },
                  onDeleted:
                      range == null ? null : () => p.setFilterDateRange(null),
                ),
              ),

              // "All" chip
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: p.filterCategory == null,
                  showCheckmark: false,
                  selectedColor: scheme.primaryContainer,
                  onSelected: (_) {
                    FocusScope.of(context).unfocus();
                    p.setFilterCategory(null);
                  },
                ),
              ),

              // One chip per category, tinted with its colour
              for (final c in ExpenseCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      c.icon,
                      size: 18,
                      color: p.filterCategory == c ? c.color : null,
                    ),
                    label: Text(c.label),
                    selected: p.filterCategory == c,
                    showCheckmark: false,
                    selectedColor: c.color.withAlpha(45),
                    side: p.filterCategory == c
                        ? BorderSide(color: c.color)
                        : null,
                    onSelected: (selected) {
                      FocusScope.of(context).unfocus();
                      // Tapping the selected chip again removes the filter.
                      p.setFilterCategory(selected ? c : null);
                    },
                  ),
                ),
            ],
          ),
        ),

        // ---- Results summary ----
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active
                          ? '$count ${count == 1 ? 'result' : 'results'} · ${context.money(total)}'
                          : '$count ${count == 1 ? 'expense' : 'expenses'} in ${Fmt.monthLabel(p.selectedMonth)}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (active)
                      Text(
                        p.filtersSpanAllMonths
                            ? 'Across all months'
                            : 'In ${Fmt.monthLabel(p.selectedMonth)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              if (active)
                TextButton.icon(
                  onPressed: p.clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: const Text('Clear all'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}