// Autor: Allan Giovanni Matias Paes
enum StartupStage {
  nova,
  em_operacao,
  em_expansao;

  static StartupStage fromString(String value) {
    switch (value) {
      case 'nova':
        return StartupStage.nova;
      case 'em_operacao':
        return StartupStage.em_operacao;
      case 'em_expansao':
        return StartupStage.em_expansao;
      default:
        throw ArgumentError('Invalid StartupStage: $value');
    }
  }

  String toDisplayString() {
    switch (this) {
      case StartupStage.nova:
        return 'Nova';
      case StartupStage.em_operacao:
        return 'Em Operação';
      case StartupStage.em_expansao:
        return 'Em Expansão';
    }
  }
}

class StartupListItem {
  final String id;
  final String name;
  final StartupStage stage;
  final String shortDescription;
  final int capitalRaisedCents;
  final int totalTokensIssued;
  final int currentTokenPriceCents;
  final double? priceVariation;
  final String priceVariationTrend;
  final String? coverImageUrl;
  final List<String> tags;

  StartupListItem({
    required this.id,
    required this.name,
    required this.stage,
    required this.shortDescription,
    required this.capitalRaisedCents,
    required this.totalTokensIssued,
    required this.currentTokenPriceCents,
    required this.priceVariation,
    required this.priceVariationTrend,
    this.coverImageUrl,
    required this.tags,
  });

  factory StartupListItem.fromJson(String id, Map<String, dynamic> json) {
    return StartupListItem(
      id: id,
      name: json['name'] as String,
      stage: StartupStage.fromString(json['stage'] as String),
      shortDescription: json['shortDescription'] as String,
      capitalRaisedCents: json['capitalRaisedCents'] as int,
      totalTokensIssued: json['totalTokensIssued'] as int,
      currentTokenPriceCents: json['currentTokenPriceCents'] as int,
      priceVariation: json['variation']['percentage'] ?.toDouble(),
      priceVariationTrend: json['variation']['trend'],
      coverImageUrl: json['coverImageUrl'] as String?,
      tags: List<String>.from(json['tags'] as List),
    );
  }

}

