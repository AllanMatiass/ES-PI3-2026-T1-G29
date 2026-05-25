// Autor: Allan Giovanni Matias Paes
import 'package:cloud_functions/cloud_functions.dart';
import '../models/api_response.dart';

// Classe abstrata que fornece funcionalidades base para chamadas de API.
abstract class BaseService {
  // Realiza uma chamada para uma Firebase Cloud Function (HTTPS Callable).
  // Gerencia o retorno e converte a resposta para o modelo desejado.
  static Future<ApiResponse<T>> call<T>(
    String functionName, {
    Map<String, dynamic>? data,
    required T Function(dynamic) fromJson,
    FirebaseFunctions? functions,
  }) async {
    final firebaseFunctions = functions ?? FirebaseFunctions.instance;

    try {
      print('🚀 Calling Firebase Function: $functionName with data: $data');
      final HttpsCallable callable =
          firebaseFunctions.httpsCallable(functionName);
      final HttpsCallableResult result = await callable.call(data);

      print('✅ Firebase Function ($functionName) Response Data: ${result.data}');

      // Se result.data for nulo, algo deu muito errado na resposta
      if (result.data == null) {
        return ApiResponse.error('Resposta nula do servidor');
      }

      final responseMap = result.data as Map;

      // O seu backend pode retornar os dados diretamente, dentro de 'result' ou dentro de 'data'.
      dynamic payload = responseMap;
      if (responseMap.containsKey('result')) {
        payload = responseMap['result'];
      } else if (responseMap.containsKey('data')) {
        // Extraímos a chave 'data' se ela for o único wrapper ou se o objetivo for 
        // atingir o payload real em funções que retornam { data: { ... } }
        payload = responseMap['data'];
      }

      print('📦 Payload extracted: $payload');
      final transformedData = fromJson(payload);
      return ApiResponse.success(transformedData);
    } on FirebaseFunctionsException catch (e) {
      print('❌ FirebaseFunctionsException in $functionName:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');

      String? errorCode = e.code;
      if (e.details is Map && e.details['authCode'] != null) {
        errorCode = e.details['authCode'];
      } else if (e.details is Map && e.details['code'] != null) {
        errorCode = e.details['code'].toString();
      }

      return ApiResponse.error(
        e.message ?? 'Erro na Cloud Function',
        errorCode: errorCode,
      );
    } catch (e) {
      print('❌ Unexpected error in $functionName: $e');
      return ApiResponse.error('Falha na chamada: $e');
    }
  }
}
