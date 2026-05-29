// Autor: Allan Giovanni Matias Paes - 25008211
import '../models/startup.dart';
import '../models/api_response.dart';
import 'base_service.dart';

/// Serviço principal para o domínio de Negócios e Investimentos.
/// Gerencia a listagem, detalhamento, métricas financeiras (histórico de preço)
/// e interações diretas (compra primária, envio de FAQ) vinculadas a uma Startup.
class StartupService {
  
  /// Obtém o catálogo de startups ativas no sistema (Mercado Primário).
  /// Retorna uma lista otimizada `StartupListItem` contendo apenas dados resumidos
  /// (logo, nome, segmento, preço atual do token) para não sobrecarregar a UI de listagem.
  static Future<ApiResponse<List<StartupListItem>>> listStartups() async {
    return BaseService.call<List<StartupListItem>>(
      'listStartups',
      fromJson: (data) => StartupListResponse.fromJson(data).startups,
    );
  }

  /// Busca o perfil completo e dados aprofundados de uma startup específica.
  /// O modelo `StartupData` retornado inclui valuation atualizado, documentos
  /// (pitch deck, plano de negócios), detalhes dos fundadores e FAQ.
  static Future<ApiResponse<StartupData>> getStartupDetails(String id) async {
    return BaseService.call<StartupData>(
      'getStartupDetails',
      data: {"id": id},
      fromJson: (data) => StartupData.fromJson(data),
    );
  }

  /// Consulta a série temporal de preços (Candlestick) do token de uma startup.
  /// 
  /// [historyInterval]: Define a granularidade do gráfico (ex: 'daily', 'weekly', 'monthly').
  /// [historyRange]: Define a janela de tempo (ex: `{"start": "2023-01-01", "end": "2023-12-31"}`).
  /// [historyLimit]: Restringe a quantidade de pontos retornados para economizar banda.
  /// 
  /// O parser customizado separa os pontos do gráfico (`history`), estatísticas gerais 
  /// (`summary` como preço médio, mín, máx) e metadados (`meta`).
  static Future<ApiResponse<Map<String, dynamic>>> getStartupPriceHistory({
    required String id,
    String historyInterval = 'monthly',
    Map<String, String>? historyRange,
    int? historyLimit,
  }) async {
    final Map<String, dynamic> requestData = {
      "id": id,
      "interval": historyInterval,
    };

    if (historyRange != null) {
      requestData["range"] = historyRange;
    }

    if (historyLimit != null) {
      requestData["limit"] = historyLimit;
    }

    return BaseService.call<Map<String, dynamic>>(
      'getStartupPriceHistory',
      data: requestData,
      fromJson: (data) {
        final mapData = Map<String, dynamic>.from(data as Map);
        return {
          'history': (mapData['history'] as List? ?? [])
              .map((e) => PriceHistoryItem.fromJson(e))
              .toList(),
          'summary': PriceSummary.fromJson(mapData['summary']),
          'meta': PriceMeta.fromJson(mapData['meta']),
        };
      },
    );
  }

  /// Registra uma nova dúvida no FAQ oficial da startup.
  /// [visibility] pode ser 'publica' (visível para todos) ou 'privada' (visível apenas para investidores e fundadores).
  static Future<ApiResponse<Question>> createQuestion({
    required String startupId,
    required String text,
    required String visibility,
  }) async {
    return BaseService.call<Question>(
      'createStartupQuestion',
      data: {
        "startupId": startupId,
        "text": text,
        "visibility": visibility,
      },
      fromJson: (data) => Question.fromJson(data),
    );
  }

  /// Processa a aquisição primária de tokens diretamente do tesouro da startup
  /// (Diferente da compra de ofertas que ocorre no mercado secundário P2P).
  ///
  /// O backend valida o saldo da carteira do usuário de forma transacional e
  /// realiza a transferência atômica dos ativos.
  static Future<ApiResponse<void>> buyTokensFromStartup({
    required String startupId,
    required int qtdTokens,
  }) async {
    return BaseService.call<void>(
      'buyTokensFromStartup',
      data: {
        "startupId": startupId,
        "qtdTokens": qtdTokens,
      },
      fromJson: (_) => null,
    );
  }
}
