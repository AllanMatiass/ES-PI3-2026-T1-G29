import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:frontend/models/portfolio.dart';
import 'package:frontend/models/wallet_transaction.dart';
import 'package:frontend/services/wallet_service.dart';
import 'package:frontend/services/base_service.dart';

class FakeFirebaseFunctions implements FirebaseFunctions {
  final HttpsCallable callable;
  FakeFirebaseFunctions(this.callable);

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      callable;

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

// SUÍTE DE TESTES UNITÁRIOS

void main() {
  group('WalletService - Testes Unitários', () {
    tearDown(() {
      // Garante que a instância estática de teste do BaseService seja limpa entre os testes
      BaseService.testFunctionsInstance = null;
    });

    // teste do  metodo getUserMovements
    test(
      'getUserMovements - Deve mapear o histórico de movimentações paginadas com sucesso',
      () async {
        // Payload mockado imitando o retorno estruturado da Cloud Function para PaginatedMovementsResponse
        final tMovementsPayload = {
          'result': {
            'lastMovementId': 'mov_abc123',
            'movements': [
              {
                'type': 'DEPOSIT',
                'amountInCents': 5000,
                'createdAt': {'_seconds': 1716736123, '_nanoseconds': 0},
              },
              {
                'type': 'WITHDRAW',
                'amountInCents': 2000,
                'createdAt': {'_seconds': 1716736150, '_nanoseconds': 0},
              },
            ],
          },
        };

        final fakeResult = FakeHttpsCallableResult(tMovementsPayload);
        final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // Act
        final result = await WalletService.getUserMovements(
          limit: 10,
          lastMovementId: 'mov_init',
        );

        // Assert
        expect(result.success, true);
        expect(result.data, isA<PaginatedMovementsResponse>());
        expect(result.data!.lastMovementId, 'mov_abc123');
        expect(result.data!.movements.length, 2);
        expect(result.data!.movements.first.type, 'DEPOSIT');
        expect(result.data!.movements.first.amountInCents, 5000);
      },
    );

    //teste do metodo getPortfolioValuation

    test(
      'getPortfolioValuation - Deve converter os pontos gráficos e variação da carteira com sucesso',
      () async {
        // Payload mockado imitando GetUserTokenValuationsResponse
        final tPortfolioPayload = {
          'result': {
            'range': '1M',
            'currency': 'BRL',
            'totalValueCents': 150000.0,
            'variationCents': 4500.0,
            'variationPercent': 3.1,
            'history': [
              {'timestamp': '2026-05-01', 'valueCents': 145500.0},
              {'timestamp': '2026-05-26', 'valueCents': 150000.0},
            ],
          },
        };

        final fakeResult = FakeHttpsCallableResult(tPortfolioPayload);
        final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // Act
        final result = await WalletService.getPortfolioValuation(range: '1M');

        // Assert
        expect(result.success, true);
        expect(result.data, isA<GetUserTokenValuationsResponse>());
        expect(result.data!.range, '1M');
        expect(result.data!.currency, 'BRL');
        expect(result.data!.totalValueCents, 150000.0);
        expect(result.data!.history.length, 2);
        expect(result.data!.history.last.timestamp, '2026-05-26');
      },
    );

    //teste do metodo deposit

    test(
      'deposit - Deve processar um depósito e retornar o novo saldo do usuário',
      () async {
        // Payload de resposta imitando WalletTransactionResponse
        final tTransactionPayload = {
          'result': {'userId': 'user_allan_99', 'newBalance': 35000.0},
        };

        final fakeResult = FakeHttpsCallableResult(tTransactionPayload);
        final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // Act
        final result = await WalletService.deposit(150.0);

        // Assert
        expect(result.success, true);
        expect(result.data, isA<WalletTransactionResponse>());
        expect(result.data!.userId, 'user_allan_99');
        expect(result.data!.newBalance, 35000.0);
      },
    );

    // teste do metodo withdraw

    test(
      'withdraw - Deve processar um saque com sucesso e atualizar o saldo',
      () async {
        final tTransactionPayload = {
          'result': {'userId': 'user_allan_99', 'newBalance': 10000.0},
        };

        final fakeResult = FakeHttpsCallableResult(tTransactionPayload);
        final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // Act
        final result = await WalletService.withdraw(50.0);

        // Assert
        expect(result.success, true);
        expect(result.data, isA<WalletTransactionResponse>());
        expect(result.data!.newBalance, 10000.0);
      },
    );

    // teste do cenario de erro

    test(
      'withdraw - Deve propagar erro amigável em caso de falha controlada na Cloud Function',
      () async {
        // Criando uma exceção do Firebase Cloud Functions (Ex: Saldo Insuficiente)
        final exception = FirebaseFunctionsException(
          message: 'Saldo em conta insuficiente para concluir o saque.',
          code: 'failed-precondition',
          details: {'code': 'insufficient-funds'},
        );

        final fakeCallable = FakeHttpsCallable(
          resultToReturn: FakeHttpsCallableResult(null),
          exceptionToThrow: exception,
        );
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // Act
        final result = await WalletService.withdraw(50000.0);

        // Assert
        expect(result.success, false);
        expect(result.data, null);
        expect(
          result.errorCode,
          'insufficient-funds',
        ); // Verificando extração dinâmica e detalhada do BaseService
        expect(
          result.message,
          'Saldo em conta insuficiente para concluir o saque.',
        );
      },
    );
  });
}
