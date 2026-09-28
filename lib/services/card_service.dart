import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/wallet_card.dart';

class CardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _cards => _db.collection('cards');

  Stream<List<WalletCard>> streamCards(String userId) {
    return _cards.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs.map(WalletCard.fromDocument).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<void> addCard(WalletCard card) async {
    final id = card.id.isEmpty ? _uuid.v4() : card.id;
    await _cards.doc(id).set(card.toMap());
  }

  Future<void> updateCard(WalletCard card) =>
      _cards.doc(card.id).update(card.toMap());

  Future<void> deleteCard(String id) => _cards.doc(id).delete();
}