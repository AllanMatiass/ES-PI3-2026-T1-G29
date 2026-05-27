// Autor: Murilo Rigoni - 25006049
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/base_service.dart';

@GenerateMocks([FirebaseFunctions, HttpsCallable, HttpsCallableResult])
import 'startup_service_test.mocks.dart';

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();

    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
  });

  group('StartupService.getStartupPriceHistory', () {
    test('returns price history on success', () async {
      final mockData = {
        "history": [
          {"timestamp": "2025-12-01T00:00:00Z", "price": 4.53},
          {"timestamp": "2026-01-01T00:00:00Z", "price": 4.92},
        ],
        "summary": {
          "currentPrice": 4.92,
          "highestPrice": 4.92,
          "lowestPrice": 4.53,
          "averagePrice": 4.725,
        },
        "meta": {"count": 2, "currency": "BRL", "interval": "monthly"},
      };

      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn(mockData);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      final result = await BaseService.call<Map<String, dynamic>>(
        'getStartupPriceHistory',
        data: {"id": "ecotech"},
        fromJson: (data) {
          final mapData = Map<String, dynamic>.from(data as Map);
          return {
            'history': (mapData['history'] as List)
                .map((e) => PriceHistoryItem.fromJson(e))
                .toList(),
            'summary': PriceSummary.fromJson(mapData['summary']),
            'meta': PriceMeta.fromJson(mapData['meta']),
          };
        },
        functions: mockFunctions,
      );

      expect(result.success, true);
      expect(result.data!['history'], isA<List<PriceHistoryItem>>());
      expect(result.data!['history'].length, 2);
      expect(result.data!['history'][0].price, 4.53);
      expect(result.data!['summary'], isA<PriceSummary>());
      expect(result.data!['summary'].currentPrice, 4.92);
    });

    test('returns error ApiResponse on failure', () async {
      when(mockCallable.call(any)).thenThrow(
        FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'Error message',
        ),
      );

      final result = await BaseService.call<Map<String, dynamic>>(
        'getStartupPriceHistory',
        data: {"id": "ecotech"},
        fromJson: (_) => {},
        functions: mockFunctions,
      );

      expect(result.success, false);
      expect(result.message, contains('Error message'));
    });
  });

  group('StartupService.listStartups', () {
    test('returns list of startups on success', () async {
      final mockData = {
        "data": {
          "startup1": {
            "name": "EcoTech Solutions",
            "stage": "em_operacao",
            "shortDescription": "Sustainable energy solutions.",
            "capitalRaisedCents": 50000000,
            "totalTokensIssued": 1000000,
            "currentTokenPriceCents": 150,
            "variation": {"percentage": 5.0, "trend": "up"},
            "coverImageUrl": "https://example.com/logo.png",
            "tags": ["energy", "green"],
          },
        },
      };

      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn(mockData);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      final result = await BaseService.call<List<StartupListItem>>(
        'listStartups',
        fromJson: (data) => StartupListResponse.fromJson(data).startups,
        functions: mockFunctions,
      );

      expect(result.success, true);
      expect(result.data, isA<List<StartupListItem>>());
      expect(result.data!.length, 1);
      expect(result.data![0].name, "EcoTech Solutions");
      expect(result.data![0].stage, StartupStage.em_operacao);
    });

    test('returns empty list if no startups found', () async {
      final mockData = {"data": {}};

      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn(mockData);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      final result = await BaseService.call<List<StartupListItem>>(
        'listStartups',
        fromJson: (data) => StartupListResponse.fromJson(data).startups,
        functions: mockFunctions,
      );

      expect(result.success, true);
      expect(result.data, isEmpty);
    });
  });

  group('StartupService.getStartupDetails (FAQ)', () {
    test('returns startup details with questions on success', () async {
      final mockData = {
        "id": "startup1",
        "details": {
          "startup": {
            "name": "EcoTech",
            "stage": "em_operacao",
            "shortDescription": "Desc",
            "description": "Long Desc",
            "coverImageUrl": "logo.png",
            "totalTokensIssued": 1000,
            "circulatingTokens": 500,
            "currentTokenPriceCents": 100,
            "capitalRaisedCents": 10000,
            "executiveSummary": "Summary",
            "lastValuationCents": 20000,
            "createdAt": {"_seconds": 1625097600, "_nanoseconds": 0},
            "updatedAt": {"_seconds": 1625097600, "_nanoseconds": 0},
            "tags": ["energy"],
            "demoVideos": [],
            "founders": [],
            "externalMembers": [],
          },
          "expectedReturn": {"expected": 15.0},
          "risk": {"label": "Médio"},
          "horizon": "5 anos",
          "valuation": 1000000,
        },
        "priceHistory": {
          "history": [],
          "summary": {
            "currentPrice": 1.0,
            "highestPrice": 1.0,
            "lowestPrice": 1.0,
            "averagePrice": 1.0,
          },
          "meta": {"count": 0, "currency": "BRL", "interval": "monthly"},
        },
        "questions": [
          {
            "id": "q1",
            "startupId": "startup1",
            "authorId": "user1",
            "authorEmail": "user@example.com",
            "visibility": "publica",
            "text": "How does it work?",
            "answers": [
              {
                "answer": "It works well.",
                "answeredAt": {"_seconds": 1625100000, "_nanoseconds": 0},
              },
            ],
            "createdAt": {"_seconds": 1625098000, "_nanoseconds": 0},
          },
        ],
        "access": {
          "isInvestor": true,
          "canTradeTokens": true,
          "canSendPrivateQuestions": true,
        },
      };

      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn(mockData);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      final result = await BaseService.call<StartupData>(
        'getStartupDetails',
        data: {"id": "startup1"},
        fromJson: (data) => StartupData.fromJson(data),
        functions: mockFunctions,
      );

      expect(result.success, true);
      expect(result.data!.name, "EcoTech");
      expect(result.data!.questions.length, 1);
      expect(result.data!.questions[0].text, "How does it work?");
      expect(result.data!.questions[0].answers[0].answer, "It works well.");
    });
  });

  group('StartupService.createQuestion', () {
    test('successfully creates a question', () async {
      final mockData = {
        "id": "q2",
        "startupId": "startup1",
        "authorId": "user1",
        "authorEmail": "user@example.com",
        "visibility": "publica",
        "text": "New question?",
        "answers": [],
        "createdAt": {"_seconds": 1625101000, "_nanoseconds": 0},
      };

      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn(mockData);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      final result = await BaseService.call<Question>(
        'createStartupQuestion',
        data: {
          "startupId": "startup1",
          "text": "New question?",
          "visibility": "publica",
        },
        fromJson: (data) => Question.fromJson(data),
        functions: mockFunctions,
      );

      expect(result.success, true);
      expect(result.data!.id, "q2");
      expect(result.data!.text, "New question?");
      expect(result.data!.visibility, "publica");
    });
  });
}
