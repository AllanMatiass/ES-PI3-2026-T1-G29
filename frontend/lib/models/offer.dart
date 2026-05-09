import './firebase.dart';

enum TransactionType {
  buyFromStartup,
  userTrade;

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

  String toJson() {
    switch (this) {
      case TransactionType.buyFromStartup:
        return 'BUY_FROM_STARTUP';
      case TransactionType.userTrade:
        return 'USER_TRADE';
    }
  }
}

enum OfferStatus {
  open,
  accepted,
  cancelled,
  expired;

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

class TransactionAgent {
  final String id;
  final String name;

  TransactionAgent({required this.id, required this.name});

  factory TransactionAgent.fromJson(Map<String, dynamic> json) {
    return TransactionAgent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class TransactionSeller {
  final String? id;
  final String name;
  final String type; // "USER" | "STARTUP"

  TransactionSeller({this.id, required this.name, required this.type});

  factory TransactionSeller.fromJson(Map<String, dynamic> json) {
    return TransactionSeller(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'USER',
    );
  }
}

class OfferWithId {
  final String id;
  final String startupId;
  final String startupName;
  final TransactionSeller seller;
  final int qtdTokens;
  final int tokenPriceCents;
  final int totalCents;
  final TransactionType transactionType;
  final FirestoreTimestamp createdAt;
  
  final TransactionAgent? buyer;
  final FirestoreTimestamp? expiresAt;
  final OfferStatus status;
  final FirestoreTimestamp? acceptedAt;
  final FirestoreTimestamp? cancelledAt;

  OfferWithId({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.seller,
    required this.qtdTokens,
    required this.tokenPriceCents,
    required this.totalCents,
    required this.transactionType,
    required this.createdAt,
    this.buyer,
    this.expiresAt,
    required this.status,
    this.acceptedAt,
    this.cancelledAt,
  });

  factory OfferWithId.fromJson(Map<String, dynamic> json) {
    return OfferWithId(
      id: json['id'] ?? '',
      startupId: json['startupId'] ?? '',
      startupName: json['startupName'] ?? '',
      seller: TransactionSeller.fromJson(json['seller'] ?? {}),
      qtdTokens: (json['qtdTokens'] as num?)?.toInt() ?? 0,
      tokenPriceCents: (json['tokenPriceCents'] as num?)?.toInt() ?? 0,
      totalCents: (json['totalCents'] as num?)?.toInt() ?? 0,
      transactionType: TransactionType.fromString(json['transactionType'] ?? ''),
      createdAt: json['createdAt'] != null
          ? FirestoreTimestamp.fromJson(json['createdAt'])
          : FirestoreTimestamp(seconds: 0, nanoseconds: 0),
      buyer: json['buyer'] != null ? TransactionAgent.fromJson(json['buyer']) : null,
      expiresAt: json['expiresAt'] != null ? FirestoreTimestamp.fromJson(json['expiresAt']) : null,
      status: OfferStatus.fromString(json['status'] ?? 'OPEN'),
      acceptedAt: json['acceptedAt'] != null ? FirestoreTimestamp.fromJson(json['acceptedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? FirestoreTimestamp.fromJson(json['cancelledAt']) : null,
    );
  }
}
