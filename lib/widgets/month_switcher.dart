import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import 'monthly_report.dart';

/// "‹ Oct 2025 ›" pill: arrows change month, tapping the label opens the picker.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: p.previousMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
            iconSize: 22,
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          InkWell(
            onTap: () => showMonthPicker(context),
            child: Text(
              Fmt.monthYearShort(p.selectedMonth),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: p.canGoNext ? p.nextMonth : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
            iconSize: 22,
            disabledColor: Colors.white38,
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }
}