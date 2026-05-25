// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import 'base_service.dart';

// Serviço responsável pela gestão e recuperação de dados do perfil do usuário.
class UserService {
  // Busca os dados completos do perfil e carteira do usuário. 
  // Se o UID não for fornecido, utiliza o do usuário atualmente autenticado.
  static Future<ApiResponse<UserProfile>> getUserData({
    String? uid,
    FirebaseAuth? auth,
  }) async {
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final currentUser = firebaseAuth.currentUser;
    
    final res = await BaseService.call<UserProfile>(
      'getUser',
      data: {"uid": uid ?? currentUser?.uid},
      fromJson: (data) => UserProfile.fromJson(data),
    );

    // Se o erro for de usuário não encontrado, marcamos o errorCode para tratamento na UI.
    if (!res.success && (res.message!.contains("não encontrado") || res.errorCode == 'auth/user-not-found' || res.errorCode == 'not-found')) {
      return ApiResponse.error(
        'Sua conta não foi encontrada no sistema. Por favor, realize o cadastro novamente.',
        errorCode: 'user-not-found',
      );
    }

    return res;
  }
}
