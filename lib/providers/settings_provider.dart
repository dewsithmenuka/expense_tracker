import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kTheme = 'theme_mode';
  static const _kCurrency = 'currency_symbol';

  final SharedPreferences _prefs;
  ThemeMode themeMode;
  String currencySymbol;

  SettingsProvider(this._prefs)
      : themeMode = _decode(_prefs.getString(_kTheme)),
        currencySymbol = _prefs.getString(_kCurrency) ?? '\$';

  static ThemeMode _decode(String? value) => ThemeMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => ThemeMode.system,
      );

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setCurrency(String symbol) async {
    currencySymbol = symbol;
    notifyListeners();
    await _prefs.setString(_kCurrency, symbol);
  }
}