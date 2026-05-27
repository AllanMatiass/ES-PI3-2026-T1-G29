// Autor: Murilo Rigoni - 25006049
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:frontend/services/base_service.dart';

@GenerateMocks([FirebaseFunctions, HttpsCallable, HttpsCallableResult])
import 'startup_service_test.mocks.dart';

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();

    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
  });

  group('AuthService.signUp', () {
    test('returns success ApiResponse when the call is successful', () async {
      final mockData = {
        "uid": "LP2zQlJx54N9NPYwiwMQfLADIdC3",
        "name": "Matias",
        "email": "matias3@22e.com",
      };

      final mockResult = MockHttpsCallableResult();
      when(mockResult.data).thenReturn(mockData);
      when(mockCallable.call(any)).thenAnswer((_) async => mockResult);

      final result = await BaseService.call<Map<String, dynamic>>(
        'signUp',
        data: {
          "cpf": "881.973.540-73",
          "name": "Matias",
          "email": "matias3@22e.com",
          "phone": "11930541768",
          "password": "123456",
        },
        fromJson: (data) => Map<String, dynamic>.from(data as Map),
        functions: mockFunctions,
      );

      expect(result.success, true);
      expect(result.data?['name'], "Matias");
      expect(result.data?['email'], "matias3@22e.com");
    });

    test('returns error ApiResponse when the CPF already exists', () async {
      when(mockCallable.call(any)).thenThrow(
        FirebaseFunctionsException(
          code: 'already-exists',
          message: 'CPF já cadastrado no sistema.',
          details: {'authCode': 'already-exists'},
        ),
      );

      final result = await BaseService.call<Map<String, dynamic>>(
        'signUp',
        data: {
          "cpf": "881.973.540-73",
          "name": "Matias",
          "email": "matias3@22e.com",
          "phone": "11930541768",
          "password": "123456",
        },
        fromJson: (data) => {},
        functions: mockFunctions,
      );

      expect(result.success, false);
      expect(result.message, "CPF já cadastrado no sistema.");
      expect(result.errorCode, "already-exists");
    });
  });
}
