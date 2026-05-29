// Autor: Pedro Vinicius Romanato - 25004075
import 'package:firebase_auth/firebase_auth.dart';
 
/// Classe auxiliar para transportar os dados de configuração inicial do 2FA.
/// Contém o segredo gerado e os dados para exibição (QR Code ou chave manual).
class TotpEnrollmentData {
  final TotpSecret secret; // Objeto interno do Firebase Auth para gerenciar o vínculo
  final String qrCodeUrl; // URL para renderizar o QR Code (compatível com Google Authenticator, Authy, etc)
  final String secretKey; // Chave em texto plano para inserção manual no app autenticador
 
  TotpEnrollmentData({
    required this.secret,
    required this.qrCodeUrl,
    required this.secretKey,
  });
}
 
/// Serviço dedicado ao gerenciamento da Autenticação de Múltiplos Fatores (MFA).
/// Utiliza o protocolo TOTP (Time-based One-Time Password) nativo do Identity Platform do Firebase.
class MfaService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
 
  /// Verifica de forma segura se o usuário atual já tem o fator TOTP ativado em sua conta.
  static Future<bool> isTotpEnrolled() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    final factors = await user.multiFactor.getEnrolledFactors();
    return factors.any((f) => f.factorId == "totp");
  }
 
  /// Retorna a lista completa de todos os fatores de autenticação secundários 
  /// configurados pelo usuário (caso no futuro suporte SMS, por exemplo).
  static Future<List<MultiFactorInfo>> enrolledFactors() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return await user.multiFactor.getEnrolledFactors();
  }
 
  /// Inicia o processo de configuração do 2FA.
  /// 1. Cria uma sessão segura (MultiFactorSession).
  /// 2. Gera um segredo compartilhado entre o Firebase e o Autenticador.
  /// 3. Retorna os dados formatados (QR Code/Key) para a interface do usuário.
  static Future<TotpEnrollmentData> startEnrollment({
    String issuer = 'InvestApp',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
 
    final multiFactorSession = await user.multiFactor.getSession();
 
    // Gera o segredo baseado na sessão ativa do usuário
    final totpSecret = await TotpMultiFactorGenerator.generateSecret(
      multiFactorSession,
    );
 
    // Monta a string de provisionamento (otpauth://totp/...) e converte em URL de QR Code
    final qrCodeUrl = await totpSecret.generateQrCodeUrl(
      accountName: user.email ?? user.uid,
      issuer: issuer,
    );
 
    return TotpEnrollmentData(
      secret: totpSecret,
      qrCodeUrl: qrCodeUrl,
      secretKey: totpSecret.secretKey,
    );
  }
 
  /// Conclui o processo de configuração validando o primeiro código TOTP.
  /// O Firebase exige essa validação inicial para garantir que o usuário
  /// configurou o app autenticador corretamente antes de bloquear a conta.
  static Future<void> confirmEnrollment({
    required TotpSecret totpSecret,
    required String verificationCode,
    String displayName = 'Autenticador',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
 
    // Gera uma "Assertion" (Prova de propriedade) com o código digitado
    final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(
      totpSecret,
      verificationCode,
    );
 
    // Efetiva o vínculo do 2FA na conta
    await user.multiFactor.enroll(assertion, displayName: displayName);
  }
 
  /// Remove todos os fatores TOTP associados à conta do usuário.
  /// Atenção: Requer login recente (`requires-recent-login`), o que pode lançar
  /// uma FirebaseAuthException que deve ser tratada pela UI.
  static Future<void> unenroll() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
 
    final factors = (await user.multiFactor.getEnrolledFactors())
        .where((f) => f.factorId == "totp")
        .toList();
 
    for (final factor in factors) {
      await user.multiFactor.unenroll(multiFactorInfo: factor);
    }
  }
 
  /// Resolve um desafio (Challenge) de login quando o usuário tem 2FA ativo.
  /// É chamado pela `login_page.dart` após o e-mail/senha estarem corretos,
  /// mas o Firebase retornar uma [FirebaseAuthMultiFactorException].
  static Future<UserCredential> resolveSignIn({
    required MultiFactorResolver resolver,
    required String verificationCode,
  }) async {
    // Procura na lista de "dicas" do resolver a chave correspondente ao TOTP
    final totpHint = resolver.hints.firstWhere(
      (h) => h.factorId == "totp",
      orElse: () => resolver.hints.first,
    );
 
    // Cria a prova de login juntando a dica (Hint) com o código de 6 dígitos
    final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
      totpHint.uid,
      verificationCode,
    );
 
    // Finaliza o login e devolve a credencial (token, uid, etc)
    return await resolver.resolveSignIn(assertion);
  }
}