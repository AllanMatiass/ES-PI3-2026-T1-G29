// Autor: Allan Giovanni Matias Paes
import './firebase.dart';

// Representa uma transação de tokens no sistema.
class Transaction {
  final String id;
  final String startupId;
  final String startupName;
  final TransactionParticipant buyer;
  final TransactionParticipant seller;
  final List<String> participants;
  final int qtdTokens;
  final double tokenPriceCents;
  final double totalCents;
  final String transactionType;
  final FirestoreTimestamp createdAt;

  Transaction({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.buyer,
    required this.seller,
    required this.participants,
    required this.qtdTokens,
    required this.tokenPriceCents,
    required this.totalCents,
    required this.transactionType,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      startupId: json['startupId'] ?? '',
      startupName: json['startupName'] ?? '',
      buyer: TransactionParticipant.fromJson(json['buyer'] ?? {}),
      seller: TransactionParticipant.fromJson(json['seller'] ?? {}),
      participants: List<String>.from(json['participants'] ?? []),
      qtdTokens: (json['qtdTokens'] as num?)?.toInt() ?? 0,
      tokenPriceCents: (json['tokenPriceCents'] as num?)?.toDouble() ?? 0.0,
      totalCents: (json['totalCents'] as num?)?.toDouble() ?? 0.0,
      transactionType: json['transactionType'] ?? '',
      createdAt: FirestoreTimestamp.fromJson(json['createdAt'] ?? {}),
    );
  }
}

// Representa um participante de uma transação (Comprador ou Vendedor).
class TransactionParticipant {
  final String id;
  final String name;
  final String type;

  TransactionParticipant({
    required this.id,
    required this.name,
    required this.type,
  });

  factory TransactionParticipant.fromJson(Map<String, dynamic> json) {
    return TransactionParticipant(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

// Resposta da API de transações.
class TransactionListResponse {
  final List<Transaction> transactions;
  final String? lastTransactionId;

  TransactionListResponse({
    required this.transactions,
    this.lastTransactionId,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    return TransactionListResponse(
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => Transaction.fromJson(e))
          .toList(),
      lastTransactionId: json['lastTransactionId'],
    );
  }
}
