// Autor: Allan Giovanni Matias Paes
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/api_response.dart';

// Classe abstrata que fornece funcionalidades base para chamadas de API.
abstract class BaseService {
  // Realiza uma requisição HTTP POST genérica. 
  // Gerencia o token de autenticação do Firebase e converte a resposta para o modelo desejado.
  static Future<ApiResponse<T>> post<T>(
    String url, {
    Map<String, dynamic>? data,
    required T Function(dynamic) fromJson,
    http.Client? client,
    FirebaseAuth? auth,
    bool forceTokenRefresh = false,
    bool requiresAuth = true,
  }) async {
    final httpClient = client ?? http.Client();

    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Adiciona o token Bearer se a rota exigir autenticação.
      if (requiresAuth) {
        final firebaseAuth = auth ?? FirebaseAuth.instance;
        final user = firebaseAuth.currentUser;
        if (user == null) {
          return ApiResponse.error('Usuário não autenticado');
        }
        final token = await user.getIdToken(forceTokenRefresh);
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({"data": data ?? {}}),
      );

      if (response.body.isEmpty) {
        return ApiResponse.error('Resposta vazia do servidor');
      }

      final body = jsonDecode(response.body);
      final result = body['result'];

      // Verifica o status code e o campo success retornado pela Cloud Function.
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result != null && result['success'] == false) {
          final error = result['error'];
          return ApiResponse.error(
            error?['message'] ?? 'Erro desconhecido',
            errorCode: error?['code'],
          );
        }

        final responseData = result is Map ? (result['data'] ?? result) : result;
        return ApiResponse.success(fromJson(responseData));
      } else {
        final error = result is Map ? result['error'] : null;
        return ApiResponse.error(
          error?['message'] ?? 'Erro na requisição: ${response.statusCode}',
          errorCode: error?['code'],
        );
      }
    } catch (e) {
      return ApiResponse.error('Falha na conexão: $e');
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
