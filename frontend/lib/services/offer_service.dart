// Autor: Allan Giovanni Matias Paes
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/offer.dart';
import '../models/api_response.dart';
import 'base_service.dart';

// Serviço responsável pelo gerenciamento de ofertas de tokens no mercado secundário.
class OfferService {
  static const String _getOffersUrl = 'https://getoffers-obpz3whteq-uc.a.run.app';
  static const String _getMyOffersUrl = 'https://getmyoffers-obpz3whteq-uc.a.run.app';
  static const String _createOfferUrl = 'https://createoffer-obpz3whteq-uc.a.run.app';
  static const String _acceptOfferUrl = 'https://acceptoffer-obpz3whteq-uc.a.run.app';
  static const String _expireOfferUrl = 'https://expireoffer-obpz3whteq-uc.a.run.app';

  // Obtém a lista de ofertas globais disponíveis, suportando paginação.
  static Future<ApiResponse<Map<String, dynamic>>> getOffers({
    int limit = 15,
    String? startAfter,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    final Map<String, dynamic> data = {"limit": limit};
    if (startAfter != null) {
      data["startAfter"] = startAfter;
    }

    return BaseService.post<Map<String, dynamic>>(
      _getOffersUrl,
      data: data,
      forceTokenRefresh: true,
      fromJson: (responseData) {
        final List<dynamic> offersJson = responseData['offers'] ?? [];
        final List<OfferWithId> offers = offersJson
            .map((json) => OfferWithId.fromJson(json as Map<String, dynamic>))
            .toList();

        return {
          'offers': offers,
          'lastOfferId': responseData['lastOfferId'],
        };
      },
      client: client,
      auth: auth,
    );
  }

  // Busca as ofertas específicas criadas pelo usuário logado.
  static Future<ApiResponse<List<Map<String, dynamic>>>> getMyOffers({
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<List<Map<String, dynamic>>>(
      _getMyOffersUrl,
      data: {},
      forceTokenRefresh: true,
      fromJson: (responseData) {
        final List<dynamic> offersJson = responseData['offers'] ?? [];
        return List<Map<String, dynamic>>.from(offersJson);
      },
      client: client,
      auth: auth,
    );
  }

  // Cria uma nova oferta de venda de tokens.
  static Future<ApiResponse<OfferWithId>> createOffer({
    required String startupId,
    required int qtdTokens,
    required int tokenPriceCents,
    required DateTime expiresAt,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<OfferWithId>(
      _createOfferUrl,
      data: {
        "startupId": startupId,
        "qtdTokens": qtdTokens,
        "tokenPriceCents": tokenPriceCents,
        "expiresAt": expiresAt.toUtc().toIso8601String(),
      },
      forceTokenRefresh: true,
      fromJson: (responseData) => OfferWithId.fromJson(responseData as Map<String, dynamic>),
      client: client,
      auth: auth,
    );
  }

  // Aceita uma oferta existente, efetuando a troca de tokens/saldo.
  static Future<ApiResponse<Map<String, dynamic>>> acceptOffer({
    required String offerId,
    required int qtdTokens,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<Map<String, dynamic>>(
      _acceptOfferUrl,
      data: {
        "offerId": offerId,
        "qtdTokens": qtdTokens,
      },
      forceTokenRefresh: true,
      fromJson: (responseData) => Map<String, dynamic>.from(responseData as Map),
      client: client,
      auth: auth,
    );
  }

  // Verifica no servidor se uma determinada oferta já expirou.
  static Future<ApiResponse<bool>> isOfferExpired({
    required String offerId,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    return BaseService.post<bool>(
      _expireOfferUrl,
      data: {"offerId": offerId},
      forceTokenRefresh: true,
      fromJson: (responseData) => responseData['expired'] == true,
      client: client,
      auth: auth,
    );
  }
}
