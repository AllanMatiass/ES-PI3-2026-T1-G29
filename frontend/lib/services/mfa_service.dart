// Autor: Pedro Vinicius Romanato - 25004075
import 'package:firebase_auth/firebase_auth.dart';
 
class TotpEnrollmentData {
  final TotpSecret secret;
  final String qrCodeUrl;
  final String secretKey;
 
  TotpEnrollmentData({
    required this.secret,
    required this.qrCodeUrl,
    required this.secretKey,
  });
}
 
class MfaService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
 
  static Future<bool> isTotpEnrolled() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final factors = await user.multiFactor.getEnrolledFactors();
    return factors.any((f) => f.factorId == "totp");
  }
 
  static Future<List<MultiFactorInfo>> enrolledFactors() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return await user.multiFactor.getEnrolledFactors();
  }
 
  static Future<TotpEnrollmentData> startEnrollment({
    String issuer = 'InvestApp',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
 
    final multiFactorSession = await user.multiFactor.getSession();
 
    final totpSecret = await TotpMultiFactorGenerator.generateSecret(
      multiFactorSession,
    );
 
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
 
  static Future<void> confirmEnrollment({
    required TotpSecret totpSecret,
    required String verificationCode,
    String displayName = 'Autenticador',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');
 
    final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(
      totpSecret,
      verificationCode,
    );
 
    await user.multiFactor.enroll(assertion, displayName: displayName);
  }
 
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
 
  static Future<UserCredential> resolveSignIn({
    required MultiFactorResolver resolver,
    required String verificationCode,
  }) async {
    final totpHint = resolver.hints.firstWhere(
      (h) => h.factorId == "totp",
      orElse: () => resolver.hints.first,
    );
 
    final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
      totpHint.uid,
      verificationCode,
    );
 
    return await resolver.resolveSignIn(assertion);
  }
}