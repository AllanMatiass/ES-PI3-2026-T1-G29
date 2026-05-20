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

      // Tenta decodificar o JSON com segurança para evitar FormatException (ex: erro HTML 401/403)
      dynamic body;
      try {
        body = jsonDecode(response.body);
      } catch (e) {
        if (response.statusCode == 401) {
          return ApiResponse.error(
            'Não autorizado (401). Verifique se a Cloud Function permite acesso não autenticado ou se o token é válido.',
            errorCode: 'unauthorized',
          );
        }
        if (response.statusCode >= 400) {
          return ApiResponse.error(
            'Erro no servidor (${response.statusCode}). O servidor não retornou um JSON válido.',
          );
        }
        return ApiResponse.error('Falha ao processar resposta do servidor (JSON inválido)');
      }

      final result = body is Map ? body['result'] : null;

      // Verifica o status code e o campo success retornado pela Cloud Function.
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (result != null && result['success'] == false) {
          final error = result['error'];
          return ApiResponse.error(
            error?['message'] ?? 'Erro desconhecido',
            errorCode: error?['code'],
          );
        }

        // Tenta extrair os dados do padrão 'result' ou do corpo diretamente
        final responseData = result is Map ? (result['data'] ?? result) : result;
        final finalData = responseData ?? (body is Map ? (body['data'] ?? body) : body);
        
        return ApiResponse.success(fromJson(finalData));
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
