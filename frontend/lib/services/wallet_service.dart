// Autor: Allan Giovanni Matias Paes
import '../models/api_response.dart';
import '../models/portfolio.dart';
import './base_service.dart';

/// Serviço responsável por gerenciar dados da carteira do usuário.
class WalletService extends BaseService {
  static const String _valuationUrl =
      'https://getusertokenvaluations-obpz3whteq-uc.a.run.app';

  /// Busca o histórico de valorização da carteira do usuário.
  static Future<ApiResponse<GetUserTokenValuationsResponse>>
  getPortfolioValuation({required String range}) async {
    return BaseService.post<GetUserTokenValuationsResponse>(
      _valuationUrl,
      data: {'range': range},
      fromJson: (json) => GetUserTokenValuationsResponse.fromJson(json),
    );
  }
}
