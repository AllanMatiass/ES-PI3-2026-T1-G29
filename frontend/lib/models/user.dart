import './firebase.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String cpf;
  final Wallet wallet;
  final FirestoreTimestamp createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.cpf,
    required this.wallet,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['result'] != null ? json['result']['data'] : json;
    
    return UserProfile(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      cpf: data['cpf'] ?? '',
      wallet: Wallet.fromJson(data['wallet'] ?? {}),
      createdAt: FirestoreTimestamp.fromJson(data['createdAt']),
    );
  }
}

class Wallet {
  final double balanceInCents;
  final double totalInvestedCents;
  final List<WalletTokenPosition> positions;
  final FirestoreTimestamp updatedAt;

  Wallet({
    required this.balanceInCents,
    required this.totalInvestedCents,
    required this.positions,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balanceInCents: (json['balanceInCents'] as num?)?.toDouble() ?? 0.0,
      totalInvestedCents: (json['totalInvestedCents'] as num?)?.toDouble() ?? 0.0,
      updatedAt: FirestoreTimestamp.fromJson(json['updatedAt']),
      positions: (json['positions'] as List? ?? [])
          .map((e) => WalletTokenPosition.fromJson(e))
          .toList(),
    );
  }
}

class WalletTokenPosition {
  final String startupId;
  final String startupName;
  final int qtdTokens;
  final int lockedTokens;
  final double averagePriceCents;
  final double investedCents;
  final FirestoreTimestamp updatedAt;

  WalletTokenPosition({
    required this.startupId,
    required this.startupName,
    required this.qtdTokens,
    required this.lockedTokens,
    required this.averagePriceCents,
    required this.investedCents,
    required this.updatedAt,
  });

  factory WalletTokenPosition.fromJson(Map<String, dynamic> json) {
    return WalletTokenPosition(
      startupId: json['startupId'] ?? '',
      startupName: json['startupName'] ?? '',
      qtdTokens: (json['qtdTokens'] as num?)?.toInt() ?? 0,
      lockedTokens: (json['lockedTokens'] as num?)?.toInt() ?? 0,
      averagePriceCents: (json['averagePriceCents'] as num?)?.toDouble() ?? 0.0,
      investedCents: (json['investedCents'] as num?)?.toDouble() ?? 0.0,
      updatedAt: FirestoreTimestamp.fromJson(json['updatedAt']),
    );
  }
}

class WalletTokenPositionDTO extends WalletTokenPosition {
  final double currentTokenPriceCents;
  final double currentValueCents;
  final double profitCents;
  final double profitPercentage;

  WalletTokenPositionDTO({
    required super.startupId,
    required super.startupName,
    required super.qtdTokens,
    required super.lockedTokens,
    required super.averagePriceCents,
    required super.investedCents,
    required super.updatedAt,
    required this.currentTokenPriceCents,
    required this.currentValueCents,
    required this.profitCents,
    required this.profitPercentage,
  });

  factory WalletTokenPositionDTO.fromJson(Map<String, dynamic> json) {
    return WalletTokenPositionDTO(
      startupId: json['startupId'] ?? '',
      startupName: json['startupName'] ?? '',
      qtdTokens: (json['qtdTokens'] as num?)?.toInt() ?? 0,
      lockedTokens: (json['lockedTokens'] as num?)?.toInt() ?? 0,
      averagePriceCents: (json['averagePriceCents'] as num?)?.toDouble() ?? 0.0,
      investedCents: (json['investedCents'] as num?)?.toDouble() ?? 0.0,
      updatedAt: FirestoreTimestamp.fromJson(json['updatedAt']),
      currentTokenPriceCents: (json['currentTokenPriceCents'] as num?)?.toDouble() ?? 0.0,
      currentValueCents: (json['currentValueCents'] as num?)?.toDouble() ?? 0.0,
      profitCents: (json['profitCents'] as num?)?.toDouble() ?? 0.0,
      profitPercentage: (json['profitPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
