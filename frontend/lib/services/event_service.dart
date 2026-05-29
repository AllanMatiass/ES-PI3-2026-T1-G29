// Autor: Allan Giovanni Matias Paes - 25008211
import '../models/event.dart';
import '../models/api_response.dart';
import 'base_service.dart';

/// Serviço responsável pela integração com o backend para buscar eventos,
/// que representam as "Notícias" ou "Acontecimentos" associados às startups.
class EventService {
  
  /// Busca uma lista paginada de eventos (notícias) do sistema.
  ///
  /// Pode ser usado de duas formas:
  /// 1. Global: Passando `startupId` nulo, retorna as notícias de todas as startups.
  /// 2. Filtrado: Passando `startupId`, retorna apenas o feed daquela empresa específica.
  /// 
  /// Os parâmetros [limit] e [lastEventId] permitem implementar a paginação infinita 
  /// (infinite scroll), evitando sobrecarregar o dispositivo com todos os dados de uma vez.
  static Future<ApiResponse<EventPaginatedResponse>> listEvents({
    String? startupId,
    int? limit,
    String? lastEventId,
  }) async {
    final Map<String, dynamic> data = {};
    if (startupId != null) data['startupId'] = startupId;
    if (limit != null) data['limit'] = limit;
    if (lastEventId != null) data['lastEventId'] = lastEventId;

    // Delega a chamada HTTP e o tratamento de erros para a classe base
    return BaseService.call<EventPaginatedResponse>(
      'listEvents',
      data: data,
      // Faz o parser do JSON retornado diretamente para o modelo paginado
      fromJson: (responseData) => EventPaginatedResponse.fromJson(responseData),
    );
  }
}
