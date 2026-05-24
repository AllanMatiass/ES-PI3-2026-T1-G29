// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// Classe responsável por gerenciar o estado global do usuário de forma reativa.
class UserState {
  // Notificadores para mudanças no perfil do usuário e no estado de carregamento.
  static final ValueNotifier<UserProfile?> userNotifier = ValueNotifier<UserProfile?>(null);
  static final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  // Getter para obter o usuário atual de forma síncrona.
  static UserProfile? get user => userNotifier.value;

  // Busca novamente os dados do usuário no servidor e atualiza o estado global.
  static Future<void> refreshUser() async {
    // Se já estiver carregando, evita chamadas duplicadas.
    if (isLoadingNotifier.value) return;

    try {
      isLoadingNotifier.value = true;
      final result = await UserService.getUserData();
      if (result.success) {
        userNotifier.value = result.data;
      }
    } catch (e) {
      debugPrint('Erro ao atualizar usuário: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  // Define manualmente um novo perfil de usuário para o estado global.
  static void setUser(UserProfile profile) {
    userNotifier.value = profile;
  }

  // Atualiza manualmente o perfil do usuário para o estado global.
  static void updateUser(UserProfile profile) {
    userNotifier.value = profile;
  }

  // Limpa o estado global do usuário.
  static void clear() {
    userNotifier.value = null;
    isLoadingNotifier.value = false;
  }
}
