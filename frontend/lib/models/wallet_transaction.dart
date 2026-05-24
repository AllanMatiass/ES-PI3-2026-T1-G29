// Autor: Allan Giovanni Matias paes
import './firebase.dart';

/// Request DTO for wallet transactions (deposit/withdraw).
class WalletTransactionRequest {
  final num amount;

  WalletTransactionRequest({required this.amount});

  Map<String, dynamic> toJson() => {'amount': amount};
}

/// Response DTO for wallet transactions.
class WalletTransactionResponse {
  final String userId;
  final num newBalance;

  WalletTransactionResponse({required this.userId, required this.newBalance});

  factory WalletTransactionResponse.fromJson(Map<String, dynamic> json) {
    return WalletTransactionResponse(
      userId: json['userId'] ?? '',
      newBalance: json['newBalance'] ?? 0,
    );
  }
}

/// Representa uma movimentação financeira (DEPOSIT | WITHDRAW).
class Movement {
  final String type;
  final int amountInCents;
  final FirestoreTimestamp createdAt;

  Movement({
    required this.type,
    required this.amountInCents,
    required this.createdAt,
  });

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      type: json['type'] ?? '',
      amountInCents: (json['amountInCents'] as num?)?.toInt() ?? 0,
      createdAt: FirestoreTimestamp.fromJson(json['createdAt']),
    );
  }
}

/// Resposta paginada de movimentações.
class PaginatedMovementsResponse {
  final List<Movement> movements;
  final String? lastMovementId;

  PaginatedMovementsResponse({required this.movements, this.lastMovementId});

  factory PaginatedMovementsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedMovementsResponse(
      movements: (json['movements'] as List? ?? [])
          .map((e) => Movement.fromJson(e))
          .toList(),
      lastMovementId: json['lastMovementId'],
    );
  }
}
