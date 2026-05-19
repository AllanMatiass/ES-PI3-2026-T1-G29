// Autor: Pedro Vinicius Romanato
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
  static bool isTotpEnrolled() {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.multiFactor.enrolledFactors
        .any((f) => f.factorId == TotpMultiFactorGenerator.FACTOR_ID);
  }

  static List<MultiFactorInfo> enrolledFactors() {
    return _auth.currentUser?.multiFactor.enrolledFactors ?? [];
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

    final qrCodeUrl = totpSecret.generateQrCodeUrl(
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

    final assertion = TotpMultiFactorGenerator.getAssertionForEnrollment(
      totpSecret,
      verificationCode,
    );

    await user.multiFactor.enroll(assertion, displayName: displayName);
  }

  static Future<void> unenroll() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final factors = user.multiFactor.enrolledFactors
        .where((f) => f.factorId == TotpMultiFactorGenerator.FACTOR_ID)
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
      (h) => h.factorId == TotpMultiFactorGenerator.FACTOR_ID,
      orElse: () => resolver.hints.first,
    );

    final assertion = TotpMultiFactorGenerator.getAssertionForSignIn(
      totpHint.uid,
      verificationCode,
    );

    return await resolver.resolveSignIn(assertion);
  }
}
