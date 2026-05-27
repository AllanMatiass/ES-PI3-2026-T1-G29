import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:frontend/models/user.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/services/base_service.dart';

// Gera os mocks robustos com tratamento de Null Safety para o Firebase
@GenerateMocks(
  [],
  customMocks: [
    MockSpec<FirebaseAuth>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<User>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<FirebaseFunctions>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<HttpsCallable>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<HttpsCallableResult>(onMissingStub: OnMissingStub.returnDefault),
  ],
)
// Altere o nome deste import caso o seu arquivo de teste não se chame 'user_service_test.dart'
import 'user_service_test.mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockCallableResult;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFunctions = MockFirebaseFunctions();
    mockCallable =
        MockHttpsCallable(); // O mock customizado herda com prefixo MockMock caso necessário, ou apenas MockHttpsCallable dependendo da geração. O gerador do MockSpec cria como MockHttpsCallable.
    mockCallableResult = MockHttpsCallableResult();

    // Injeta o mock globalmente dentro do BaseService antes de cada teste
    BaseService.testFunctionsInstance = mockFunctions;

    // No Mockito, usamos apenas any (sem os parênteses arrow do mocktail)
    when(mockFunctions.httpsCallable(any)).thenReturn(mockCallable);
  });

  tearDown(() {
    // Limpa a instância após os testes para evitar vazamento de escopo
    BaseService.testFunctionsInstance = null;
  });

  group('UserService - getUserData (Sem alterar o UserService)', () {
    test('Deve retornar sucesso e converter o JSON corretamente', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('123');
      when(mockCallable.call(any)).thenAnswer((_) async => mockCallableResult);
      when(mockCallableResult.data).thenReturn({
        'result': {
          'uid': '123',
          'name': 'Roberto Carlos', // Nome mockado aqui
          'email': 'cn@teste.com',
          'phone': '11930541768',
          'cpf': '881.973.540-73',
          'wallet': {
            'balanceInCents': 0.0,
            'totalInvestedCents': 0.0,
            'updatedAt': {'_seconds': 0, '_nanoseconds': 0},
            'positions': [],
          },
          'createdAt': {'_seconds': 0, '_nanoseconds': 0},
        },
      });

      // Act
      final result = await UserService.getUserData(auth: mockAuth);

      // Assert
      expect(result.success, true);
      // CORREÇÃO: Ajustado para validar o nome que veio do Mock (Roberto Carlos)
      expect(result.data!.name, 'Roberto Carlos');
    });
  });
}
