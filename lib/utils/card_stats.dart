import '../models/expense.dart';
import '../models/wallet_card.dart';

/// Numbers for one card, computed from the expense list. Nothing here is
/// stored: edit or delete an expense and the balance is automatically right.
class CardStats {
  final WalletCard card;
  final double spentTotal; // every tracked expense on this card
  final double spentInMonth; // ...in the month passed to CardStats.of
  final int count;

  const CardStats({
    required this.card,
    required this.spentTotal,
    required this.spentInMonth,
    required this.count,
  });

  factory CardStats.of(WalletCard card, List<Expense> expenses, DateTime month) {
    var total = 0.0;
    var inMonth = 0.0;
    var n = 0;
    for (final e in expenses) {
      if (e.cardId != card.id) continue;
      total += e.amount;
      n++;
      if (e.date.year == month.year && e.date.month == month.month) {
        inMonth += e.amount;
      }
    }
    return CardStats(
      card: card,
      spentTotal: total,
      spentInMonth: inMonth,
      count: n,
    );
  }

  bool get isCredit => card.isCredit;

  /// Debit: money left on the card.
  double get balance => card.openingBalance + card.topUps - spentTotal;

  /// Credit: money currently owed.
  double get outstanding => card.openingBalance + spentTotal - card.topUps;

  /// Credit: how much can still be spent.
  double? get available {
    final limit = card.creditLimit;
    return limit == null ? null : limit - outstanding;
  }

  /// Credit: 0..1+ (above 1 means over the limit).
  double? get utilization {
    final limit = card.creditLimit;
    if (limit == null || limit <= 0) return null;
    return outstanding / limit;
  }

  /// The big number shown on the card face.
  double get headline => isCredit ? (available ?? 0) : balance;
}