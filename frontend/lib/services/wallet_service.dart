// Autor: Allan Giovanni Matias Paes - 25008211
import '../models/api_response.dart';
import '../models/portfolio.dart';
import '../models/wallet_transaction.dart';
import './base_service.dart';

/// Serviço responsável exclusivamente pelo gerenciamento de moedas fiduciárias (Real/BRL)
/// na carteira (Wallet) do usuário.
/// Abrange operações de Depósito, Saque, Histórico Financeiro e Métricas de Portfólio.
/// Nota: A compra/venda de Tokens em si é orquestrada pelo [OfferService] e [StartupService].
class WalletService {
  
  /// Busca o extrato de movimentações financeiras (Entradas e Saídas em R$).
  /// Utiliza paginação (Infinite Scroll) via cursores no banco de dados.
  /// 
  /// [limit]: Restringe a quantidade de itens do payload.
  /// [lastMovementId]: Cursor de referência para recuperar o próximo bloco de dados.
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

  /// Recupera o histórico de valorização patrimonial da carteira consolidada do usuário.
  /// Essa métrica calcula o valor total investido versus o valor de mercado atual 
  /// de todos os tokens possuídos pelo usuário no período definido.
  /// 
  /// [range]: Período analisado, ex: '7d' (últimos 7 dias), '1m' (1 mês), '1y' (1 ano).
  static Future<ApiResponse<GetUserTokenValuationsResponse>>
  getPortfolioValuation({required String range}) async {
    return BaseService.call<GetUserTokenValuationsResponse>(
      'getUserTokenValuations',
      data: {'range': range},
      fromJson: (json) => GetUserTokenValuationsResponse.fromJson(json),
    );
  }

  /// Processa uma solicitação de Depósito de fundos (BRL) na conta do aplicativo.
  /// O backend é encarregado de validar os limites e registrar a transação 
  /// como pendente (ex: aguardando pagamento Pix/Boleto) ou processada.
  /// 
  /// [amount]: O valor da operação inserido na UI.
  static Future<ApiResponse<WalletTransactionResponse>> deposit(
      double amount) async {
    return BaseService.call<WalletTransactionResponse>(
      'createDeposit',
      data: WalletTransactionRequest(amount: amount).toJson(),
      fromJson: (json) => WalletTransactionResponse.fromJson(json),
    );
  }

  /// Processa uma solicitação de Saque (Retirada) de fundos para uma conta externa.
  /// O backend atua garantindo de forma atômica que o usuário possui saldo 
  /// livre suficiente antes de deduzir o valor e encaminhar a ordem de pagamento.
  ///
  /// [amount]: O valor a ser sacado da plataforma.
  static Future<ApiResponse<WalletTransactionResponse>> withdraw(
      double amount) async {
    return BaseService.call<WalletTransactionResponse>(
      'createWithdraw',
      data: WalletTransactionRequest(amount: amount).toJson(),
      fromJson: (json) => WalletTransactionResponse.fromJson(json),
    );
  }
}
