// Autor: Allan Giovanni Matias Paes
import '../models/startup.dart';
import '../models/api_response.dart';
import 'base_service.dart';

// Serviço responsável pela consulta e interação com os dados das startups.
class StartupService {
  // Lista todas as startups cadastradas no sistema.
  static Future<ApiResponse<List<StartupListItem>>> listStartups() async {
    return BaseService.call<List<StartupListItem>>(
      'listStartups',
      fromJson: (data) => StartupListResponse.fromJson(data).startups,
    );
  }

  // Obtém informações detalhadas de uma startup específica pelo seu ID.
  static Future<ApiResponse<StartupData>> getStartupDetails(String id) async {
    return BaseService.call<StartupData>(
      'getStartupDetails',
      data: {"id": id},
      fromJson: (data) => StartupData.fromJson(data),
    );
  }

  // Busca o histórico de preços dos tokens de uma startup com filtros de intervalo e limite.
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

  // Cria uma nova pergunta direcionada a uma startup.
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

  // Realiza a compra de tokens diretamente da tesouraria da startup.
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
