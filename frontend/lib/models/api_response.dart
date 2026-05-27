// Autor: Allan Giovanni Matias Paes - 25008211
// Classe genérica para representar a resposta da API.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  // Fábrica para criar uma instância de sucesso com dados.
  factory ApiResponse.success(T data) {
    return ApiResponse(
      success: true,
      data: data,
    );
  }

  // Fábrica para criar uma instância de erro com mensagem e código opcional.
  factory ApiResponse.error(String message, {String? errorCode}) {
    return ApiResponse(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }
}
