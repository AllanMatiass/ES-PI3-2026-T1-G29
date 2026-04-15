import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:frontend/services/auth.dart';

// Generate a MockClient using Mockito
@GenerateMocks([http.Client])
import 'auth_service_test.mocks.dart';

void main() {
  late MockClient mockClient;

  setUp(() {
    mockClient = MockClient();
    AuthService.setHttpClient(mockClient);
  });

  group('AuthService.signUp', () {
    const signUpUrl = 'https://signup-obpz3whteq-uc.a.run.app';

    test('returns success map when the call is successful', () async {
      final successResponse = {
        "result": {
          "success": true,
          "data": {
            "uid": "LP2zQlJx54N9NPYwiwMQfLADIdC3",
            "name": "Matias",
            "email": "matias3@22e.com"
          }
        }
      };

      when(mockClient.post(
        Uri.parse(signUpUrl),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(successResponse), 200));

      final result = await AuthService.signUp(
        cpf: "881.973.540-73",
        name: "Matias",
        email: "matias3@22e.com",
        phone: "11930541768",
        password: "123456"
      );

      expect(result['success'], true);
      expect(result['data']['name'], "Matias");
      expect(result['data']['email'], "matias3@22e.com");
    });

    test('returns error map when the CPF already exists', () async {
      final errorResponse = {
        "result": {
          "success": false,
          "error": {
            "code": "already-exists",
            "message": "CPF já cadastrado no sistema.",
            "status": 409
          }
        }
      };

      when(mockClient.post(
        Uri.parse(signUpUrl),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(errorResponse), 409));

      final result = await AuthService.signUp(
        cpf: "881.973.540-73",
        name: "Matias",
        email: "matias3@22e.com",
        phone: "11930541768",
        password: "123456"
      );

      expect(result['success'], false);
      expect(result['error'], "CPF já cadastrado no sistema.");
    });

    test('returns error map when connection fails', () async {
      when(mockClient.post(
        Uri.parse(signUpUrl),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenThrow(Exception('Falha na rede'));

      final result = await AuthService.signUp(
        cpf: "881.973.540-73",
        name: "Matias",
        email: "matias3@22e.com",
        phone: "11930541768",
        password: "123456"
      );

      expect(result['success'], false);
      expect(result['error'], contains("Falha na conexão"));
    });
  });
}
