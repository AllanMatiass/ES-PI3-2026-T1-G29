// Autor: Allan Giovanni Matias Paes
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/startup.dart';
import '../models/api_response.dart';
import 'base_service.dart';

// Serviço responsável pela consulta e interação com os dados das startups.
class StartupService {
  static const String _listUrl = 'https://liststartups-obpz3whteq-uc.a.run.app/';
  static const String _detailsUrl = 'https://getstartupdetails-obpz3whteq-uc.a.run.app';
  static const String _priceHistoryUrl = 'https://getstartuppricehistory-obpz3whteq-uc.a.run.app';
  static const String _createQuestionUrl = 'https://createstartupquestion-obpz3whteq-uc.a.run.app';
  static const String _buyTokensUrl = 'https://buytokensfromstartup-obpz3whteq-uc.a.run.app';

  // Lista todas as startups cadastradas no sistema.
  static Future<ApiResponse<List<StartupListItem>>> listStartups({
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<List<StartupListItem>>(
      _listUrl,
      fromJson: (data) {
        final Map<String, dynamic> responseData = data['data'];
        return responseData.entries.map((entry) {
          return StartupListItem.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          );
        }).toList();
      },
      client: client,
      auth: auth,
    );
  }

  // Obtém informações detalhadas de uma startup específica pelo seu ID.
  static Future<ApiResponse<StartupData>> getStartupDetails(
    String id, {
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<StartupData>(
      _detailsUrl,
      data: {"id": id},
      fromJson: (data) => StartupData.fromJson(data as Map<String, dynamic>),
      client: client,
      auth: auth,
    );
  }

  // Busca o histórico de preços dos tokens de uma startup com filtros de intervalo e limite.
  static Future<ApiResponse<Map<String, dynamic>>> getStartupPriceHistory({
    required String id,
    String historyInterval = 'monthly',
    Map<String, String>? historyRange,
    int? historyLimit,
    http.Client? client,
    FirebaseAuth? auth,
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

    return BaseService.post<Map<String, dynamic>>(
      _priceHistoryUrl,
      data: requestData,
      fromJson: (data) {
        return {
          'history': (data['history'] as List? ?? [])
              .map((e) => PriceHistoryItem.fromJson(e))
              .toList(),
          'summary': PriceSummary.fromJson(data['summary']),
          'meta': PriceMeta.fromJson(data['meta']),
        };
      },
      client: client,
      auth: auth,
    );
  }

  // Cria uma nova pergunta direcionada a uma startup.
  static Future<ApiResponse<Question>> createQuestion({
    required String startupId,
    required String text,
    required String visibility,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<Question>(
      _createQuestionUrl,
      data: {
        "startupId": startupId,
        "text": text,
        "visibility": visibility,
      },
      fromJson: (data) => Question.fromJson(data as Map<String, dynamic>),
      client: client,
      auth: auth,
    );
  }

  // Realiza a compra de tokens diretamente da tesouraria da startup.
  static Future<ApiResponse<void>> buyTokensFromStartup({
    required String startupId,
    required int qtdTokens,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<void>(
      _buyTokensUrl,
      data: {
        "startupId": startupId,
        "qtdTokens": qtdTokens,
      },
      fromJson: (_) => null,
      client: client,
      auth: auth,
    );
  }
}
