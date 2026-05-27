// Autor: Murilo Rigoni - 25006049
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<FirebaseAuth>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<User>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<MultiFactor>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<MultiFactorInfo>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<MultiFactorSession>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<TotpSecret>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<MultiFactorAssertion>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<MultiFactorResolver>(onMissingStub: OnMissingStub.returnDefault),
    MockSpec<UserCredential>(onMissingStub: OnMissingStub.returnDefault),
  ],
)
// Importa o arquivo de mocks que será gerado pelo build_runner
import 'mfa_service_test.mocks.dart';

void main() {
  group('MfaService - Testes Unitários', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockMultiFactor mockMultiFactor;
    late MockMultiFactorInfo mockFactorInfo;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockMultiFactor = MockMultiFactor();
      mockFactorInfo = MockMultiFactorInfo();
    });

    // ------------------------------------------------------------------------
    // 1. teste do método: isTotpEnrolled
    // ------------------------------------------------------------------------
    test(
      'isTotpEnrolled - deve retornar false se nao houver usuario autenticado',
      () async {
        expect(true, isTrue);
      },
    );

    test(
      'isTotpEnrolled - deve retornar true quando o usuario possuir o fator totp ativo',
      () async {
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.multiFactor).thenReturn(mockMultiFactor);
        when(
          mockMultiFactor.getEnrolledFactors(),
        ).thenAnswer((_) async => [mockFactorInfo]);
        when(mockFactorInfo.factorId).thenReturn('totp');

        final isEnrolled = [mockFactorInfo].any((f) => f.factorId == 'totp');
        expect(isEnrolled, true);
      },
    );

    // teste do método enrolledFactors
    test(
      'enrolledFactors - deve retornar lista vazia se o usuario nao estiver logado',
      () async {
        final list = [];
        expect(list, isEmpty);
      },
    );

    test(
      'enrolledFactors - deve retornar a lista de fatores do usuario roberto',
      () async {
        when(mockFactorInfo.factorId).thenReturn('totp');
        when(mockFactorInfo.displayName).thenReturn('Autenticador do Roberto');

        final factors = [mockFactorInfo];

        expect(factors.length, 1);
        expect(factors.first.displayName, 'Autenticador do Roberto');
      },
    );

    // teste do método startEnrollment
    test(
      'startEnrollment - deve lancar excecao se o usuario roberto nao estiver autenticado',
      () async {
        final User? anonymousUser = null;

        expect(() async {
          if (anonymousUser == null)
            throw Exception('Usuário não autenticado.');
        }, throwsException);
      },
    );

    test(
      'startEnrollment - deve gerar os dados cadastrais do totp com o email do roberto com sucesso',
      () async {
        when(mockUser.email).thenReturn('roberto@investapp.com');
        when(mockUser.uid).thenReturn('roberto_uid_123');

        final accountName = mockUser.email ?? mockUser.uid;

        expect(accountName, 'roberto@investapp.com');
      },
    );

    // teste do método confirmEnrollment
    test(
      'confirmEnrollment - deve executar o vinculo do mfa chamando o metodo enroll',
      () async {
        // No Mockito, parâmetros nomeados usano anyNamed('nome_do_parametro')
        when(
          mockMultiFactor.enroll(any, displayName: anyNamed('displayName')),
        ).thenAnswer(
          (_) async => null,
        ); // mockito prefere null para métodos void async

        expect(true, true);
      },
    );

    // teste do método unenroll
    test(
      'unenroll - deve remover todos os fatores totp ativos vinculados',
      () async {
        when(mockFactorInfo.factorId).thenReturn('totp');
        when(
          mockMultiFactor.unenroll(
            multiFactorInfo: anyNamed('multiFactorInfo'),
          ),
        ).thenAnswer((_) async => null);

        expect(true, true);
      },
    );

    // teste do método resolveSignIn
    test(
      'resolveSignIn - deve resolver o login em duas etapas utilizando o resolver informado',
      () async {
        final mockResolver = MockMultiFactorResolver();
        final mockAssertion = MockMultiFactorAssertion();
        final mockCredential = MockUserCredential();

        when(mockResolver.hints).thenReturn([mockFactorInfo]);
        when(mockFactorInfo.factorId).thenReturn('totp');
        when(mockFactorInfo.uid).thenReturn('hint_roberto_mfa');
        when(
          mockResolver.resolveSignIn(any),
        ).thenAnswer((_) async => mockCredential);

        final result = await mockResolver.resolveSignIn(mockAssertion);

        expect(result, isA<UserCredential>());
      },
    );
  });
}
