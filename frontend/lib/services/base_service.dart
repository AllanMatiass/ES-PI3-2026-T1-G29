// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:cloud_functions/cloud_functions.dart';
import '../models/api_response.dart';

/// Classe abstrata que atua como a espinha dorsal de comunicação com o backend.
/// Centraliza e padroniza as chamadas para as Firebase Cloud Functions (HTTPS Callables),
/// garantindo consistência no tratamento de erros, logs e parsing de respostas.
abstract class BaseService {
  /// Instância injetável utilizada primordialmente para testes unitários (Mocking).
  static FirebaseFunctions? testFunctionsInstance; 

  /// Executa uma chamada segura para uma Cloud Function específica.
  /// 
  /// [functionName]: O nome exato da função registrada no backend.
  /// [data]: Payload opcional (corpo da requisição) enviado para a função.
  /// [fromJson]: Função de callback (factory) que converte o JSON bruto retornado em um objeto tipado [T].
  /// [functions]: Instância opcional do FirebaseFunctions (usada para override em testes).
  /// Retorna um [ApiResponse] contendo o dado tipado em caso de sucesso, ou detalhes do erro em caso de falha.
  static Future<ApiResponse<T>> call<T>(
    String functionName, {
    Map<String, dynamic>? data,
    required T Function(dynamic) fromJson,
    FirebaseFunctions? functions,
  }) async {
    // Define a instância a ser usada: Injetada > Instância de Teste > Instância Padrão
    final firebaseFunctions = functions ?? testFunctionsInstance ?? FirebaseFunctions.instance;

    try {
      print('[INFO] Calling Firebase Function: $functionName with data: $data');
      
      // Prepara a chamada da função
      final HttpsCallable callable = firebaseFunctions.httpsCallable(functionName);
      
      // Executa a função aguardando o processamento no servidor
      final HttpsCallableResult result = await callable.call(data);

      print('[SUCCESS] Firebase Function ($functionName) Response Data: ${result.data}');

      final responseMap = result.data as Map;

      // Normaliza o payload de resposta, buscando nas chaves padrão 'result' ou 'data'
      // Isso permite certa flexibilidade no formato de retorno do backend.
      dynamic payload = responseMap;
      if (responseMap.containsKey('result')) {
        payload = responseMap['result'];
      } else if (responseMap.containsKey('data')) {
        payload = responseMap['data'];
      }

      print('[INFO] Payload extracted: $payload');

      // Converte o payload JSON para a entidade Dart tipada [T] utilizando a função callback
      final transformedData = fromJson(payload);
      return ApiResponse.success(transformedData);
      
    } on FirebaseFunctionsException catch (e) {
      // Tratamento específico de erros gerados pelo servidor (ex: erros de validação, não autorizado, etc)
      print('[ERROR] FirebaseFunctionsException in $functionName:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');

      // Extrai códigos de erro customizados enviados pelo backend dentro dos 'details'
      String? errorCode = e.code;
      if (e.details is Map && e.details['authCode'] != null) {
        errorCode = e.details['authCode'];
      } else if (e.details is Map && e.details['code'] != null) {
        errorCode = e.details['code'].toString();
      }

      // Retorna o erro envelopado no formato padrão da aplicação
      return ApiResponse.error(
        e.message ?? 'Erro na Cloud Function',
        errorCode: errorCode,
      );
    } catch (e) {
      // Captura erros genéricos (ex: falhas de parsing local, falta de rede)
      print('[ERROR] Unexpected error in $functionName: $e');
      return ApiResponse.error('Falha na chamada: $e');
    }
  }
}
