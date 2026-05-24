// Autor: Allan Giovanni Matias Paes
import '../models/api_response.dart';
import '../models/portfolio.dart';
import '../models/wallet_transaction.dart';
import './base_service.dart';

/// Serviço responsável por gerenciar dados da carteira do usuário.
class WalletService extends BaseService {
  static const String _valuationUrl =
      'https://getusertokenvaluations-obpz3whteq-uc.a.run.app';
  static const String _depositUrl =
      'https://createdeposit-obpz3whteq-uc.a.run.app';
  static const String _withdrawUrl =
      'https://createwithdraw-obpz3whteq-uc.a.run.app';
  static const String _movementsUrl =
      'https://getusermovements-obpz3whteq-uc.a.run.app';

  /// Busca o histórico de movimentações financeiras (depósitos e saques) do usuário.
  static Future<ApiResponse<PaginatedMovementsResponse>> getUserMovements({
    int? limit,
    String? lastMovementId,
  }) async {
    return BaseService.post<PaginatedMovementsResponse>(
      _movementsUrl,
      data: {
        if (limit != null) 'limit': limit,
        if (lastMovementId != null) 'lastMovementId': lastMovementId,
      },
      fromJson: (json) => PaginatedMovementsResponse.fromJson(json),
    );
  }

  /// Busca o histórico de valorização da carteira do usuário.
  static Future<ApiResponse<GetUserTokenValuationsResponse>>
  getPortfolioValuation({required String range}) async {
    return BaseService.post<GetUserTokenValuationsResponse>(
      _valuationUrl,
      data: {'range': range},
      fromJson: (json) => GetUserTokenValuationsResponse.fromJson(json),
    );
  }

  /// Realiza um depósito na carteira do usuário.
  static Future<ApiResponse<WalletTransactionResponse>> deposit(
      double amount) async {
    return BaseService.post<WalletTransactionResponse>(
      _depositUrl,
      data: WalletTransactionRequest(amount: amount).toJson(),
      fromJson: (json) => WalletTransactionResponse.fromJson(json),
    );
  }

  /// Realiza um saque da carteira do usuário.
  static Future<ApiResponse<WalletTransactionResponse>> withdraw(
      double amount) async {
    return BaseService.post<WalletTransactionResponse>(
      _withdrawUrl,
      data: WalletTransactionRequest(amount: amount).toJson(),
      fromJson: (json) => WalletTransactionResponse.fromJson(json),
    );
  }
}
