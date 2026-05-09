import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/models/startup.dart';

@GenerateMocks([http.Client, FirebaseAuth, User])
import 'startup_service_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockClient = MockClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.getIdToken()).thenAnswer((_) async => 'fake_token');
  });

  group('StartupService.getStartupPriceHistory', () {
    test('returns price history on success', () async {
      final mockResponse = {
        "result": {
          "success": true,
          "data": {
            "history": [
              {
                "timestamp": "2025-12-01",
                "price": 4.53,
                "variation": null,
                "variationPercent": null
              },
              {
                "timestamp": "2026-01-01",
                "price": 4.92,
                "variation": 0.39,
                "variationPercent": 8.6
              }
            ],
            "summary": {
              "currentPrice": 4.92,
              "highestPrice": 4.92,
              "lowestPrice": 4.53,
              "averagePrice": 4.725
            },
            "meta": {
              "count": 2,
              "currency": "BRL",
              "interval": "monthly"
            }
          }
        }
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await StartupService.getStartupPriceHistory(
        id: 'ecotech',
        client: mockClient,
        auth: mockAuth,
      );

      expect(result['history'], isA<List<PriceHistoryItem>>());
      expect(result['history'].length, 2);
      expect(result['history'][0].price, 4.53);
      expect(result['history'][1].price, 4.92);
      expect(result['summary'], isA<PriceSummary>());
      expect(result['summary'].currentPrice, 4.92);
      expect(result['meta'].currency, 'BRL');
    });

    test('throws exception on error', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode({"result": {"success": false}}), 400));

      expect(
        () => StartupService.getStartupPriceHistory(id: 'ecotech', client: mockClient, auth: mockAuth),
        throwsException,
      );
    });
  });

  group('StartupService.listStartups', () {
    test('returns list of startups on success', () async {
      final mockResponse = {
        "result": {
          "success": true,
          "data": {
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
                "tags": ["energy", "green"]
              }
            }
          }
        }
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await StartupService.listStartups(
        client: mockClient,
        auth: mockAuth,
      );

      expect(result, isA<List<StartupListItem>>());
      expect(result.length, 1);
      expect(result[0].name, "EcoTech Solutions");
      expect(result[0].stage, StartupStage.em_operacao);
    });

    test('returns empty list if no startups found', () async {
      final mockResponse = {
        "result": {
          "success": true,
          "data": {"data": {}}
        }
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await StartupService.listStartups(
        client: mockClient,
        auth: mockAuth,
      );

      expect(result, isEmpty);
    });
  });

  group('StartupService.getStartupDetails (FAQ)', () {
    test('returns startup details with questions on success', () async {
      final mockResponse = {
        "result": {
          "success": true,
          "data": {
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
                "externalMembers": []
              },
              "expectedReturn": {"expected": 15.0},
              "risk": {"label": "Médio"},
              "horizon": "5 anos",
              "valuation": 1000000
            },
            "priceHistory": {
              "history": [],
              "summary": {
                "currentPrice": 1.0,
                "highestPrice": 1.0,
                "lowestPrice": 1.0,
                "averagePrice": 1.0
              },
              "meta": {"count": 0, "currency": "BRL", "interval": "monthly"}
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
                    "answeredAt": {"_seconds": 1625100000, "_nanoseconds": 0}
                  }
                ],
                "createdAt": {"_seconds": 1625098000, "_nanoseconds": 0}
              }
            ],
            "access": {
              "isInvestor": true,
              "canTradeTokens": true,
              "canSendPrivateQuestions": true
            }
          }
        }
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await StartupService.getStartupDetails(
        "startup1",
        client: mockClient,
        auth: mockAuth,
      );

      expect(result.name, "EcoTech");
      expect(result.questions.length, 1);
      expect(result.questions[0].text, "How does it work?");
      expect(result.questions[0].answers[0].answer, "It works well.");
    });
  });

  group('StartupService.createQuestion', () {
    test('successfully creates a question', () async {
      final mockResponse = {
        "result": {
          "success": true,
          "data": {
            "id": "q2",
            "startupId": "startup1",
            "authorId": "user1",
            "authorEmail": "user@example.com",
            "visibility": "publica",
            "text": "New question?",
            "answers": [],
            "createdAt": {"_seconds": 1625101000, "_nanoseconds": 0}
          }
        }
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await StartupService.createQuestion(
        startupId: "startup1",
        text: "New question?",
        visibility: "publica",
        client: mockClient,
        auth: mockAuth,
      );

      expect(result.id, "q2");
      expect(result.text, "New question?");
      expect(result.visibility, "publica");
    });

    test('throws exception on error with message', () async {
      final mockResponse = {
        "result": {
          "success": false,
          "error": {"message": "Unauthorized"}
        }
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 400));

      expect(
        () => StartupService.createQuestion(
          startupId: "startup1",
          text: "Fail",
          visibility: "publica",
          client: mockClient,
          auth: mockAuth,
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Unauthorized'))),
      );
    });
  });
}
