import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:frontend/models/user.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/services/base_service.dart'; // Importamos o BaseService

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockCallableResult;

  setUpAll(() {
    registerFallbackValue(any());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockCallableResult = MockHttpsCallableResult();

    // Injeta o mock globalmente dentro do BaseService antes de cada teste
    BaseService.testFunctionsInstance = mockFunctions;

    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
  });

  tearDown(() {
    // Limpa a instância após os testes para evitar vazamento de escopo
    BaseService.testFunctionsInstance = null;
  });

  group('UserService - getUserData (Sem alterar o UserService)', () {
    test('Deve retornar sucesso e converter o JSON corretamente', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('123');
      when(() => mockCallable.call(any())).thenAnswer((_) async => mockCallableResult);
      when(() => mockCallableResult.data).thenReturn({
        'result': {
          'uid': '123',
          'name': 'Roberto Carlos',
          'email': 'cn@teste.com',
          'phone': '11930541768',
          'cpf': '881.973.540-73',
          'wallet': {
            'balanceInCents': 0.0,
            'totalInvestedCents': 0.0,
            'updatedAt': {'_seconds': 0, '_nanoseconds': 0},
            'positions': []
          },
          'createdAt': {'_seconds': 0, '_nanoseconds': 0}
        }
      });

      // Act - Chamando o método exatamente como ele é hoje
      final result = await UserService.getUserData(auth: mockAuth);

      // Assert
      expect(result.success, true);
      expect(result.data!.name, 'Allan Giovanni');
    });
  });
}