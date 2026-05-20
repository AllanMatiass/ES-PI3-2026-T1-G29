// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import 'base_service.dart';

// Serviço responsável pela autenticação de usuários via Firebase e Cloud Functions.
class AuthService {
  static const String _signUpUrl = 'https://signup-obpz3whteq-uc.a.run.app';

  // Realiza o login do usuário utilizando email e senha através do Firebase Auth.
  static Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return ApiResponse.error("Usuário não encontrado");
      }

      final token = await user.getIdToken();

      return ApiResponse.success({
        "uid": user.uid,
        "name": user.displayName ?? '',
        "token": token!,
      });
    } on FirebaseAuthMultiFactorException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(e.message ?? "Erro no login", errorCode: e.code);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Cria um novo cadastro de usuário invocando a Cloud Function de registro.
  static Future<ApiResponse<Map<String, dynamic>>> signUp({
    required String cpf,
    required String name,
    required String email,
    required String phone,
    required String password,
    http.Client? client,
  }) async {
    return BaseService.post<Map<String, dynamic>>(
      _signUpUrl,
      requiresAuth: false,
      data: {
        "cpf": cpf,
        "name": name,
        "email": email,
        // Remove caracteres não numéricos do telefone antes de enviar.
        "phone": phone.replaceAll(RegExp(r'\D'), ''),
        "password": password,
      },
      fromJson: (data) => data as Map<String, dynamic>,
      client: client,
    );
  }

  // Verifica se existe um usuário autenticado na sessão atual.
  static bool isAuthenticated() => FirebaseAuth.instance.currentUser != null;

  // Retorna o objeto do usuário atualmente logado no Firebase.
  static User? getCurrentUser() => FirebaseAuth.instance.currentUser;

  // Finaliza a sessão do usuário no Firebase.
  static Future<void> signOut() => FirebaseAuth.instance.signOut();
}
