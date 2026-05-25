// Autor: Allan Giovanni Matias Paes
import '../models/api_response.dart';
import '../models/portfolio.dart';
import '../models/wallet_transaction.dart';
import './base_service.dart';

/// Serviço responsável por gerenciar dados da carteira do usuário.
class WalletService {
  /// Busca o histórico de movimentações financeiras (depósitos e saques) do usuário.
  static Future<ApiResponse<PaginatedMovementsResponse>> getUserMovements({
    int? limit,
    String? lastMovementId,
  }) async {
    return BaseService.call<PaginatedMovementsResponse>(
      'getUserMovements',
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
    return BaseService.call<GetUserTokenValuationsResponse>(
      'getUserTokenValuations',
      data: {'range': range},
      fromJson: (json) => GetUserTokenValuationsResponse.fromJson(json),
    );
  }

  /// Realiza um depósito na carteira do usuário.
  static Future<ApiResponse<WalletTransactionResponse>> deposit(
      double amount) async {
    return BaseService.call<WalletTransactionResponse>(
      'createDeposit',
      data: WalletTransactionRequest(amount: amount).toJson(),
      fromJson: (json) => WalletTransactionResponse.fromJson(json),
    );
  }

  /// Realiza um saque da carteira do usuário.
  static Future<ApiResponse<WalletTransactionResponse>> withdraw(
      double amount) async {
    return BaseService.call<WalletTransactionResponse>(
      'createWithdraw',
      data: WalletTransactionRequest(amount: amount).toJson(),
      fromJson: (json) => WalletTransactionResponse.fromJson(json),
    );
  }
}
