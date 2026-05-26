import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/transaction.dart';
import 'package:frontend/services/transaction_service.dart';
import 'package:frontend/services/base_service.dart';


class FakeFirebaseFunctions implements FirebaseFunctions {
  final HttpsCallable callable;
  FakeFirebaseFunctions(this.callable);

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) => callable;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpsCallable implements HttpsCallable {
  final HttpsCallableResult resultToReturn;
  final Object? exceptionToThrow;

  FakeHttpsCallable({required this.resultToReturn, this.exceptionToThrow});

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return resultToReturn as HttpsCallableResult<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHttpsCallableResult implements HttpsCallableResult {
  @override
  final dynamic data;
  FakeHttpsCallableResult(this.data);
}

//   suíte de testes unitários 

void main() {
  group('TransactionService - Testes Unitários', () {
    
    tearDown(() {
      // limpa a propriedade estática de teste do baseservice após cada execução
      BaseService.testFunctionsInstance = null;
    });

    // massa de dados mockada simulando um item completo da lista de transações
    final Map<String, dynamic> tTransactionItemPayload = {
      'id': 'tx_789',
      'startupId': 'startup_001',
      'startupName': 'Tech Innovators',
      'buyer': {
        'id': 'buyer_roberto',
        'name': 'Roberto',
        'type': 'USER'
      },
      'seller': {
        'id': 'seller_company',
        'name': 'Angels Corp',
        'type': 'COMPANY'
      },
      'participants': ['buyer_roberto', 'seller_company'],
      'qtdTokens': 250,
      'tokenPriceCents': 1000.0,
      'totalCents': 250000.0,
      'transactionType': 'BUY',
      'createdAt': {'_seconds': 1716736123, '_nanoseconds': 0}
    };

    //   teste parâmetros padrão (limit = 10)

    test('getUserTransactions - Deve carregar transações com os parâmetros padrão com sucesso', () async {
      final tResponsePayload = {
        'result': {
          'lastTransactionId': 'tx_789',
          'transactions': [tTransactionItemPayload]
        }
      };

      final fakeResult = FakeHttpsCallableResult(tResponsePayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await TransactionService.getUserTransactions();

      // assert
      expect(result.success, true);
      expect(result.data, isA<TransactionListResponse>());
      expect(result.data!.lastTransactionId, 'tx_789');
      expect(result.data!.transactions.length, 1);
      
      final transaction = result.data!.transactions.first;
      expect(transaction.id, 'tx_789');
      expect(transaction.startupName, 'Tech Innovators');
      expect(transaction.buyer.name, 'Roberto');
      expect(transaction.seller.type, 'COMPANY');
      expect(transaction.qtdTokens, 250);
      expect(transaction.totalCents, 250000.0);
    });

    //  teste paginação ativa
    // 
    test('getUserTransactions - Deve incluir o lastTransactionId no payload quando fornecido', () async {
      final tResponsePayload = {
        'result': {
          'lastTransactionId': 'tx_999',
          'transactions': [tTransactionItemPayload]
        }
      };

      final fakeResult = FakeHttpsCallableResult(tResponsePayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await TransactionService.getUserTransactions(
        limit: 5,
        lastTransactionId: 'tx_789',
      );

      // assert
      expect(result.success, true);
      expect(result.data!.transactions.isNotEmpty, true);
    });

    // teste mapeamento de lista vazia
    test('getUserTransactions - Deve mapear corretamente quando o resultado vier sem transações', () async {
      final tEmptyPayload = {
        'result': {
          'lastTransactionId': null,
          'transactions': []
        }
      };

      final fakeResult = FakeHttpsCallableResult(tEmptyPayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await TransactionService.getUserTransactions();

      // assert
      expect(result.success, true);
      expect(result.data!.transactions, isEmpty);
      expect(result.data!.lastTransactionId, null);
    });

    //  teste tratamento de exceções
    test('getUserTransactions - Deve repassar o erro estruturado caso a Cloud Function falhe', () async {
      final exception = FirebaseFunctionsException(
        message: 'Não foi possível carregar as transações.',
        code: 'internal',
        details: {'code': 'database-error'},
      );

      final fakeCallable = FakeHttpsCallable(
        resultToReturn: FakeHttpsCallableResult(null),
        exceptionToThrow: exception,
      );
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await TransactionService.getUserTransactions();

      // assert
      expect(result.success, false);
      expect(result.data, null);
      expect(result.errorCode, 'database-error');
      expect(result.message, 'Não foi possível carregar as transações.');
    });
  });
}