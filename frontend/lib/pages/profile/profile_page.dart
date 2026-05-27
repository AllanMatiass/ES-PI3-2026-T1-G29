// Autor: Pedro Vinicius Romanato - 25004075
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/pages/profile/mfa_setup_page.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/base_service.dart';
import 'package:frontend/states/user_state.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/headers/home_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSendingVerification = false;
  bool _isSendingPasswordReset = false;
  bool _isUploadingPicture = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    UserState.refreshUser();
    _authSubscription = FirebaseAuth.instance.userChanges().listen((
      user,
    ) async {
      if (user == null || user.email == null) return;
      final current = UserState.userNotifier.value;
      if (current == null || current.email == user.email) return;
      try {
        await BaseService.call<void>(
          'updateUserProfile',
          data: {'email': user.email},
          fromJson: (_) {},
        );
        UserState.userNotifier.value = current.copyWith(email: user.email!);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _changeProfilePicture() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image == null) return;

    setState(() => _isUploadingPicture = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final fileName = 'profilePicture.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child(fileName);

      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      // Standardize the URL in the local state directly from Storage
      UserState.profilePictureUrlNotifier.value = downloadUrl;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPicture = false);
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _isSendingVerification = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email de verificação enviado! Verifique sua caixa de entrada.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'too-many-requests'
                ? 'Aguarde alguns minutos antes de solicitar outro email.'
                : (e.message ?? 'Não foi possível enviar o email.'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingVerification = false);
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;

    setState(() => _isSendingPasswordReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email de redefinição enviado para $email. Verifique sua caixa de entrada.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'too-many-requests'
                ? 'Muitas tentativas. Aguarde alguns minutos.'
                : (e.message ?? 'Não foi possível enviar o email.'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingPasswordReset = false);
    }
  }

  void _showEditEmailSheet(
    BuildContext context,
    ThemeData theme,
    String currentEmail,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final factors = user != null
        ? await user.multiFactor.getEnrolledFactors()
        : <MultiFactorInfo>[];
    final hasMfa = factors.isNotEmpty;

    if (!mounted) return;

    if (hasMfa) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outlined,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Desative o 2FA primeiro',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para alterar o email é necessário desativar a Autenticação em 2 Fatores. '
                  'Após a alteração você pode reativá-la.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MfaSetupPage()),
                      );
                    },
                    icon: const Icon(Icons.security_outlined, size: 18),
                    label: const Text('Gerenciar 2FA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    final emailCtrl = TextEditingController(text: currentEmail);
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alterar email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Um link de verificação será enviado para o novo endereço. '
                      'O email só será atualizado após você clicar no link.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Novo email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Informe o novo email';
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(v.trim()))
                          return 'Email inválido';
                        if (v.trim() == currentEmail)
                          return 'Informe um email diferente do atual';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: sending
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => sending = true);
                                try {
                                  await FirebaseAuth.instance.currentUser
                                      ?.verifyBeforeUpdateEmail(
                                        emailCtrl.text.trim(),
                                      );

                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Link enviado para ${emailCtrl.text.trim()}. '
                                          'Clique nele para confirmar a alteração.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 6),
                                      ),
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  setModalState(() => sending = false);
                                  final msg = switch (e.code) {
                                    'too-many-requests' =>
                                      'Muitas tentativas. Aguarde alguns minutos.',
                                    'email-already-in-use' =>
                                      'Este email já está em uso por outra conta.',
                                    _ => e.message ?? 'Erro ao alterar email.',
                                  };
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_outlined, size: 18),
                        label: Text(
                          sending
                              ? 'Enviando...'
                              : 'Enviar link de verificação',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditPhoneSheet(
    BuildContext context,
    ThemeData theme,
    String currentPhone,
  ) {
    // Prepara o texto inicial removendo o +55 se existir para o formatador aplicar novamente
    String initialDigits = currentPhone.replaceAll(RegExp(r'\D'), '');
    if (initialDigits.startsWith('55')) {
      initialDigits = initialDigits.substring(2);
    }

    // Aplica a formatação inicial manualmente
    final buffer = StringBuffer();
    if (initialDigits.isNotEmpty) {
      buffer.write('+55 ');
      for (int i = 0; i < initialDigits.length; i++) {
        if (i == 0) buffer.write('(');
        if (i == 2) buffer.write(') ');
        if (initialDigits.length == 11 && i == 7) buffer.write('-');
        if (initialDigits.length == 10 && i == 6) buffer.write('-');
        buffer.write(initialDigits[i]);
      }
    }

    final controller = TextEditingController(text: buffer.toString());
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alterar telefone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Informe o novo número com DDD. A alteração é imediata.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        _PhoneMaskFormatter(),
                      ],
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        hintText: '+55 (11) 91234-5678',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Informe o telefone';
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        // Remove o 55 do país para validar o DDD + Número
                        final cleanDigits = digits.startsWith('55') ? digits.substring(2) : digits;
                        if (cleanDigits.length < 10 || cleanDigits.length > 11) {
                          return 'Telefone deve ter 10 ou 11 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => saving = true);

                                // Extrai apenas os dígitos e remove o 55 do país antes de enviar
                                String digits = controller.text.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                if (digits.startsWith('55')) {
                                  digits = digits.substring(2);
                                }

                                final res = await BaseService.call<void>(
                                  'updateUserProfile',
                                  data: {'phone': digits},
                                  fromJson: (_) {},
                                );
                                if (!ctx.mounted) return;
                                setModalState(() => saving = false);

                                if (res.success) {
                                  final current = UserState.userNotifier.value;
                                  if (current != null) {
                                    // Salva com o 55 para manter o padrão do back se necessário, 
                                    // ou apenas os dígitos conforme instrução. 
                                    // O backend vai tratar e salvar com +55.
                                    UserState.userNotifier.value = current
                                        .copyWith(phone: digits);
                                  }
                                  Navigator.of(ctx).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Telefone atualizado com sucesso!',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res.message ??
                                            'Erro ao atualizar telefone.',
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(saving ? 'Salvando...' : 'Salvar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserState.userNotifier,
      builder: (context, userData, _) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final name = userData?.name ?? firebaseUser?.displayName ?? 'Usuário';
        final email = userData?.email ?? firebaseUser?.email ?? '';
        final phone = userData?.phone ?? '';
        final cpf = userData?.cpf ?? '';
        final initials = _getInitials(name);
        final emailVerified = firebaseUser?.emailVerified ?? true;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => UserState.refreshUser(context),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeader(
                      title: 'Perfil',
                      userData: userData,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              InkWell(
                                onTap: _isUploadingPicture
                                    ? null
                                    : _changeProfilePicture,
                                borderRadius: BorderRadius.circular(44),
                                child: ValueListenableBuilder<String?>(
                                  valueListenable:
                                      UserState.profilePictureUrlNotifier,
                                  builder: (context, profileUrl, _) {
                                    return CircleAvatar(
                                      radius: 44,
                                      backgroundColor: AppColors.primary.withOpacity(
                                        0.15,
                                      ),
                                      backgroundImage: profileUrl != null
                                          ? NetworkImage(profileUrl)
                                          : null,
                                      child: profileUrl == null
                                          ? Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          : null,
                                    );
                                  },
                                ),
                              ),
                              if (_isUploadingPicture)
                                const Positioned.fill(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.primary,
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.scaffoldBackgroundColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!emailVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.mark_email_unread_outlined,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Email não verificado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Confirme seu email para poder ativar o 2FA e proteger sua conta.',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isSendingVerification
                                    ? null
                                    : _sendVerificationEmail,
                                icon: _isSendingVerification
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.orange,
                                        ),
                                      )
                                    : const Icon(Icons.send_outlined, size: 16),
                                label: Text(
                                  _isSendingVerification
                                      ? 'Enviando...'
                                      : 'Reenviar email de verificação',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    _sectionTitle('Dados pessoais', theme),
                    const SizedBox(height: 12),
                    _infoCard(theme, [
                      if (cpf.isNotEmpty)
                        _infoRow(
                          theme,
                          icon: Icons.badge_outlined,
                          label: 'CPF',
                          value: _maskCpf(cpf),
                        ),
                      if (cpf.isNotEmpty)
                        Divider(
                          height: 1,
                          color: theme.dividerColor.withOpacity(0.15),
                        ),

                      _editableRow(
                        theme,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: email,
                        onEdit: () => _showEditEmailSheet(context, theme, email),
                      ),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withOpacity(0.15),
                      ),

                      _editableRow(
                        theme,
                        icon: Icons.phone_outlined,
                        label: 'Telefone',
                        value: phone.isNotEmpty
                            ? _maskPhone(phone)
                            : 'Não informado',
                        onEdit: () => _showEditPhoneSheet(context, theme, phone),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    _sectionTitle('Segurança', theme),
                    const SizedBox(height: 12),

                    _actionCard(
                      theme,
                      icon: Icons.lock_outline,
                      title: 'Alterar senha',
                      subtitle: 'Enviaremos um link para redefinir sua senha',
                      isLoading: _isSendingPasswordReset,
                      onTap: _isSendingPasswordReset
                          ? null
                          : _sendPasswordResetEmail,
                    ),
                    const SizedBox(height: 8),

                    _actionCard(
                      theme,
                      icon: Icons.security_outlined,
                      title: 'Autenticação em 2 Fatores',
                      subtitle: 'Configure o 2FA para proteger sua conta',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MfaSetupPage()),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _sectionTitle('Preferências', theme),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeNotifier,
                      builder: (context, currentMode, _) {
                        final isDark = currentMode == ThemeMode.dark;
                        return _infoCard(theme, [
                          _infoRow(
                            theme,
                            icon: isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                            label: 'Tema escuro',
                            value: '',
                            trailing: Switch(
                              value: isDark,
                              activeColor: AppColors.primary,
                              onChanged: (_) {
                                themeNotifier.value = isDark
                                    ? ThemeMode.light
                                    : ThemeMode.dark;
                              },
                            ),
                          ),
                        ]);
                      },
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Sair da conta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _maskCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.***.***-${digits.substring(9)}';
    }
    return cpf;
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    String purePhone = digits;

    // Remove o prefixo 55 se ele estiver presente no início e o número tiver 12 ou 13 dígitos total
    if (digits.startsWith('55') && (digits.length == 13 || digits.length == 12)) {
      purePhone = digits.substring(2);
    }

    if (purePhone.length == 11) {
      return '+55 (${purePhone.substring(0, 2)}) *****-${purePhone.substring(7)}';
    } else if (purePhone.length == 10) {
      return '+55 (${purePhone.substring(0, 2)}) ****-${purePhone.substring(6)}';
    }
    return phone;
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoCard(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (trailing != null) trailing,
                if (value.isNotEmpty)
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await AuthService.signOut(context);
  }
}

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Se o usuário está apagando e sobrou apenas o prefixo "55", limpamos tudo para permitir apagar completamente
    if (newValue.text.length < oldValue.text.length && digits == '55') {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Se os dígitos começam com 55 e o campo já tinha o prefixo ou é um número longo (paste), 
    // removemos os 55 iniciais para não duplicar o prefixo visual.
    if (digits.startsWith('55') && (oldValue.text.contains('+55') || digits.length > 11)) {
      digits = digits.substring(2);
    }

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final buffer = StringBuffer();
    buffer.write('+55 ');

    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (digits.length == 11 && i == 7) buffer.write('-');
      if (digits.length == 10 && i == 6) buffer.write('-');
      buffer.write(digits[i]);
      if (i >= 10) break; // Limite de 11 dígitos
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
