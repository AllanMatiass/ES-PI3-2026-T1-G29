import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:frontend/models/event.dart';
import 'package:frontend/services/event_service.dart';
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

void main() {
  group('EventService - Testes Unitários', () {
    tearDown(() {
      // limpa a propriedade estática de teste do baseservice após cada execução
      BaseService.testFunctionsInstance = null;
    });

    // massa de dados mockada simulando um evento estruturado individual
    final Map<String, dynamic> tEventItemPayload = {
      'id': 'event_xyz789',
      'startupId': 'startup_quantum_12',
      'delta': 0.7,
      'title': 'Roberto assume a liderança tecnológica',
      'summary': 'Novo direcionamento focado em arquiteturas distribuídas.',
      'content':
          'O especialista Roberto assume a gestão da equipe de engenharia para acelerar entregas.',
      'tags': ['lideranca', 'tecnologia'],
      'createdAt': {'_seconds': 1716736123, '_nanoseconds': 0},
    };

    // teste do método listEvents (sucesso com parâmetros completos)
    test(
      'listEvents - deve obter a lista de eventos filtrados e paginados com sucesso',
      () async {
        final tResponsePayload = {
          'result': {
            'events': [tEventItemPayload],
            'lastEventId': 'event_xyz789',
          },
        };

        final fakeResult = FakeHttpsCallableResult(tResponsePayload);
        final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // act
        final result = await EventService.listEvents(
          startupId: 'startup_quantum_12',
          limit: 5,
          lastEventId: 'event_init',
        );

        // assert
        expect(result.success, true);
        expect(result.data, isA<EventPaginatedResponse>());
        expect(result.data!.lastEventId, 'event_xyz789');
        expect(result.data!.events.length, 1);

        final event = result.data!.events.first;
        expect(event.id, 'event_xyz789');
        expect(event.startupId, 'startup_quantum_12');
        expect(event.delta, 0.7);
        expect(event.title, contains('Roberto'));
        expect(event.tags, contains('lideranca'));
        expect(event.sentiment, NewsSentiment.excellent);
        expect(event.sentiment.label, 'Excelente');
      },
    );

    //  teste do método listEvents (sucesso com parâmetros nulos / default)
    test(
      'listEvents - deve funcionar perfeitamente quando os filtros opcionais forem nulos',
      () async {
        final tResponsePayload = {
          'result': {
            'events': [tEventItemPayload],
            'lastEventId': null,
          },
        };

        final fakeResult = FakeHttpsCallableResult(tResponsePayload);
        final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // act
        final result = await EventService.listEvents();

        // assert
        expect(result.success, true);
        expect(result.data!.events.isNotEmpty, true);
        expect(result.data!.lastEventId, null);
      },
    );

    // teste de mapeamento de sentimentos baseados no delta
    test(
      'news_sentiment - deve validar todas as faixas do enum newssentiment com base no delta',
      () {
        expect(NewsSentiment.fromDelta(0.7), NewsSentiment.excellent);
        expect(NewsSentiment.fromDelta(0.3), NewsSentiment.good);
        expect(NewsSentiment.fromDelta(0.0), NewsSentiment.neutral);
        expect(NewsSentiment.fromDelta(-0.3), NewsSentiment.bad);
        expect(NewsSentiment.fromDelta(-0.8), NewsSentiment.disaster);

        expect(NewsSentiment.neutral.label, 'Neutra');
        expect(NewsSentiment.disaster.label, 'Desastre');
      },
    );

    // teste do método listEvents (cenário de erro)
    test(
      'listEvents - deve propagar a falha estruturada caso a cloud function retorne erro',
      () async {
        final exception = FirebaseFunctionsException(
          message: 'erro ao consultar o banco de dados de eventos.',
          code: 'unavailable',
          details: {'code': 'timeout'},
        );

        final fakeCallable = FakeHttpsCallable(
          resultToReturn: FakeHttpsCallableResult(null),
          exceptionToThrow: exception,
        );
        BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

        // act
        final result = await EventService.listEvents();

        // assert
        expect(result.success, false);
        expect(result.data, null);
        expect(result.errorCode, 'timeout');
        expect(
          result.message,
          'erro ao consultar o banco de dados de eventos.',
        );
      },
    );
  });
}
