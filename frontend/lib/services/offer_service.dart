// Autores:
// Allan Giovanni Matias Paes - 25008211
// Pedro Romanato - 25004075
import '../models/offer.dart';
import '../models/api_response.dart';
import 'base_service.dart';

/// Serviço responsável pelo gerenciamento de ofertas de tokens no Mercado Secundário.
/// Esse mercado permite negociações Peer-to-Peer (P2P), onde usuários compram
/// e vendem tokens entre si, sem passar diretamente pela tesouraria da startup.
class OfferService {
  
  /// Busca a lista global (pública) de ofertas de venda ativas (Mercado Aberto).
  /// Suporta paginação (Infinite Scroll) através de:
  /// - [limit]: Quantidade de ofertas por página.
  /// - [startAfter]: O ID da última oferta recebida (cursor).
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

  /// Busca o histórico consolidado de ofertas criadas pelo usuário autenticado.
  /// Retorna ofertas em todos os estados (Abertas, Canceladas, Expiradas e Finalizadas),
  /// servindo para a tela de gerenciamento de portfólio.
  static Future<ApiResponse<List<Offer>>> getMyOffers() async {
    return BaseService.call<List<Offer>>(
      'getMyOffers',
      data: {},
      fromJson: (responseData) => OfferListResponse.fromJson(responseData).offers,
    );
  }

  /// Publica uma nova intenção de venda (Ask) no mercado secundário.
  /// Ao criar a oferta, o backend congelará (lock) a [qtdTokens] na carteira do 
  /// usuário para evitar gasto duplo (double spending) até a [expiresAt].
  static Future<ApiResponse<Offer>> createOffer({
    required String startupId,
    required int qtdTokens,
    required int tokenPriceCents,
    required DateTime expiresAt,
  }) async {
    return BaseService.call<Offer>(
      'createOffer',
      data: {
        "startupId": startupId,
        "qtdTokens": qtdTokens,
        "tokenPriceCents": tokenPriceCents,
        // Garante a conversão do timezone para evitar bugs de expiração no servidor (Node.js)
        "expiresAt": expiresAt.toUtc().toIso8601String(),
      },
      fromJson: (responseData) => Offer.fromJson(responseData),
    );
  }

  /// Executa o lado comprador (Bid) de uma oferta existente no mercado.
  /// É uma operação transacional: debita saldo do comprador, credita ao vendedor
  /// e transfere a titularidade dos tokens de forma atômica no banco de dados.
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

  /// Solicita ao backend a verificação forçada e a possível transição de estado de uma 
  /// oferta para "Expirada", caso sua validade tenha passado, liberando os tokens trancados.
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

  /// Cancela uma oferta ativa prematuramente por solicitação do usuário criador.
  /// O backend irá estornar os tokens congelados para o saldo livre da carteira.
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
