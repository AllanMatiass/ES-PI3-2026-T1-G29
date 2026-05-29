// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/api_response.dart';
import 'base_service.dart';
import 'user_service.dart';
import '../states/user_state.dart';

/// Serviço responsável por gerenciar a autenticação e a sessão do usuário.
/// Atua como uma ponte entre o Firebase Auth (autenticação real) e o backend (dados do perfil).
class AuthService {
  
  /// Autentica o usuário no Firebase com e-mail e senha.
  /// Em caso de sucesso, sincroniza os dados com o backend e atualiza o estado global.
  /// Lança [FirebaseAuthMultiFactorException] caso o usuário tenha o 2FA ativado,
  /// delegando o tratamento para a interface gráfica (`login_page.dart`).
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

      // O token JWT é gerenciado internamente pelo Firebase, mas pode ser
      // usado se o backend precisar validar chamadas diretamente com o Firebase Admin.
      final token = await user.getIdToken();
      await _syncEmailIfNeeded(user);

      return ApiResponse.success({
        "uid": user.uid,
        "name": user.displayName ?? '',
        "token": token!,
      });
    } on FirebaseAuthMultiFactorException {
      // Repassa a exceção para que a UI abra o modal de desafio 2FA (TOTP)
      rethrow;
    } on FirebaseAuthException catch (e) {
      return ApiResponse.error(e.message ?? "Erro no login", errorCode: e.code);
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  /// Sincroniza o e-mail do Firebase com o banco de dados do Mescla Invest.
  /// Isso é útil caso o e-mail seja alterado no Firebase, mas a atualização no backend tenha falhado.
  static Future<void> _syncEmailIfNeeded(User user) async {
    try {
      // Busca o perfil mais recente do banco de dados
      final result = await UserService.getUserData(uid: user.uid);
      if (!result.success || result.data == null) return;

      final profile = result.data!;
      UserState.setUser(profile); // Atualiza o estado global com os dados do banco

      final authEmail = user.email;
      // Compara a fonte de verdade do Firebase com o banco
      if (authEmail != null && authEmail != profile.email) {
        await BaseService.call<void>(
          'updateUserProfile',
          data: {'email': authEmail},
          fromJson: (_) {},
        );
        UserState.setUser(profile.copyWith(email: authEmail));
      }
    } catch (_) {
      // Silencia erros para não impedir o login do usuário caso a sincronização falhe
    }
  }

  /// Registra um novo usuário. A criação real (Firebase + Banco de Dados) 
  /// é orquestrada inteiramente pelo backend através da rota `signup` 
  /// para garantir consistência e executar transações seguras.
  static Future<ApiResponse<Map<String, dynamic>>> signUp({
    required String cpf,
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return BaseService.call<Map<String, dynamic>>(
      'signup',
      data: {
        "cpf": cpf,
        "name": name,
        "email": email,
        // Limpa a formatação visual do telefone antes de enviar
        "phone": phone.replaceAll(RegExp(r'\D'), ''),
        "password": password,
      },
      fromJson: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  /// Verifica de forma síncrona se existe uma sessão ativa no dispositivo.
  static bool isAuthenticated() => FirebaseAuth.instance.currentUser != null;

  /// Retorna a instância atual do usuário do Firebase Auth, se existir.
  static User? getCurrentUser() => FirebaseAuth.instance.currentUser;

  /// Encerra a sessão do usuário.
  /// Limpa os tokens locais do Firebase, zera o estado global (`UserState`) 
  /// e redireciona para a tela de login.
  static Future<void> signOut([BuildContext? context]) async {
    await FirebaseAuth.instance.signOut();
    UserState.clear(); // Limpa os dados em memória (segurança)

    if (context != null && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}