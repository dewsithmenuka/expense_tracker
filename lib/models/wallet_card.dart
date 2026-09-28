import 'package:cloud_firestore/cloud_firestore.dart';

enum CardType { debit, credit }

/// A user's card/wallet. For security we NEVER store the full card
/// number, expiry or CVV - only a nickname and the last 4 digits.
class WalletCard {
  final String id;
  final String userId;
  final String nickname;
  final String last4;
  final CardType type;

  /// Debit: balance when the card was added.
  /// Credit: amount already owed when the card was added.
  final double openingBalance;

  /// Credit cards only.
  final double? creditLimit;

  /// Debit: total funds added later. Credit: total payments made.
  final double topUps;

  final int colorValue;
  final DateTime createdAt;

  const WalletCard({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.last4,
    required this.type,
    required this.openingBalance,
    this.creditLimit,
    this.topUps = 0,
    required this.colorValue,
    required this.createdAt,
  });

  bool get isCredit => type == CardType.credit;

  String get displayName => '$nickname •••• $last4';

  WalletCard withTopUps(double value) => WalletCard(
        id: id,
        userId: userId,
        nickname: nickname,
        last4: last4,
        type: type,
        openingBalance: openingBalance,
        creditLimit: creditLimit,
        topUps: value,
        colorValue: colorValue,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'nickname': nickname,
        'last4': last4,
        'type': type.name,
        'openingBalance': openingBalance,
        'creditLimit': creditLimit,
        'topUps': topUps,
        'colorValue': colorValue,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory WalletCard.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return WalletCard(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      nickname: d['nickname'] as String? ?? 'Card',
      last4: d['last4'] as String? ?? '0000',
      type: CardType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => CardType.debit,
      ),
      openingBalance: (d['openingBalance'] as num?)?.toDouble() ?? 0,
      creditLimit: (d['creditLimit'] as num?)?.toDouble(),
      topUps: (d['topUps'] as num?)?.toDouble() ?? 0,
      colorValue: d['colorValue'] as int? ?? 0xFF009688,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}