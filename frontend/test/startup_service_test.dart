import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/models/startup.dart';

void main() {
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

      final client = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final result = await StartupService.getStartupPriceHistory(
        id: 'ecotech',
        client: client,
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
      final client = MockClient((request) async {
        return http.Response(jsonEncode({"result": {"success": false}}), 400);
      });

      expect(
        () => StartupService.getStartupPriceHistory(id: 'ecotech', client: client),
        throwsException,
      );
    });
  });
}
