// Autor: Allan Giovanni Matias Paes

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/api.dart';

class AuthService {
  static const String _signUpUrl =
      'https://signup-obpz3whteq-uc.a.run.app';

  static http.Client _httpClient = http.Client();

  // Set custom client for testing
  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  static Future<ApiResponse<Map<String, dynamic>>> login(
      String email,
      String password,
      ) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: ApiErrorResponse(
            code: 'user-not-found',
            status: 404,
            message: 'Usuário não encontrado',
          ),
        );
      }

      final token = await user.getIdToken();

      return ApiResponse<Map<String, dynamic>>(
        success: true,
        data: {
          "uid": user.uid,
          "name": user.displayName ?? '',
          "token": token ?? '',
        },
      );
    } on FirebaseAuthException catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: ApiErrorResponse(
          code: e.code,
          status: 401,
          message: e.message ?? 'Erro no login',
        ),
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: ApiErrorResponse(
          code: 'unknown-error',
          status: 500,
          message: e.toString(),
        ),
      );
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> signUp({
    required String cpf,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_signUpUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "data": {
            "cpf": cpf,
            "name": name,
            "email": email,
            "phone": phone.replaceAll(RegExp(r'\D'), ''),
            "password": password,
          },
        }),
      );

      final responseData = jsonDecode(response.body);

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        responseData,
            (data) => Map<String, dynamic>.from(data),
      );

      if (apiResponse.success) {
        return apiResponse;
      }

      final isPhoneAlreadyExists =
          apiResponse.error?.code ==
              'auth/phone-number-already-exists';

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: ApiErrorResponse(
          code: apiResponse.error?.code ?? 'signup-error',
          status: apiResponse.error?.status ?? response.statusCode,
          message: isPhoneAlreadyExists
              ? 'Telefone já cadastrado no sistema'
              : apiResponse.error?.message ?? 'Erro desconhecido',
        ),
      );
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: ApiErrorResponse(
          code: 'connection-error',
          status: 500,
          message: 'Falha na conexão: $e',
        ),
      );
    }
  }

  static bool isAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}