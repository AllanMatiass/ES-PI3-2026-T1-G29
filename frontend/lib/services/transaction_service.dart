// Autor: Allan Giovanni Matias Paes - 25008211
import '../models/api_response.dart';
import '../models/transaction.dart';
import './base_service.dart';

/// Serviço responsável por recuperar o recibo de todas as negociações de tokens
/// (compra ou venda) efetuadas pelo usuário ativo.
/// Observação: Isso difere do WalletService, que gerencia depósitos/saques em Reais.
class TransactionService {
  
  /// Busca o histórico de transações de ativos (tokens) do usuário logado.
  /// 
  /// Agrupa as transações independentemente de terem sido originadas em mercado 
  /// primário (startup) ou secundário (ofertas de outros usuários).
  ///
  /// Utiliza paginação (Infinite Scroll) para otimizar o payload da rede:
  /// - [limit]: Quantidade máxima de registros retornados por requisição (Padrão: 10).
  /// - [lastTransactionId]: O ID da última transação exibida na tela. O backend
  ///   utiliza este ID como cursor para buscar o próximo bloco de registros.
  static Future<ApiResponse<TransactionListResponse>> getUserTransactions({
    int limit = 10,
    String? lastTransactionId,
  }) async {
    return BaseService.call<TransactionListResponse>(
      'getUserTransactions',
      data: {
        'limit': limit,
        if (lastTransactionId != null) 'lastTransactionId': lastTransactionId,
      },
      fromJson: (json) => TransactionListResponse.fromJson(json),
    );
  }
}
