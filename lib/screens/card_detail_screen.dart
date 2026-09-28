import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/wallet_card.dart';
import '../providers/card_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_style.dart';
import '../utils/card_stats.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/card_face.dart';
import 'card_form_screen.dart';

class CardDetailScreen extends StatelessWidget {
  final String cardId;

  const CardDetailScreen({
    super.key,
    required this.cardId,
  });

  Future<void> _adjust(
    BuildContext context,
    WalletCard card,
    CardStats stats,
  ) async {
    final cards = context.read<CardProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final credit = card.isCredit;

    if (credit && stats.outstanding <= 0.005) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Nothing is owed on this card.'),
        ),
      );
      return;
    }

    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _AmountDialog(
        title: credit ? 'Record a payment' : 'Add funds',
        helper: credit
            ? 'You currently owe ${context.money(stats.outstanding)}.'
            : 'Money you added to this card.',
        max: credit ? stats.outstanding : null,
      ),
    );

    if (amount == null) return;

    final err = await cards.topUp(card, amount);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          err ?? (credit ? 'Payment recorded' : 'Funds added'),
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WalletCard card,
    int count,
  ) async {
    final cards = context.read<CardProvider>();
    final expenses = context.read<ExpenseProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete ${card.displayName}?',
        ),
        content: Text(
          count > 0
              ? 'The $count expenses paid with this card are kept and will show '
                  'as "Cash / no card".'
              : 'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    // Order matters: detach the expenses first, then delete the card.
    final e1 = await expenses.detachCard(card.id);

    if (e1 != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e1),
        ),
      );
      return;
    }

    final e2 = await cards.deleteCard(card.id);

    if (e2 != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e2),
        ),
      );
      return;
    }

    navigator.pop();

    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Card deleted'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = context.watch<CardProvider>();
    final ex = context.watch<ExpenseProvider>();

    final card = cards.cardById(cardId);
    final theme = Theme.of(context);

    if (card == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('This card no longer exists.'),
        ),
      );
    }

    final stats = CardStats.of(
      card,
      ex.allExpenses,
      ex.selectedMonth,
    );

    final monthLabel = Fmt.monthLabel(
      ex.selectedMonth,
    );

    final recent = ex.allExpenses
        .where((e) => e.cardId == card.id)
        .take(10)
        .toList();

    final util = stats.utilization;

    final utilColor = (util ?? 0) >= 1
        ? theme.colorScheme.error
        : (util ?? 0) >= 0.8
            ? Colors.orange
            : theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(card.nickname),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 380,
              ),
              child: AspectRatio(
                aspectRatio: 1.586,
                child: StatsCardFace(
                  stats: stats,
                  monthLabel: monthLabel,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- Credit usage bar ----
          if (card.isCredit && util != null) ...[
            Row(
              children: [
                Text(
                  'Credit used',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(util * 100).round()}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: utilColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: util.clamp(0.0, 1.0).toDouble(),
                minHeight: 10,
                backgroundColor: utilColor.withAlpha(35),
                valueColor: AlwaysStoppedAnimation<Color>(
                  utilColor,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],

          // ---- Stats ----
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_month,
                  label: 'Spent in $monthLabel',
                  value: context.money(
                    stats.spentInMonth,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _StatTile(
                  icon: Icons.summarize_outlined,
                  label: 'Total tracked',
                  value: context.money(
                    stats.spentTotal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.receipt_long,
                  label: 'Transactions',
                  value: '${stats.count}',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _StatTile(
                  icon: card.isCredit
                      ? Icons.payments_outlined
                      : Icons.savings_outlined,
                  label: card.isCredit
                      ? 'Paid so far'
                      : 'Funds added',
                  value: context.money(
                    card.topUps,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ---- Actions ----
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => _adjust(
                  context,
                  card,
                  stats,
                ),
                icon: Icon(
                  card.isCredit
                      ? Icons.payments_outlined
                      : Icons.add_card,
                ),
                label: Text(
                  card.isCredit
                      ? 'Record payment'
                      : 'Add funds',
                ),
              ),

              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CardFormScreen(
                      card: card,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                ),
                label: const Text('Edit'),
              ),

              OutlinedButton.icon(
                onPressed: () => _delete(
                  context,
                  card,
                  stats.count,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                icon: const Icon(
                  Icons.delete_outline,
                ),
                label: const Text('Delete'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ---- Recent expenses ----
          Text(
            'Recent expenses',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Text(
                'No expenses paid with this card yet. Pick it under '
                '"Paid with" when adding an expense.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Material(
              color: AppColors.tile(context),
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final e in recent)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            e.category.color.withAlpha(40),
                        child: const Icon(
                          Icons.receipt_long_outlined,
                        ),
                      ),
                      title: Text(
                        e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        Fmt.dayLabel(e.date),
                      ),
                      trailing: Text(
                        '-${context.money(e.amount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tile(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for one amount. Its own widget so the controller is disposed safely.
class _AmountDialog extends StatefulWidget {
  final String title;
  final String? helper;
  final double? max;

  const _AmountDialog({
    required this.title,
    this.helper,
    this.max,
  });

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final base = Validators.amount(v);

    if (base != null) return base;

    final value = double.parse(
      v!.trim().replaceAll(',', '.'),
    );

    if (widget.max != null &&
        value > widget.max! + 0.005) {
      return 'Cannot be more than the amount owed';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d*[.,]?\d{0,2}'),
            ),
          ],
          decoration: InputDecoration(
            labelText: 'Amount',
            helperText: widget.helper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
          validator: _validate,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                double.parse(
                  _controller.text
                      .trim()
                      .replaceAll(',', '.'),
                ),
              );
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}