import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockProvider extends ChangeNotifier {
  static const _kHash = 'lock_hash';
  static const _kSalt = 'lock_salt';
  static const _kBio = 'lock_bio';
  static const _kTimeout = 'lock_timeout';

  /// seconds -> label. 0 means "lock as soon as the app is left".
  static const Map<int, String> autoLockOptions = {
    0: 'Immediately',
    60: 'After 1 minute',
    300: 'After 5 minutes',
    900: 'After 15 minutes',
  };

  final SharedPreferences _prefs;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool enabled = false;
  bool locked = false;
  bool biometricEnabled = false;
  bool biometricAvailable = false;
  int autoLockSeconds = 0;
  bool _authenticating = false;
  DateTime? _pausedAt;
  String? _hash;
  String? _salt;

  AppLockProvider(this._prefs) {
    _hash = _prefs.getString(_kHash);
    _salt = _prefs.getString(_kSalt);
    enabled = _hash != null && _salt != null;
    biometricEnabled = enabled && (_prefs.getBool(_kBio) ?? false);
    autoLockSeconds = _prefs.getInt(_kTimeout) ?? 0;
    locked = enabled; // always locked on a fresh app start
    _checkBiometrics();
  }

  String get autoLockLabel => autoLockOptions[autoLockSeconds] ?? 'Immediately';

  Future<void> _checkBiometrics() async {
    try {
      biometricAvailable = (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      biometricAvailable = false;
    }
    notifyListeners();
  }

  String _digest(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  bool verifyPin(String pin) =>
      _hash != null && _salt != null && _digest(_salt!, pin) == _hash;

  bool unlockWithPin(String pin) {
    if (!verifyPin(pin)) return false;
    locked = false;
    notifyListeners();
    return true;
  }

  Future<void> setPin(String pin) async {
    final rnd = Random.secure();
    _salt = base64UrlEncode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    _hash = _digest(_salt!, pin);
    await _prefs.setString(_kSalt, _salt!);
    await _prefs.setString(_kHash, _hash!);
    enabled = true;
    locked = false;
    notifyListeners();
  }

  Future<void> disable() async {
    if (!enabled) return;
    await _prefs.remove(_kSalt);
    await _prefs.remove(_kHash);
    await _prefs.remove(_kBio);
    await _prefs.remove(_kTimeout);
    _salt = null;
    _hash = null;
    enabled = false;
    locked = false;
    biometricEnabled = false;
    autoLockSeconds = 0;
    notifyListeners();
  }

  Future<void> setAutoLock(int seconds) async {
    autoLockSeconds = seconds;
    await _prefs.setInt(_kTimeout, seconds);
    notifyListeners();
  }

  Future<bool> _authenticate(String reason) async {
    if (_authenticating) return false;
    _authenticating = true;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    } finally {
      _authenticating = false;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    if (!enabled || !biometricEnabled) return false;
    final ok = await _authenticate('Unlock Expense Tracker');
    if (ok) {
      locked = false;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> setBiometric(bool value) async {
    if (!enabled) return false;
    if (value) {
      if (!biometricAvailable) return false;
      if (!await _authenticate('Confirm to enable biometric unlock')) return false;
    }
    biometricEnabled = value;
    await _prefs.setBool(_kBio, value);
    notifyListeners();
    return true;
  }

  /// App went to the background: remember when. With "Immediately" we
  /// also lock right now, so the app-switcher preview is protected.
  void onPaused() {
    if (!enabled || _authenticating) return;
    _pausedAt = DateTime.now();
    if (autoLockSeconds == 0) {
      locked = true;
      notifyListeners();
    }
  }

  /// App came back: lock if it was away longer than the chosen timeout.
  void onResumed() {
    if (!enabled || locked || _authenticating) return;
    final at = _pausedAt;
    _pausedAt = null;
    if (at != null && DateTime.now().difference(at).inSeconds >= autoLockSeconds) {
      locked = true;
      notifyListeners();
    }
  }
}