// Autor: Allan Giovanni Matias Paes
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/startup.dart';

class StartupService {
  static const String _listUrl =
      'https://liststartups-obpz3whteq-uc.a.run.app/';

  static Future<List<StartupListItem>> listStartups() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final token = await user.getIdToken();

    final response = await http.post(
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
  }

  static Future<StartupData> getStartupDetails(String id) async {
    const String url = 'https://getstartupdetails-obpz3whteq-uc.a.run.app';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": {"id": id}}),
      );

      if (response.statusCode == 200) {
        return StartupData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erro ao carregar dados');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
