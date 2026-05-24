// Autor: Allan Giovanni Matias Paes
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// Classe responsável por gerenciar o estado global do usuário de forma reativa.
class UserState {
  // Notificadores para mudanças no perfil do usuário e no estado de carregamento.
  static final ValueNotifier<UserProfile?> userNotifier = ValueNotifier<UserProfile?>(null);
  static final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String?> profilePictureUrlNotifier = ValueNotifier<String?>(null);

  // Getter para obter o usuário atual de forma síncrona.
  static UserProfile? get user => userNotifier.value;

  // Busca novamente os dados do usuário no servidor e atualiza o estado global.
  static Future<void> refreshUser() async {
    // Se já estiver carregando, evita chamadas duplicadas.
    if (isLoadingNotifier.value) return;

    try {
      isLoadingNotifier.value = true;
      final result = await UserService.getUserData();
      if (result.success && result.data != null) {
        userNotifier.value = result.data;
        await _fetchProfilePicture(result.data!.uid);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar usuário: $e');
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  static Future<void> _fetchProfilePicture(String uid) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('users').child(uid).child('profilePicture.jpg');
      final url = await ref.getDownloadURL();
      profilePictureUrlNotifier.value = url;
    } catch (e) {
      // Se não existir a foto, silencia o erro e limpa a URL para mostrar iniciais
      profilePictureUrlNotifier.value = null;
    }
  }

  // Define manualmente um novo perfil de usuário para o estado global.
  static void setUser(UserProfile profile) {
    userNotifier.value = profile;
    _fetchProfilePicture(profile.uid);
  }

  // Atualiza manualmente o perfil do usuário para o estado global.
  static void updateUser(UserProfile profile) {
    userNotifier.value = profile;
    _fetchProfilePicture(profile.uid);
  }

  // Limpa o estado global do usuário.
  static void clear() {
    userNotifier.value = null;
    profilePictureUrlNotifier.value = null;
    isLoadingNotifier.value = false;
  }
}
