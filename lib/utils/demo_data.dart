import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/expense.dart';
import '../models/wallet_card.dart';

/// Demo expenses get ids that start with this, so they can be removed later.
const String demoIdPrefix = 'demo_';

class _Template {
  final String title;
  final double min;
  final double max;
  const _Template(this.title, this.min, this.max);
}

const Map<ExpenseCategory, List<_Template>> _templates = {
  ExpenseCategory.food: [
    _Template('Lunch', 6, 18),
    _Template('Groceries', 25, 90),
    _Template('Coffee', 3, 7),
    _Template('Dinner out', 20, 60),
    _Template('Snacks', 2, 10),
  ],
  ExpenseCategory.transport: [
    _Template('Bus ticket', 2, 6),
    _Template('Taxi', 10, 35),
    _Template('Fuel', 30, 70),
  ],
  ExpenseCategory.shopping: [
    _Template('Clothes', 20, 150),
    _Template('Online order', 10, 80),
    _Template('New shoes', 40, 120),
  ],
  ExpenseCategory.entertainment: [
    _Template('Movie night', 10, 25),
    _Template('Streaming', 8, 16),
    _Template('Concert ticket', 30, 90),
  ],
  ExpenseCategory.health: [
    _Template('Pharmacy', 5, 40),
    _Template('Gym session', 15, 40),
  ],
  ExpenseCategory.education: [
    _Template('Online course', 15, 60),
    _Template('Books', 10, 35),
  ],
  ExpenseCategory.other: [
    _Template('Gift', 10, 60),
    _Template('Donation', 5, 25),
  ],
};

/// Categories are repeated so food/transport show up more often.
const List<ExpenseCategory> _everyday = [
  ExpenseCategory.food,
  ExpenseCategory.food,
  ExpenseCategory.food,
  ExpenseCategory.transport,
  ExpenseCategory.transport,
  ExpenseCategory.shopping,
  ExpenseCategory.entertainment,
  ExpenseCategory.health,
  ExpenseCategory.education,
  ExpenseCategory.other,
];

/// (title, amount, day of the month)
const List<(String, double, int)> _bills = [
  ('Internet bill', 45.0, 5),
  ('Phone plan', 25.0, 12),
  ('Electricity', 68.0, 20),
];

/// Builds realistic sample expenses from the first day of [months] months ago
/// up to today. Pass [random] to get repeatable output (used in tests).
List<Expense> generateDemoExpenses({
  required String userId,
  required List<WalletCard> cards,
  int months = 3,
  Random? random,
}) {
  final rnd = random ?? Random();
  const uuid = Uuid();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = DateTime(now.year, now.month - (months - 1), 1);
  final result = <Expense>[];

  double round2(double v) => (v * 100).roundToDouble() / 100;

  // ~30% cash, the rest spread across the user's cards.
  String? pickCard() {
    if (cards.isEmpty || rnd.nextInt(10) < 3) return null;
    return cards[rnd.nextInt(cards.length)].id;
  }

  Expense make(String title, ExpenseCategory cat, double amount, DateTime day) {
    return Expense(
      id: '$demoIdPrefix${uuid.v4()}',
      userId: userId,
      title: title,
      amount: round2(amount),
      category: cat,
      date: day,
      cardId: pickCard(),
      createdAt: DateTime.now(),
    );
  }

  for (var day = start;
      !day.isAfter(today);
      day = DateTime(day.year, day.month, day.day + 1)) {
    for (final bill in _bills) {
      if (day.day == bill.$3) {
        result.add(make(bill.$1, ExpenseCategory.bills, bill.$2, day));
      }
    }

    // 0-2 everyday expenses on weekdays, 0-3 on weekends
    final count = rnd.nextInt(day.weekday >= DateTime.saturday ? 4 : 3);
    for (var i = 0; i < count; i++) {
      final cat = _everyday[rnd.nextInt(_everyday.length)];
      final options = _templates[cat]!;
      final t = options[rnd.nextInt(options.length)];
      final amount = t.min + rnd.nextDouble() * (t.max - t.min);
      result.add(make(t.title, cat, amount, day));
    }
  }
  return result;
}