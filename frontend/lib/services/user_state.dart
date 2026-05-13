import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserState {
  static final ValueNotifier<UserProfile?> userNotifier = ValueNotifier<UserProfile?>(null);
  static final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  static Future<void> refreshUser() async {
    // If already loading, don't start another fetch
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

  static void setUser(UserProfile profile) {
    userNotifier.value = profile;
  }
}
