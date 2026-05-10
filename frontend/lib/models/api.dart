// Autor: Allan Giovanni Matias Paes

class ApiErrorResponse {
  final String code;
  final int status;
  final String message;

  ApiErrorResponse({
    required this.code,
    required this.status,
    required this.message,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      code: json['code'] ?? '',
      status: json['status'] ?? 0,
      message: json['message'] ?? 'Erro desconhecido',
    );
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiErrorResponse? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic json)? fromJsonT,
      ) {
    final result = json['result'];

    return ApiResponse<T>(
      success: result['success'] ?? false,
      data: result['data'] != null && fromJsonT != null
          ? fromJsonT(result['data'])
          : null,
      error: result['error'] != null
          ? ApiErrorResponse.fromJson(result['error'])
          : null,
    );
  }
}