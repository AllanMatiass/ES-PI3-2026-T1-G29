import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/offer.dart';
import 'package:frontend/services/offer_service.dart';
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

//  suíte de testes unitários

void main() {
  group('OfferService - Testes Unitários', () {
    
    tearDown(() {
      // limpa a propriedade estática de teste do baseservice após cada execução
      BaseService.testFunctionsInstance = null;
    });

    // massa de dados mockada simulando uma oferta individual estruturada
    final Map<String, dynamic> tOfferItemPayload = {
      'id': 'offer_abc123',
      'startupId': 'startup_tech_99',
      'startupName': 'Quantum Code',
      'seller': {
        'id': 'user_roberto_77',
        'name': 'Roberto',
        'type': 'USER'
      },
      'qtdTokens': 100,
      'remainingQtdTokens': 100,
      'initialQtdTokens': 100,
      'soldQtdTokens': 0,
      'tokenPriceCents': 500.0,
      'totalCents': 50000.0,
      'transactionType': 'USER_TRADE',
      'status': 'OPEN',
      'createdAt': {'_seconds': 1716736123, '_nanoseconds': 0},
      'expiresAt': {'_seconds': 1719328123, '_nanoseconds': 0}
    };

    // teste do método: getOffers
    test('getOffers - deve obter a lista global de ofertas paginadas com sucesso', () async {
      final tResponsePayload = {
        'result': {
          'offers': [tOfferItemPayload],
          'lastOfferId': 'offer_abc123'
        }
      };

      final fakeResult = FakeHttpsCallableResult(tResponsePayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await OfferService.getOffers(limit: 10, startAfter: 'offer_init');

      // assert
      expect(result.success, true);
      expect(result.data, isA<OfferListResponse>());
      expect(result.data!.lastOfferId, 'offer_abc123');
      expect(result.data!.offers.length, 1);
      
      final offer = result.data!.offers.first;
      expect(offer.id, 'offer_abc123');
      expect(offer.seller.name, 'Roberto');
      expect(offer.status, OfferStatus.open);
      expect(offer.transactionType, TransactionType.userTrade);
    });

    // teste do método getMyOffers
    test('getMyOffers - deve retornar a lista de ofertas criadas pelo usuario logado', () async {
      final tResponsePayload = {
        'result': {
          'offers': [tOfferItemPayload],
          'lastOfferId': null
        }
      };

      final fakeResult = FakeHttpsCallableResult(tResponsePayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await OfferService.getMyOffers();

      // assert
      expect(result.success, true);
      expect(result.data, isA<List<OfferWithId>>());
      expect(result.data!.length, 1);
      expect(result.data!.first.seller.name, 'Roberto');
    });

    //  teste do método createOffer
    test('createOffer - deve criar uma nova oferta enviando a data no formato iso8601', () async {
      final fakeResult = FakeHttpsCallableResult({'result': tOfferItemPayload});
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await OfferService.createOffer(
        startupId: 'startup_tech_99',
        qtdTokens: 100,
        tokenPriceCents: 500,
        expiresAt: DateTime(2026, 06, 25),
      );

      // assert
      expect(result.success, true);
      expect(result.data, isA<OfferWithId>());
      expect(result.data!.id, 'offer_abc123');
      expect(result.data!.totalCents, 50000.0);
    });

    // teste do método acceptOffer
    test('acceptOffer - deve aceitar uma oferta e retornar o mapa com os dados da transacao', () async {
      final tAcceptPayload = {
        'result': {
          'transactionId': 'tx_sec_999',
          'buyerId': 'user_buyer_01',
          'tokensExchanged': 50
        }
      };

      final fakeResult = FakeHttpsCallableResult(tAcceptPayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await OfferService.acceptOffer(offerId: 'offer_abc123', qtdTokens: 50);

      // assert
      expect(result.success, true);
      expect(result.data, isA<Map<String, dynamic>>());
      expect(result.data!['transactionId'], 'tx_sec_999');
      expect(result.data!['tokensExchanged'], 50);
    });

    // teste do método isOfferExpired
    test('isOfferExpired - deve validar mapeamento booleano quando a oferta estiver expirada', () async {
      final tExpiredPayload = {
        'result': {
          'expired': true
        }
      };

      final fakeResult = FakeHttpsCallableResult(tExpiredPayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await OfferService.isOfferExpired(offerId: 'offer_abc123');

      // assert
      expect(result.success, true);
      expect(result.data, true);
    });

    // teste do método cancelOffer
    test('cancelOffer - deve validar mapeamento booleano quando a oferta for cancelada', () async {
      final tCancelledPayload = {
        'result': {
          'cancelled': true
        }
      };

      final fakeResult = FakeHttpsCallableResult(tCancelledPayload);
      final fakeCallable = FakeHttpsCallable(resultToReturn: fakeResult);
      BaseService.testFunctionsInstance = FakeFirebaseFunctions(fakeCallable);

      // act
      final result = await OfferService.cancelOffer(offerId: 'offer_abc123');

      // assert
      expect(result.success, true);
      expect(result.data, true);
    });
  });
}