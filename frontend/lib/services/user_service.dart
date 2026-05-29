// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/api_response.dart';
import 'base_service.dart';

/// Serviço responsável pela gestão e recuperação dos dados de perfil do usuário.
/// Estes dados ficam armazenados no backend (Firestore/Database), de forma separada 
/// dos dados de autenticação mantidos pelo Firebase Auth.
class UserService {
  
  /// Busca o consolidado de dados do usuário (Perfil, Saldo em Conta e Tokens possuídos).
  /// Esta é a principal função chamada ao iniciar a aplicação para preencher o [UserState].
  /// 
  /// Se o parâmetro [uid] não for fornecido, a função utilizará o UID do usuário
  /// atualmente autenticado no Firebase no dispositivo. A Injeção de dependência via
  /// [auth] é suportada primordialmente para testes automatizados.
  static Future<ApiResponse<UserProfile>> getUserData({
    String? uid,
    FirebaseAuth? auth,
  }) async {
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final currentUser = firebaseAuth.currentUser;
    
    // Solicita o perfil completo à Cloud Function 'getUser'
    final res = await BaseService.call<UserProfile>(
      'getUser',
      data: {"uid": uid ?? currentUser?.uid},
      fromJson: (data) => UserProfile.fromJson(data),
    );

    // TRATAMENTO DE CONFLITO DE ESTADO (Firebase Auth vs Database)
    // Pode ocorrer um cenário onde a conta foi criada no Firebase, mas o documento
    // do usuário no banco de dados falhou em ser gerado ou foi deletado manualmente.
    // Aqui nós interceptamos essa falha e sobrescrevemos o 'errorCode' para que a 
    // interface gráfica direcione o usuário corretamente (ex: forçar novo cadastro ou logout).
    if (!res.success && (res.message!.contains("não encontrado") || res.errorCode == 'auth/user-not-found' || res.errorCode == 'not-found')) {
      return ApiResponse.error(
        'Sua conta não foi encontrada no sistema. Por favor, realize o cadastro novamente.',
        errorCode: 'user-not-found',
      );
    }

    return res;
  }
}
