import 'package:flutter/material.dart';

import '../models/expense.dart';

extension CategoryStyle on ExpenseCategory {
  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF9800); // orange
      case ExpenseCategory.transport:
        return const Color(0xFF2196F3); // blue
      case ExpenseCategory.shopping:
        return const Color(0xFFE91E63); // pink
      case ExpenseCategory.bills:
        return const Color(0xFF9C27B0); // purple
      case ExpenseCategory.entertainment:
        return const Color(0xFFFFC107); // amber
      case ExpenseCategory.health:
        return const Color(0xFFF44336); // red
      case ExpenseCategory.education:
        return const Color(0xFF3F51B5); // indigo
      case ExpenseCategory.other:
        return const Color(0xFF607D8B); // blue-grey
    }
  }
}

class AppColors {
  /// Card/tile background that works in both light and dark mode.
  static Color tile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1F2A29) : Colors.white;
  }
    static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00897B), Color(0xFF004D40)],
  );
}