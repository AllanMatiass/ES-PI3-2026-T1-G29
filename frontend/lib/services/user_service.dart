import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String _getUserUrl = 'https://getuser-obpz3whteq-uc.a.run.app';
  static http.Client _httpClient = http.Client();

  // Set custom client for testing
  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  static Future<Map<String, dynamic>> getUserData(String uid, String token) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_getUserUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "data": {
            "uid": uid,
          },
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['result'] != null &&
            responseData['result']['success'] == true) {
          return {
            "success": true,
            "data": UserData.fromJson(responseData),
          };
        } else {
          return {
            "success": false,
            "error": responseData['result']?['error']?['message'] ?? 'Erro desconhecido',
            "code": responseData['result']?['error']?['code'],
          };
        }
      } else {
        return {
          "success": false,
          "error": responseData['result']?['error']?['message'] ??
              'Erro na requisição: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {"success": false, "error": "Falha na conexão: $e"};
    }
  }
}
