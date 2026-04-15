import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _signUpUrl = 'https://signup-obpz3whteq-uc.a.run.app';
  static http.Client _httpClient = http.Client();

  // Set custom client for testing
  static void setHttpClient(http.Client client) {
    _httpClient = client;
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception("User not found");
      }

      final token = await user.getIdToken();

      return {
        "success": true,
        "uid": user.uid,
        "name": user.displayName ?? '',
        "token": token!
      };
    } on FirebaseAuthException catch (e) {

      return {
        "success": false,
        "error": e.message ?? "Erro no login"
      };
    } catch (e) {
      return {
        "success": false,
        "error": e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> signUp({
    required String cpf,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_signUpUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "data": {
            "cpf": cpf,
            "name": name,
            "email": email,
            "phone": phone.replaceAll(RegExp(r'\D'), ''),
            "password": password
          }
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['result'] != null && responseData['result']['success'] == true) {
          return {
            "success": true,
            "data": responseData['result']['data']
          };
        } else {
          final phoneAlreadyExist = responseData['result']?['error']?['code'] == 'auth/phone-number-already-exists';
          return {
            "success": false,
            "error": phoneAlreadyExist ? 'Telefone já cadastrado no sistema' : responseData['result']?['error']?['message']  ?? 'Erro desconhecido'
          };
        }
      } else {
        return {
          "success": false,
          "error": responseData['result']?['error']?['message'] ?? 'Erro na requisição: ${response.statusCode}'
        };
      }
    } catch (e) {

      return {
        "success": false,
        "error": "Falha na conexão: $e"
      };
    }
  }

  static bool isAuthenticated() => FirebaseAuth.instance.currentUser != null;
  
  static User? getCurrentUser() => FirebaseAuth.instance.currentUser;

  static Future<void> signOut() => FirebaseAuth.instance.signOut();
}