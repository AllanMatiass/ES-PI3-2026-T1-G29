// Autor: Allan Giovanni Matias Paes - 25008211
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

  factory Transaction.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return Transaction(
      id: data['id'] ?? '',
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      buyer: TransactionParticipant.fromJson(data['buyer'] ?? {}),
      seller: TransactionParticipant.fromJson(data['seller'] ?? {}),
      participants: List<String>.from(data['participants'] ?? []),
      qtdTokens: (data['qtdTokens'] as num?)?.toInt() ?? 0,
      tokenPriceCents: (data['tokenPriceCents'] as num?)?.toDouble() ?? 0.0,
      totalCents: (data['totalCents'] as num?)?.toDouble() ?? 0.0,
      transactionType: data['transactionType'] ?? '',
      createdAt: FirestoreTimestamp.fromJson(data['createdAt'] ?? {}),
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

  factory TransactionParticipant.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return TransactionParticipant(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
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

  factory TransactionListResponse.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return TransactionListResponse(
      transactions: (data['transactions'] as List? ?? [])
          .map((e) => Transaction.fromJson(e))
          .toList(),
      lastTransactionId: data['lastTransactionId'],
    );
  }
}
