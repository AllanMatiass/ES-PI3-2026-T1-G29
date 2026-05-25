// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/api_response.dart';
import 'base_service.dart';
import 'user_service.dart';
import '../states/user_state.dart';

class AuthService {
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
      await _syncEmailIfNeeded(user);

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

  static Future<void> _syncEmailIfNeeded(User user) async {
    try {
      final result = await UserService.getUserData(uid: user.uid);
      if (!result.success || result.data == null) return;

      final profile = result.data!;
      UserState.setUser(profile);

      final authEmail = user.email;
      if (authEmail != null && authEmail != profile.email) {
        await BaseService.call<void>(
          'updateUserProfile',
          data: {'email': authEmail},
          fromJson: (_) {},
        );
        UserState.setUser(profile.copyWith(email: authEmail));
      }
    } catch (_) {}
  }

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
        "phone": phone.replaceAll(RegExp(r'\D'), ''),
        "password": password,
      },
      fromJson: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  static bool isAuthenticated() => FirebaseAuth.instance.currentUser != null;

  static User? getCurrentUser() => FirebaseAuth.instance.currentUser;

  static Future<void> signOut([BuildContext? context]) async {
    await FirebaseAuth.instance.signOut();
    UserState.clear();

    if (context != null && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}