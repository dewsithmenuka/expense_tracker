import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';
import 'monthly_report.dart';

class SummaryHeader extends StatelessWidget {
  const SummaryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();

    final total = p.monthTotal;
    final top = p.topCategory;
    final change = p.monthChangePercent;

    final topShare =
        (top != null && total > 0) ? top.value / total * 100 : 0.0;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00897B),
            Color(0xFF004D40),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative translucent circles
          const Positioned(
            right: -50,
            top: -50,
            child: _Bubble(size: 180),
          ),
          const Positioned(
            left: -40,
            bottom: -60,
            child: _Bubble(size: 140),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Top row: title + month switcher ----
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Expenses',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),

                    const _MonthSwitcher(),
                  ],
                ),

                const SizedBox(height: 24),

                // ---- Total ----
                Text(
                  'Total spent in ${Fmt.monthLabel(p.selectedMonth)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                // ---- Total animation ----
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: total,
                  ),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.money(value),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (change != null) _ChangePill(percent: change),

                const SizedBox(height: 20),

                // ---- Category proportion bar + insight sentence ----
                if (top != null) ...[
                  _CategoryBar(data: p.byCategory),

                  const SizedBox(height: 10),

                  Text(
                    '${top.key.label} leads at ${context.money(top.value)} '
                    '· ${topShare.round()}% of your spending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],

                // ---- Three quick stats ----
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          icon: top?.key.icon ?? Icons.category_outlined,
                          value: top?.key.label ?? '—',
                          label: 'Top category',
                        ),
                      ),

                      const _StatDivider(),

                      Expanded(
                        child: _Stat(
                          icon: Icons.receipt_long,
                          value: '${p.monthCount}',
                          label: 'Transactions',
                        ),
                      ),

                      const _StatDivider(),

                      Expanded(
                        child: _Stat(
                          icon: Icons.show_chart,
                          value: context.money(p.dailyAverage),
                          label: 'Daily average',
                        ),
                      ),
                    ],
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

class _Bubble extends StatelessWidget {
  final double size;

  const _Bubble({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white10,
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  final double percent;

  const _ChangePill({
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final up = percent >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: up ? Colors.orangeAccent : Colors.lightGreenAccent,
          ),
          const SizedBox(width: 6),
          Text(
            '${percent.abs().toStringAsFixed(0)}% '
            '${up ? 'more' : 'less'} than previous month',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// A thin segmented bar: each colored segment is one category's share.
class _CategoryBar extends StatelessWidget {
  final Map<ExpenseCategory, double> data;

  const _CategoryBar({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort(
        (a, b) => b.value.compareTo(a.value),
      );

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final e in entries)
              Expanded(
                flex: (e.value * 100)
                    .round()
                    .clamp(1, 1000000000)
                    .toInt(),
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  color: e.key.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white24,
    );
  }
}

/// "‹ Oct 2025 ›" pill:
/// arrows change month, tapping the label opens the picker.
class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher();

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
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 36,
            ),
            iconSize: 22,
            icon: const Icon(
              Icons.chevron_left,
              color: Colors.white,
            ),
          ),

          InkWell(
            onTap: () => showMonthPicker(context),
            child: Text(
              Fmt.monthYearShort(p.selectedMonth),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          IconButton(
            onPressed: p.canGoNext ? p.nextMonth : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 36,
            ),
            iconSize: 22,
            disabledColor: Colors.white38,
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

