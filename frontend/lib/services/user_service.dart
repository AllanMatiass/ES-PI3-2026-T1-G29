// Autor: Allan Giovanni Matias Paes
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import 'base_service.dart';

// Serviço responsável pela gestão e recuperação de dados do perfil do usuário.
class UserService {
  static const String _getUserUrl = 'https://getuser-obpz3whteq-uc.a.run.app';

  // Busca os dados completos do perfil e carteira do usuário. 
  // Se o UID não for fornecido, utiliza o do usuário atualmente autenticado.
  static Future<ApiResponse<UserProfile>> getUserData({
    String? uid,
    http.Client? client,
    FirebaseAuth? auth,
  }) async {
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final currentUser = firebaseAuth.currentUser;
    
    return BaseService.post<UserProfile>(
      _getUserUrl,
      data: {"uid": uid ?? currentUser?.uid},
      fromJson: (data) => UserProfile.fromJson(data as Map<String, dynamic>),
      client: client,
      auth: firebaseAuth,
    );
  }
}
