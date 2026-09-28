import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/card_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/card_stats.dart';
import '../utils/formatters.dart';
import '../widgets/card_face.dart';
import 'card_detail_screen.dart';
import 'card_form_screen.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  void _add(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CardFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardProvider>();
    final ex = context.watch<ExpenseProvider>();

    Widget body;
    if (cards.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (cards.errorMessage != null) {
      body = _CardsError(message: cards.errorMessage!, onRetry: cards.retry);
    } else if (cards.cards.isEmpty) {
      body = _EmptyCards(onAdd: () => _add(context));
    } else {
      final stats = [
        for (final c in cards.cards)
          CardStats.of(c, ex.allExpenses, ex.selectedMonth),
      ];
      var debitTotal = 0.0;
      var owed = 0.0;
      var hasCredit = false;
      for (final s in stats) {
        if (s.isCredit) {
          hasCredit = true;
          owed += s.outstanding;
        } else {
          debitTotal += s.balance;
        }
      }
      final monthLabel = Fmt.monthLabel(ex.selectedMonth);

      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // room for the FAB
        children: [
          _Summary(debitTotal: debitTotal, owed: owed, hasCredit: hasCredit),
          const SizedBox(height: 20),
          for (final s in stats)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardDetailScreen(cardId: s.card.id),
                      ),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.586,
                      child: StatsCardFace(stats: s, monthLabel: monthLabel),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My cards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_card),
        label: const Text('Add card'),
      ),
      body: body,
    );
  }
}

class _Summary extends StatelessWidget {
  final double debitTotal;
  final double owed;
  final bool hasCredit;
  const _Summary({
    required this.debitTotal,
    required this.owed,
    required this.hasCredit,
  });

  @override
  Widget build(BuildContext context) {
    Widget block(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.brand,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          block('Total balance (debit)',
              debitTotal < 0 ? '-${context.money(-debitTotal)}' : context.money(debitTotal)),
          if (hasCredit) ...[
            Container(width: 1, height: 44, color: Colors.white24),
            const SizedBox(width: 16),
            block('Owed on credit', context.money(owed)),
          ],
        ],
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCards({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.credit_card,
                  size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text('No cards yet',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Add a debit or credit card to see live\nbalances and where your money goes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_card),
              label: const Text('Add your first card'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CardsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text("We couldn't load your cards",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}