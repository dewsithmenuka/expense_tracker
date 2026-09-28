import 'package:flutter/material.dart';

import '../models/wallet_card.dart';
import '../utils/card_stats.dart';
import '../utils/formatters.dart';

/// Colours the user can pick for a card.
const List<int> kCardColors = [
  0xFF00897B, // teal
  0xFF3949AB, // indigo
  0xFF8E24AA, // purple
  0xFFD81B60, // pink
  0xFFF4511E, // orange
  0xFF546E7A, // slate
  0xFF1E88E5, // blue
  0xFF43A047, // green
];

Color _darken(Color c, [double amount = 0.16]) {
  final hsl = HSLColor.fromColor(c);
  final lightness = (hsl.lightness - amount).clamp(0.0, 1.0).toDouble();
  return hsl.withLightness(lightness).toColor();
}

/// The plain visual. Give it a size (SizedBox / AspectRatio) from outside.
class CardFace extends StatelessWidget {
  final String nickname;
  final String last4;
  final CardType type;
  final Color color;
  final String label;
  final String value;
  final String? footnote;
  final bool warn;

  const CardFace({
    super.key,
    required this.nickname,
    required this.last4,
    required this.type,
    required this.color,
    required this.label,
    required this.value,
    this.footnote,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, _darken(color)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(70),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(right: -30, top: -30, child: _Circle(120)),
          const Positioned(left: -20, bottom: -50, child: _Circle(110)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type == CardType.credit ? 'CREDIT' : 'DEBIT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.credit_card, color: Colors.white70),
                  ],
                ),
                const Spacer(),
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: warn ? const Color(0xFFFFCDD2) : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (footnote != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      footnote!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '•••• $last4',
                      style: const TextStyle(
                          color: Colors.white, letterSpacing: 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  const _Circle(this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
    );
  }
}

/// A [CardFace] filled in from real numbers (a card + its expenses).
/// [compact] hides the footnote so it fits the small cards on Home.
class StatsCardFace extends StatelessWidget {
  final CardStats stats;
  final String monthLabel;
  final bool compact;

  const StatsCardFace({
    super.key,
    required this.stats,
    required this.monthLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = stats.card;
    final headline = stats.headline;

    String? footnote;
    if (!compact) {
      footnote = card.isCredit
          ? 'Limit ${context.money(card.creditLimit ?? 0)} · Owed ${context.money(stats.outstanding)}'
          : 'Spent in $monthLabel: ${context.money(stats.spentInMonth)}';
    }

    return CardFace(
      nickname: card.nickname,
      last4: card.last4,
      type: card.type,
      color: Color(card.colorValue),
      label: card.isCredit ? 'Available credit' : 'Balance',
      value: headline < 0
          ? '-${context.money(-headline)}'
          : context.money(headline),
      footnote: footnote,
      warn: headline < 0,
    );
  }
}