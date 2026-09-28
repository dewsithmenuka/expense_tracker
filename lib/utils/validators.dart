class Validators {
  static const double maxAmount = 10000000;
  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter a title';
    if (v.length < 2) return 'Title is too short';
    if (v.length > 60) return 'Keep the title under 60 characters';
    return null;
  }

  static String? amount(String? value) {
    final v = (value ?? '').trim().replaceAll(',', '.');
    if (v.isEmpty) return 'Please enter an amount';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Amount must be greater than 0';
    if (parsed > maxAmount) return 'Amount is too large';
    return null;
  }

  static String? note(String? value) {
    if ((value ?? '').trim().length > 200) {
      return 'Note must be under 200 characters';
    }
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 40) return 'Name must be under 40 characters';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    if (!_emailRe.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Use at least 6 characters';
    return null;
  }
    static String? cardName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Give the card a name';
    if (v.length < 2) return 'Name is too short';
    if (v.length > 20) return 'Keep it under 20 characters';
    return null;
  }

  static String? last4(String? value) {
    if (!RegExp(r'^\d{4}$').hasMatch(value?.trim() ?? '')) {
      return 'Enter exactly 4 digits';
    }
    return null;
  }

  /// Like amount(), but 0 is allowed (an empty account, a fresh card).
  static String? balance(String? value) {
    final v = (value ?? '').trim().replaceAll(',', '.');
    if (v.isEmpty) return 'Enter an amount (0 is fine)';
    final parsed = double.tryParse(v);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Cannot be negative';
    if (parsed > maxAmount) return 'Amount is too large';
    return null;
  }
}