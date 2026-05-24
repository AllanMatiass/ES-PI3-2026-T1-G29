// Autor: Gemini CLI

/// Request DTO for wallet transactions (deposit/withdraw).
class WalletTransactionRequest {
  final num amount;

  WalletTransactionRequest({required this.amount});

  Map<String, dynamic> toJson() => {
    'amount': amount,
  };
}

/// Response DTO for wallet transactions.
class WalletTransactionResponse {
  final String userId;
  final num newBalance;

  WalletTransactionResponse({
    required this.userId,
    required this.newBalance,
  });

  factory WalletTransactionResponse.fromJson(Map<String, dynamic> json) {
    return WalletTransactionResponse(
      userId: json['userId'] ?? '',
      newBalance: json['newBalance'] ?? 0,
    );
  }
}
