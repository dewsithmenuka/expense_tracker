import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/card_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/formatters.dart';
import 'section_card.dart';

class _Row {
  final String label;
  final Color color;
  final double amount;
  final IconData icon;
  const _Row(this.label, this.color, this.amount, this.icon);
}

class CardsBreakdownCard extends StatelessWidget {
  const CardsBreakdownCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardProvider>().cards;
    final p = context.watch<ExpenseProvider>();
    if (cards.isEmpty || p.monthCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final total = p.monthTotal;
    final month = p.monthExpenses;
    final known = {for (final c in cards) c.id};

    final rows = <_Row>[];
    for (final c in cards) {
      final sum = month
          .where((e) => e.cardId == c.id)
          .fold<double>(0, (s, e) => s + e.amount);
      if (sum > 0) {
        rows.add(_Row(
          c.displayName,
          Color(c.colorValue),
          sum,
          c.isCredit ? Icons.credit_card : Icons.account_balance_wallet_outlined,
        ));
      }
    }
    // Cash, plus anything pointing at a card that no longer exists
    final noCard = month
        .where((e) => !known.contains(e.cardId))
        .fold<double>(0, (s, e) => s + e.amount);
    if (noCard > 0) {
      rows.add(_Row('Cash / no card', Colors.blueGrey, noCard, Icons.payments_outlined));
    }

    if (total <= 0 || rows.isEmpty) return const SizedBox.shrink();
    rows.sort((a, b) => b.amount.compareTo(a.amount));

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SectionCard(
        title: 'Spending by card',
        subtitle: 'How you paid in ${Fmt.monthLabel(p.selectedMonth)}',
        icon: Icons.credit_card,
        child: Column(
          children: [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: r.color.withAlpha(40),
                          child: Icon(r.icon, size: 16, color: r.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(r.label,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text(context.money(r.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${(r.amount / total * 100).round()}%',
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
                        value: r.amount / total,
                        minHeight: 6,
                        backgroundColor: r.color.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(r.color),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}