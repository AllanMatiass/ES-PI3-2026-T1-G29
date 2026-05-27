// Autores:
// Allan Giovanni Matias Paes - 25008211
// Pedro Romanato - 25004075
import '../models/offer.dart';
import '../models/api_response.dart';
import 'base_service.dart';

// Serviço responsável pelo gerenciamento de ofertas de tokens no mercado secundário.
class OfferService {
  // Obtém a lista de ofertas globais disponíveis, suportando paginação.
  static Future<ApiResponse<OfferListResponse>> getOffers({
    int limit = 15,
    String? startAfter,
  }) async {
    final Map<String, dynamic> data = {"limit": limit};
    if (startAfter != null) {
      data["startAfter"] = startAfter;
    }

    return BaseService.call<OfferListResponse>(
      'getOffers',
      data: data,
      fromJson: (responseData) => OfferListResponse.fromJson(responseData),
    );
  }

  // Busca as ofertas específicas criadas pelo usuário logado.
  static Future<ApiResponse<List<OfferWithId>>> getMyOffers() async {
    return BaseService.call<List<OfferWithId>>(
      'getMyOffers',
      data: {},
      fromJson: (responseData) => OfferListResponse.fromJson(responseData).offers,
    );
  }

  // Cria uma nova oferta de venda de tokens.
  static Future<ApiResponse<OfferWithId>> createOffer({
    required String startupId,
    required int qtdTokens,
    required int tokenPriceCents,
    required DateTime expiresAt,
  }) async {
    return BaseService.call<OfferWithId>(
      'createOffer',
      data: {
        "startupId": startupId,
        "qtdTokens": qtdTokens,
        "tokenPriceCents": tokenPriceCents,
        "expiresAt": expiresAt.toUtc().toIso8601String(),
      },
      fromJson: (responseData) => OfferWithId.fromJson(responseData),
    );
  }

  // Aceita uma oferta existente, efetuando a troca de tokens/saldo.
  static Future<ApiResponse<Map<String, dynamic>>> acceptOffer({
    required String offerId,
    required int qtdTokens,
  }) async {
    return BaseService.call<Map<String, dynamic>>(
      'acceptOffer',
      data: {
        "offerId": offerId,
        "qtdTokens": qtdTokens,
      },
      fromJson: (responseData) => Map<String, dynamic>.from(responseData as Map),
    );
  }

  // Verifica no servidor se uma determinada oferta já expirou.
  static Future<ApiResponse<bool>> isOfferExpired({
    required String offerId,
  }) async {
    return BaseService.call<bool>(
      'expireOffer',
      data: {"offerId": offerId},
      fromJson: (responseData) {
        final mapData = Map<String, dynamic>.from(responseData as Map);
        return mapData['expired'] == true;
      },
    );
  }

  // Cancela uma oferta
  static Future<ApiResponse<bool>> cancelOffer({
    required String offerId,
  }) async {
    return BaseService.call<bool>(
      'cancelOffer',
      data: {"id": offerId},
      fromJson: (responseData) {
        final mapData = Map<String, dynamic>.from(responseData as Map);
        return mapData['cancelled'] == true;
      },
    );
  }
}
