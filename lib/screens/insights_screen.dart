import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/formatters.dart';
import '../widgets/category_donut.dart';
import '../widgets/insight_card.dart';
import '../widgets/month_switcher.dart';
import '../widgets/spending_heatmap.dart';
import '../widgets/state_views.dart';
import '../widgets/trend_chart.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();

    // What goes under the header depends on the loading state.
    final List<Widget> body;
    switch (p.status) {
      case LoadStatus.loading:
        body = const [
          Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      case LoadStatus.error:
        body = [
          SizedBox(
            height: 360,
            child: ErrorView(
              message: p.errorMessage ?? 'Unknown error',
              onRetry: p.retry,
            ),
          ),
        ];
      case LoadStatus.empty:
        body = const [SizedBox(height: 360, child: _NoDataYet())];
      case LoadStatus.loaded:
        body = [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              children: [
                const SmartInsightsCard(),
                // Charts only make sense when this month has data
                if (p.monthCount > 0) ...const [
                  SizedBox(height: 16),
                  CategoryDonutCard(),
                  SizedBox(height: 16),
                  SpendingHeatmapCard(),
                ],
                const SizedBox(height: 16),
                const MonthlyTrendCard(),
              ],
            ),
          ),
        ];
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [const _Header(), ...body],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.brand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Insights',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const MonthSwitcher(),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Where your money went in ${Fmt.monthLabel(p.selectedMonth)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            context.money(p.monthTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDataYet extends StatelessWidget {
  const _NoDataYet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No data to analyse yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a few expenses and your charts,\ncalendar and insights will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}