// Autor: Allan Giovanni Matias Paes
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

  factory WalletTransactionResponse.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return WalletTransactionResponse(
      userId: data['userId'] ?? '',
      newBalance: data['newBalance'] ?? 0,
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

  factory Movement.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return Movement(
      type: data['type'] ?? '',
      amountInCents: (data['amountInCents'] as num?)?.toInt() ?? 0,
      createdAt: FirestoreTimestamp.fromJson(data['createdAt']),
    );
  }
}

/// Resposta paginada de movimentações.
class PaginatedMovementsResponse {
  final List<Movement> movements;
  final String? lastMovementId;

  PaginatedMovementsResponse({required this.movements, this.lastMovementId});

  factory PaginatedMovementsResponse.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return PaginatedMovementsResponse(
      movements: (data['movements'] as List? ?? [])
          .map((e) => Movement.fromJson(e))
          .toList(),
      lastMovementId: data['lastMovementId'],
    );
  }
}
