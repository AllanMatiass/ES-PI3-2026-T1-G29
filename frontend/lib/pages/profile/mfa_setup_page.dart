// Autor: Pedro Vinicius Romanato - 25004075

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/services/mfa_service.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';

class MfaSetupPage extends StatefulWidget {
  const MfaSetupPage({super.key});

  @override
  State<MfaSetupPage> createState() => _MfaSetupPageState();
}

class _MfaSetupPageState extends State<MfaSetupPage> {
  bool _isTotpEnrolled = false;
  bool _isLoading = false;

  TotpEnrollmentData? _enrollmentData;
  final TextEditingController _codeController = TextEditingController();

  bool _isInVerificationStep = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollmentStatus();
  }

  Future<void> _loadEnrollmentStatus() async {
    final enrolled = await MfaService.isTotpEnrolled();
    if (mounted) setState(() => _isTotpEnrolled = enrolled);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    setState(() => _isLoading = true);

    try {
      final data = await MfaService.startEnrollment(issuer: 'InvestApp');
      setState(() {
        _enrollmentData = data;
        _isInVerificationStep = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        FeedbackModal.show(
          context: context,
          title: 'Sessão expirada',
          message:
              'Por segurança, faça login novamente antes de ativar o 2FA.',
          type: FeedbackType.error,
        );
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro',
          message: e.message ?? 'Não foi possível iniciar o 2FA.',
          type: FeedbackType.error,
        );
      }
    }
  }

  Future<void> _confirmEnrollment() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      FeedbackModal.show(
        context: context,
        title: 'Código inválido',
        message: 'Digite o código de 6 dígitos do seu autenticador.',
        type: FeedbackType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await MfaService.confirmEnrollment(
        totpSecret: _enrollmentData!.secret,
        verificationCode: code,
        displayName: 'Autenticador',
      );

      setState(() {
        _isTotpEnrolled = true;
        _isInVerificationStep = false;
        _enrollmentData = null;
        _codeController.clear();
        _isLoading = false;
      });

      if (!mounted) return;
      FeedbackModal.show(
        context: context,
        title: '2FA ativado!',
        message: 'Autenticação em dois fatores ativada com sucesso.',
        type: FeedbackType.success,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      FeedbackModal.show(
        context: context,
        title: 'Código incorreto',
        message: e.code == 'invalid-verification-code'
            ? 'O código está incorreto. Verifique o app autenticador e tente novamente.'
            : (e.message ?? 'Erro ao verificar código.'),
        type: FeedbackType.error,
      );
    }
  }

  Future<void> _unenroll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Desativar 2FA'),
        content: const Text(
          'Tem certeza que deseja desativar a autenticação em dois fatores?\n\n'
          'Sua conta ficará menos protegida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await MfaService.unenroll();
      setState(() {
        _isTotpEnrolled = false;
        _isLoading = false;
      });

      if (!mounted) return;
      FeedbackModal.show(
        context: context,
        title: '2FA desativado',
        message: 'Autenticação em dois fatores foi removida.',
        type: FeedbackType.success,
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      if (e.code == 'requires-recent-login') {
        FeedbackModal.show(
          context: context,
          title: 'Sessão expirada',
          message: 'Faça login novamente para desativar o 2FA.',
          type: FeedbackType.error,
        );
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro',
          message: e.message ?? 'Não foi possível desativar o 2FA.',
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Autenticação em 2 Fatores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(theme),
            const SizedBox(height: 24),

            if (!_isTotpEnrolled && !_isInVerificationStep)
              _buildActivateSection(theme),

            if (_isInVerificationStep && _enrollmentData != null)
              _buildVerificationStep(theme),

            if (_isTotpEnrolled)
              _buildDisableSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final isActive = _isTotpEnrolled;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.primary : Colors.grey)
                  .withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.security : Icons.security_outlined,
              color: isActive ? AppColors.primary : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? '2FA Ativo' : '2FA Inativo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? AppColors.primary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Sua conta está protegida com autenticação em dois fatores.'
                      : 'Ative o 2FA para adicionar uma camada extra de segurança.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivateSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Como funciona',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _buildStep(theme, '1', 'Clique em "Ativar 2FA"'),
        _buildStep(theme, '2', 'Escaneie o QR Code com Google Authenticator, Authy ou similar'),
        _buildStep(theme, '3', 'Digite o código de 6 dígitos gerado pelo app'),
        _buildStep(theme, '4', 'Pronto! A partir de agora, seu login pedirá o código'),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _startEnrollment,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.shield_outlined),
            label: const Text(
              'Ativar 2FA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep(ThemeData theme) {
    final data = _enrollmentData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurar autenticador',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Text(
                'Escaneie com seu app autenticador:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent(data.qrCodeUrl)}',
                  width: 200,
                  height: 200,
                  errorBuilder: (_, __, ___) => Column(
                    children: [
                      const Icon(Icons.qr_code, size: 60, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'Não foi possível carregar o QR Code.\nUse o código manual abaixo.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Ou adicione manualmente:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data.secretKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chave copiada!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.secretKey,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Digite o código do app:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: TextStyle(
              color: Colors.grey.withOpacity(0.4),
              letterSpacing: 8,
            ),
            counterText: '',
            filled: true,
            fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isInVerificationStep = false;
                          _enrollmentData = null;
                          _codeController.clear();
                        });
                      },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmEnrollment,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: const Text('Confirmar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisableSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'O 2FA está ativo. A cada login, você precisará inserir o código do seu autenticador.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _unenroll,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.no_encryption_outlined),
            label: const Text('Desativar 2FA'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(ThemeData theme, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}