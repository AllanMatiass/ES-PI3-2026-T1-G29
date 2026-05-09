import './firebase.dart';

class UserData {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String cpf;
  final FirestoreTimestamp createdAt;
  final Wallet wallet;

  UserData({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.cpf,
    required this.createdAt,
    required this.wallet,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    final data = json['result']['data'];
    return UserData(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      phone: data['phone'],
      cpf: data['cpf'],
      createdAt: FirestoreTimestamp.fromJson(data['createdAt']),
      wallet: Wallet.fromJson(data['wallet']),
    );
  }
}

class Wallet {
  final int balanceInCents;
  final int totalInvestedCents;
  final FirestoreTimestamp updatedAt;
  final List<Position> positions;

  Wallet({
    required this.balanceInCents,
    required this.totalInvestedCents,
    required this.updatedAt,
    required this.positions,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balanceInCents: json['balanceInCents'] ?? 0,
      totalInvestedCents: json['totalInvestedCents'] ?? 0,
      updatedAt: FirestoreTimestamp.fromJson(json['updatedAt']),
      positions: (json['positions'] as List? ?? [])
          .map((e) => Position.fromJson(e))
          .toList(),
    );
  }
}

class Position {
  final int lockedTokens;
  final int qtdTokens;
  final String startupId;
  final String startupName;
  final FirestoreTimestamp updatedAt;
  final int averagePriceCents;
  final int investedCents;

  Position({
    required this.lockedTokens,
    required this.qtdTokens,
    required this.startupId,
    required this.startupName,
    required this.updatedAt,
    required this.averagePriceCents,
    required this.investedCents,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      lockedTokens: json['lockedTokens'] ?? 0,
      qtdTokens: json['qtdTokens'] ?? 0,
      startupId: json['startupId'] ?? '',
      startupName: json['startupName'] ?? '',
      updatedAt: FirestoreTimestamp.fromJson(json['updatedAt']),
      averagePriceCents: json['averagePriceCents'] ?? 0,
      investedCents: json['investedCents'] ?? 0,
    );
  }
}
