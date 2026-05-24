// Autor: Allan Giovanni Matias Paes
import './firebase.dart';

// Representa o perfil detalhado do usuário no sistema.
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

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? cpf,
    Wallet? wallet,
    FirestoreTimestamp? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      cpf: cpf ?? this.cpf,
      wallet: wallet ?? this.wallet,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Converte dados do JSON para uma instância de UserProfile.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json;

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

// Representa a carteira virtual do usuário com saldo e posições.
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

  Wallet copyWith({
    double? balanceInCents,
    double? totalInvestedCents,
    List<WalletTokenPosition>? positions,
    FirestoreTimestamp? updatedAt,
  }) {
    return Wallet(
      balanceInCents: balanceInCents ?? this.balanceInCents,
      totalInvestedCents: totalInvestedCents ?? this.totalInvestedCents,
      positions: positions ?? this.positions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balanceInCents: (json['balanceInCents'] as num?)?.toDouble() ?? 0.0,
      totalInvestedCents:
          (json['totalInvestedCents'] as num?)?.toDouble() ?? 0.0,
      updatedAt: FirestoreTimestamp.fromJson(json['updatedAt']),
      positions: (json['positions'] as List? ?? [])
          .map((e) => WalletTokenPosition.fromJson(e))
          .toList(),
    );
  }
}

// Representa a posse de tokens de uma startup específica na carteira do usuário.
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

// Extensão da posição de tokens com informações adicionais de mercado.
class WalletTokenPositionDTO extends WalletTokenPosition {
  final double currentTokenPriceCents;
  final double currentValueCents;

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
      currentTokenPriceCents:
          (json['currentTokenPriceCents'] as num?)?.toDouble() ?? 0.0,
      currentValueCents: (json['currentValueCents'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Resposta paginada da API de investimentos.
class PaginatedInvestmentsResponseDTO {
  final List<WalletTokenPositionDTO> investments;
  final String? lastStartupId;

  PaginatedInvestmentsResponseDTO({
    required this.investments,
    this.lastStartupId,
  });

  factory PaginatedInvestmentsResponseDTO.fromJson(Map<String, dynamic> json) {
    return PaginatedInvestmentsResponseDTO(
      investments: (json['investments'] as List? ?? [])
          .map((e) => WalletTokenPositionDTO.fromJson(e))
          .toList(),
      lastStartupId: json['lastStartupId'],
    );
  }
}
