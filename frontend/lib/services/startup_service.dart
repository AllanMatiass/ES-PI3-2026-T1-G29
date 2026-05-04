// Autor: Allan Giovanni Matias Paes
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/startup.dart';

class StartupService {
  static const String _listUrl =
      'https://liststartups-obpz3whteq-uc.a.run.app/';

  static Future<List<StartupListItem>> listStartups({http.Client? client}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse(_listUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"data": {}}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final result = body['result'];

        if (result == null ||
            result['success'] != true ||
            result['data'] == null) {
          return [];
        }

        final Map<String, dynamic> responseData = result['data'];
        final Map<String, dynamic> startupsMap = responseData['data'];

        return startupsMap.entries.map((entry) {
          return StartupListItem.fromJson(
            entry.key,
            entry.value as Map<String, dynamic>,
          );
        }).toList();
      } else {
        throw Exception(
          'Failed to load startups: ${response.statusCode} - ${response.body}',
        );
      }
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<StartupData> getStartupDetails(String id, {http.Client? client}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken();
    const String url = 'https://getstartupdetails-obpz3whteq-uc.a.run.app';
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"data": {"id": id}}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['result']['success'] == true) {
        return StartupData.fromJson(body);
      } else {
        throw Exception('Erro ao carregar dados: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Future<Map<String, dynamic>> getStartupPriceHistory({
    required String id,
    String historyInterval = 'monthly',
    Map<String, String>? historyRange,
    int? historyLimit,
    http.Client? client,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken();
    const String url = 'https://getstartuppricehistory-obpz3whteq-uc.a.run.app';
    final httpClient = client ?? http.Client();

    final Map<String, dynamic> requestData = {
      "id": id,
      "historyInterval": historyInterval,
    };

    if (historyRange != null) {
      requestData["historyRange"] = historyRange;
    }

    if (historyLimit != null) {
      requestData["historyLimit"] = historyLimit;
    }

    try {
      final response = await httpClient.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"data": requestData}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['result']['success'] == true) {
        final data = body['result']['data'];
        return {
          'history': (data['history'] as List? ?? [])
              .map((e) => PriceHistoryItem.fromJson(e))
              .toList(),
          'summary': PriceSummary.fromJson(data['summary']),
          'meta': PriceMeta.fromJson(data['meta']),
        };
      } else {
        throw Exception('Erro ao carregar histórico de preços: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static const String _createQuestionUrl =
      'https://createstartupquestion-obpz3whteq-uc.a.run.app';

  static Future<Question> createQuestion({
    required String startupId,
    required String text,
    required String visibility,
    http.Client? client,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse(_createQuestionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "data": {
            "startupId": startupId,
            "text": text,
            "visibility": visibility,
          }
        }),
      );

      final body = jsonDecode(response.body);
      final result = body['result'];

      if (response.statusCode == 200 &&
          result != null &&
          result['success'] == true) {
        return Question.fromJson(result['data']);
      } else {
        final error = result?['error'];
        final message =
            error?['message'] ?? 'Erro desconhecido ao criar pergunta';
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Erro ao criar pergunta: $e');
    } finally {
      if (client == null) httpClient.close();
    }
  }
}

