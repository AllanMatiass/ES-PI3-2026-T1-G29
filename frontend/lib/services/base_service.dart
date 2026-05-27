// Autor: Allan Giovanni Matias Paes
import 'package:cloud_functions/cloud_functions.dart';
import '../models/api_response.dart';


// Classe abstrata que fornece funcionalidades base para chamadas de API.
abstract class BaseService {
  // Realiza uma chamada para uma Firebase Cloud Function (HTTPS Callable).
  // Gerencia o retorno e converte a resposta para o modelo desejado.
  static FirebaseFunctions? testFunctionsInstance; 

  static Future<ApiResponse<T>> call<T>(
    String functionName, {
    Map<String, dynamic>? data,
    required T Function(dynamic) fromJson,
    FirebaseFunctions? functions,
  }) async {
    final firebaseFunctions = functions ?? testFunctionsInstance ?? FirebaseFunctions.instance;

    try {
      print('[INFO] Calling Firebase Function: $functionName with data: $data');
      final HttpsCallable callable =
          firebaseFunctions.httpsCallable(functionName);
      final HttpsCallableResult result = await callable.call(data);

      print('[SUCCESS] Firebase Function ($functionName) Response Data: ${result.data}');

      final responseMap = result.data as Map;

      dynamic payload = responseMap;
      if (responseMap.containsKey('result')) {
        payload = responseMap['result'];
      } else if (responseMap.containsKey('data')) {
        payload = responseMap['data'];
      }

      print('[INFO] Payload extracted: $payload');

      final transformedData = fromJson(payload);
      return ApiResponse.success(transformedData);
    } on FirebaseFunctionsException catch (e) {
      print('[ERROR] FirebaseFunctionsException in $functionName:');
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
      print('[ERROR] Unexpected error in $functionName: $e');
      return ApiResponse.error('Falha na chamada: $e');
    }
  }
}
