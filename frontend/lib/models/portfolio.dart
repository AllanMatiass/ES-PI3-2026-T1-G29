// Autor: Allan Giovanni Matias Paes - 25008211

typedef PortfolioRange = String; // "1D" | "1W" | "1M" | "1Y" | "YTD"

/// Representa um ponto no histórico de valorização da carteira.
class PortfolioHistoryPoint {
  final String timestamp;
  final double valueCents;

  PortfolioHistoryPoint({required this.timestamp, required this.valueCents});

  factory PortfolioHistoryPoint.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return PortfolioHistoryPoint(
      timestamp: data['timestamp'] as String,
      valueCents: (data['valueCents'] as num).toDouble(),
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

  factory GetUserTokenValuationsResponse.fromJson(dynamic json) {
    final data = Map<String, dynamic>.from(json as Map);
    return GetUserTokenValuationsResponse(
      range: data['range'] as String,
      currency: data['currency'] as String,
      totalValueCents: (data['totalValueCents'] as num).toDouble(),
      variationCents: (data['variationCents'] as num).toDouble(),
      variationPercent: (data['variationPercent'] as num).toDouble(),
      history: (data['history'] as List)
          .map((e) => PortfolioHistoryPoint.fromJson(e))
          .toList(),
    );
  }
}
