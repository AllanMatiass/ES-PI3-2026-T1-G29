// Autor: Allan Giovanni Matias Paes
import '../models/api_response.dart';
import '../models/transaction.dart';
import './base_service.dart';

// Serviço responsável por gerenciar as transações do usuário.
class TransactionService extends BaseService {
  static const String _baseUrl = 'https://getusertransactions-obpz3whteq-uc.a.run.app';

  // Busca as transações do usuário atual com suporte a paginação.
  static Future<ApiResponse<TransactionListResponse>> getUserTransactions({
    int limit = 10,
    String? lastTransactionId,
  }) async {
    return BaseService.post<TransactionListResponse>(
      _baseUrl,
      data: {
        'limit': limit,
        if (lastTransactionId != null) 'lastTransactionId': lastTransactionId,
      },
      fromJson: (json) => TransactionListResponse.fromJson(json),
    );
  }
}
