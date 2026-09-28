import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/card_provider.dart';
import '../providers/expense_provider.dart';
import '../screens/card_detail_screen.dart';
import '../screens/cards_screen.dart';
import '../utils/card_stats.dart';
import '../utils/formatters.dart';
import 'card_face.dart';

class CardsStrip extends StatelessWidget {
  const CardsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardProvider>().cards;
    if (cards.isEmpty) return const SizedBox.shrink();

    final ex = context.watch<ExpenseProvider>();
    final theme = Theme.of(context);
    final monthLabel = Fmt.monthLabel(ex.selectedMonth);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
            child: Row(
              children: [
                Text('My cards',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CardsScreen()),
                  ),
                  child: const Text('Manage'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 172, // leaves room for the card's shadow
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final card = cards[i];
                final stats = CardStats.of(card, ex.allExpenses, ex.selectedMonth);
                return SizedBox(
                  width: 260,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardDetailScreen(cardId: card.id),
                      ),
                    ),
                    child: StatsCardFace(
                      stats: stats,
                      monthLabel: monthLabel,
                      compact: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}