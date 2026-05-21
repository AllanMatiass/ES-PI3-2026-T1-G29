// Autor: Allan Giovanni Matias Paes

typedef PortfolioRange = String; // "1D" | "1W" | "1M" | "1Y" | "YTD"

/// Representa um ponto no histórico de valorização da carteira.
class PortfolioHistoryPoint {
  final String timestamp;
  final double valueCents;

  PortfolioHistoryPoint({required this.timestamp, required this.valueCents});

  factory PortfolioHistoryPoint.fromJson(Map<String, dynamic> json) {
    return PortfolioHistoryPoint(
      timestamp: json['timestamp'] as String,
      valueCents: (json['valueCents'] as num).toDouble(),
    );
  }
}

/// Resposta da API de valorização de tokens do usuário.
class GetUserTokenValuationsResponse {
  final String range;
  final String currency;
  final double totalValueCents;
  final double variationCents;
  final double variationPercent;
  final List<PortfolioHistoryPoint> history;

  GetUserTokenValuationsResponse({
    required this.range,
    required this.currency,
    required this.totalValueCents,
    required this.variationCents,
    required this.variationPercent,
    required this.history,
  });

  factory GetUserTokenValuationsResponse.fromJson(Map<String, dynamic> json) {
    return GetUserTokenValuationsResponse(
      range: json['range'] as String,
      currency: json['currency'] as String,
      totalValueCents: (json['totalValueCents'] as num).toDouble(),
      variationCents: (json['variationCents'] as num).toDouble(),
      variationPercent: (json['variationPercent'] as num).toDouble(),
      history: (json['history'] as List)
          .map((e) => PortfolioHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
