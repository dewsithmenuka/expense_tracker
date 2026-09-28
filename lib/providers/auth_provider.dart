import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../utils/navigation.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  final AccountService _account;
  StreamSubscription<User?>? _sub;

  User? user;
  bool initializing = true;

  AuthProvider(this._service, this._account) {
    _sub = _service.userChanges.listen(
      (u) {
        user = u;
        initializing = false;
        notifyListeners();
      },
      onError: (_) {
        initializing = false;
        notifyListeners();
      },
    );
  }

  Future<String?> signIn(String email, String password) =>
      _run(() => _service.signIn(email, password));

  Future<String?> register(String name, String email, String password) =>
      _run(() => _service.register(name, email, password));

  Future<String?> sendPasswordReset(String email) =>
      _run(() => _service.sendPasswordReset(email));

  Future<String?> updateName(String name) =>
      _run(() => _service.updateDisplayName(name));

  Future<String?> changePassword(String current, String next) =>
      _run(() => _account.changePassword(current, next), sensitive: true);

  Future<String?> deleteAccount(String password) => _run(
        () => _account
            .deleteAccount(password)
            .timeout(const Duration(seconds: 90)),
        sensitive: true,
      );

  /// null = success, otherwise a message ready to show to the user.
  Future<String?> _run(Future<void> Function() action,
      {bool sensitive = false}) async {
    try {
      await action();
      return null;
    } catch (e) {
      return AuthService.friendlyError(e, sensitive: sensitive);
    }
  }

  Future<void> signOut() async {
    rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
    await _service.signOut();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}