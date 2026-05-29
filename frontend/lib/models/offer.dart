// Autor: Allan Giovanni Matias Paes - 25008211
import './firebase.dart';

// Enumeração que define os tipos de transação permitidos.
enum TransactionType {
  buyFromStartup,
  userTrade;

  // Converte uma string da API para o tipo TransactionType correspondente.
  static TransactionType fromString(String value) {
    switch (value) {
      case 'BUY_FROM_STARTUP':
        return TransactionType.buyFromStartup;
      case 'USER_TRADE':
        return TransactionType.userTrade;
      default:
        return TransactionType.userTrade;
    }
  }

  // Converte o enum para o formato string esperado pela API.
  String toJson() {
    switch (this) {
      case TransactionType.buyFromStartup:
        return 'BUY_FROM_STARTUP';
      case TransactionType.userTrade:
        return 'USER_TRADE';
    }
  }
}

// Enumeração que define os possíveis estados de uma oferta.
enum OfferStatus {
  open,
  accepted,
  cancelled,
  expired;

  // Converte uma string da API para o status de oferta correspondente.
  static OfferStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return OfferStatus.open;
      case 'ACCEPTED':
        return OfferStatus.accepted;
      case 'CANCELLED':
        return OfferStatus.cancelled;
      case 'EXPIRED':
        return OfferStatus.expired;
      default:
        return OfferStatus.open;
    }
  }

  // Retorna uma representação textual amigável do status.
  String toDisplayString() {
    switch (this) {
      case OfferStatus.open:
        return 'Aberta';
      case OfferStatus.accepted:
        return 'Aceita';
      case OfferStatus.cancelled:
        return 'Cancelada';
      case OfferStatus.expired:
        return 'Expirada';
    }
  }

  String toJson() {
    return name.toUpperCase();
  }
}

// Representa um agente (usuário ou sistema) em uma transação.
class TransactionAgent {
  final String id;
  final String name;

  TransactionAgent({required this.id, required this.name});

  factory TransactionAgent.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return TransactionAgent(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
    );
  }
}

// Representa a entidade que está vendendo tokens.
class TransactionSeller {
  final String? id;
  final String name;
  final String type; // "USER" | "STARTUP"

  TransactionSeller({this.id, required this.name, required this.type});

  factory TransactionSeller.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return TransactionSeller(
      id: data['id'],
      name: data['name'] ?? '',
      type: data['type'] ?? 'USER',
    );
  }
}

// Representa uma oferta com identificador e detalhes completos.
class Offer {
  final String id;
  final String startupId;
  final String startupName;
  final TransactionSeller seller;
  final int qtdTokens;
  final int? remainingQtdTokens;
  final int? initialQtdTokens;
  final int? soldQtdTokens;
  final double tokenPriceCents;
  final double totalCents;
  final double? totalEarnedCents;
  final TransactionType transactionType;
  final FirestoreTimestamp createdAt;
  
  final TransactionAgent? buyer;
  final FirestoreTimestamp? expiresAt;
  final OfferStatus status;
  final FirestoreTimestamp? acceptedAt;
  final FirestoreTimestamp? cancelledAt;

  Offer({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.seller,
    required this.qtdTokens,
    this.remainingQtdTokens,
    this.initialQtdTokens,
    this.soldQtdTokens,
    required this.tokenPriceCents,
    required this.totalCents,
    this.totalEarnedCents,
    required this.transactionType,
    required this.createdAt,
    this.buyer,
    this.expiresAt,
    required this.status,
    this.acceptedAt,
    this.cancelledAt,
  });

  // Converte dados do JSON para uma instância de OfferWithId.
  factory Offer.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return Offer(
      id: data['id'] ?? '',
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      seller: TransactionSeller.fromJson(data['seller'] ?? {}),
      qtdTokens: (data['qtdTokens'] as num?)?.toInt() ?? 0,
      remainingQtdTokens: (data['remainingQtdTokens'] as num?)?.toInt(),
      initialQtdTokens: (data['initialQtdTokens'] as num?)?.toInt(),
      soldQtdTokens: (data['soldQtdTokens'] as num?)?.toInt(),
      tokenPriceCents: (data['tokenPriceCents'] as num?)?.toDouble() ?? 0.0,
      totalCents: (data['totalCents'] as num?)?.toDouble() ?? 0.0,
      totalEarnedCents: (data['totalEarnedCents'] as num?)?.toDouble(),
      transactionType: TransactionType.fromString(data['transactionType'] ?? ''),
      createdAt: data['createdAt'] != null
          ? FirestoreTimestamp.fromJson(data['createdAt'])
          : FirestoreTimestamp(seconds: 0, nanoseconds: 0),
      buyer: data['buyer'] != null ? TransactionAgent.fromJson(data['buyer']) : null,
      expiresAt: data['expiresAt'] != null ? FirestoreTimestamp.fromJson(data['expiresAt']) : null,
      status: OfferStatus.fromString(data['status'] ?? 'OPEN'),
      acceptedAt: data['acceptedAt'] != null ? FirestoreTimestamp.fromJson(data['acceptedAt']) : null,
      cancelledAt: data['cancelledAt'] != null ? FirestoreTimestamp.fromJson(data['cancelledAt']) : null,
    );
  }
}

// Resposta da API de listagem de ofertas.
class OfferListResponse {
  final List<Offer> offers;
  final String? lastOfferId;

  OfferListResponse({required this.offers, this.lastOfferId});

  factory OfferListResponse.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    final List<dynamic> offersJson = data['offers'] ?? [];
    return OfferListResponse(
      offers: offersJson.map((e) => Offer.fromJson(e)).toList(),
      lastOfferId: data['lastOfferId'],
    );
  }
}
