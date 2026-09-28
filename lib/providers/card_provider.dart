import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/wallet_card.dart';
import '../services/card_service.dart';

class CardProvider extends ChangeNotifier {
  final CardService _service;
  String userId = '';

  CardProvider({required CardService service}) : _service = service;

  StreamSubscription<List<WalletCard>>? _subscription;
  List<WalletCard> _cards = [];
  bool loading = false;
  String? errorMessage;

  List<WalletCard> get cards => _cards;

  /// Runs during a build (ChangeNotifierProxyProvider), so it must NOT
  /// call notifyListeners(). The stream's first event does that instead.
  void setUser(String? uid) {
    final newId = uid ?? '';
    if (newId == userId) return;
    userId = newId;
    _subscription?.cancel();
    _subscription = null;
    _cards = [];
    errorMessage = null;
    loading = false;
    if (newId.isEmpty) return;
    _listen();
  }

  void _listen() {
    loading = true;
    errorMessage = null;
    _subscription?.cancel();
    _subscription = _service.streamCards(userId).listen(
      (cards) {
        _cards = cards;
        loading = false;
        errorMessage = null;
        notifyListeners();
      },
      onError: (e) {
        loading = false;
        errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  /// For the error screen's Retry button.
  void retry() {
    if (userId.isEmpty) return;
    _listen();
    notifyListeners();
  }

  WalletCard? cardById(String? id) {
    if (id == null) return null;
    for (final c in _cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// null = success, otherwise a message ready to show the user.
  Future<String?> saveCard(WalletCard card, {required bool isNew}) async {
    try {
      final op = isNew ? _service.addCard(card) : _service.updateCard(card);
      await op.timeout(const Duration(seconds: 8));
      return null;
    } on TimeoutException {
      return null; // offline: Firestore queues the write and syncs later
    } catch (_) {
      return 'Could not save the card. Please try again.';
    }
  }

  /// Debit: adds funds. Credit: records a payment.
  Future<String?> topUp(WalletCard card, double amount) =>
      saveCard(card.withTopUps(card.topUps + amount), isNew: false);

  Future<String?> deleteCard(String id) async {
    try {
      await _service.deleteCard(id).timeout(const Duration(seconds: 8));
      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return 'Could not delete the card. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}