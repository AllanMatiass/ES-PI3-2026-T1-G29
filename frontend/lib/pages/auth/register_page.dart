// Autor: Vinícius Castro & Allan Giovanni Matias Paes & Pedro Vinicius Romanato
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/validators.dart';
import 'package:frontend/pages/auth/login_page.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: { "#": RegExp(r'[0-9]') },
  );
  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: { "#": RegExp(r'[0-9]') },
  );
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Regras de senha forte
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\+=/\\]'));
  bool get _passwordValid => _hasMinLength && _hasUppercase && _hasNumber && _hasSpecial;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final result = await AuthService.signUp(
      cpf: _cpfController.text,
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result.success) {
        try {
          final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
          await credential.user?.sendEmailVerification();
          await FirebaseAuth.instance.signOut();
        } catch (_) {
        }

        FeedbackModal.show(
          context: context,
          title: 'Conta criada!',
          message:
              'Sua conta foi criada com sucesso. Enviamos um email de verificação para ${_emailController.text}. Confirme seu email antes de fazer login.',
          type: FeedbackType.success,
        );

        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (route) => false,
          );
        }
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro no cadastro',
          message: result.message ?? 'Erro ao criar conta',
          type: FeedbackType.error,
        );
      }
    }
  }

  Widget _buildPasswordRule(bool satisfied, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: satisfied
                ? Colors.green
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: satisfied
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).maybePop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Preencha seus dados para começar',
                style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: 'Nome completo',
                          isRequired: true,
                          hintText: 'João Silva',
                          controller: _nameController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Nome é obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          label: 'CPF',
                          isRequired: true,
                          hintText: '000.000.000-00',
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [cpfMask],
                          validator: Validators.validateCPF,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          label: 'Telefone',
                          isRequired: true,
                          hintText: '(00) 00000-0000',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [phoneMask],
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          label: 'Email',
                          isRequired: true,
                          hintText: 'seu@email.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        const SizedBox(height: 18),
                        CustomTextField(
                          label: 'Senha',
                          isRequired: true,
                          hintText: 'Mínimo 8 caracteres',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Senha é obrigatória';
                            if (!_hasMinLength) return 'A senha deve ter pelo menos 8 caracteres';
                            if (!_hasUppercase) return 'A senha deve ter pelo menos uma letra maiúscula';
                            if (!_hasNumber) return 'A senha deve ter pelo menos um número';
                            if (!_hasSpecial) return 'A senha deve ter pelo menos um caractere especial';
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        
                        if (_passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _passwordValid
                                    ? Colors.green.withOpacity(0.4)
                                    : theme.colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Requisitos da senha:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _buildPasswordRule(_hasMinLength, 'Mínimo 8 caracteres'),
                                _buildPasswordRule(_hasUppercase, 'Uma letra maiúscula'),
                                _buildPasswordRule(_hasNumber, 'Um número'),
                                _buildPasswordRule(_hasSpecial, 'Um caractere especial (!@#\$%...)'),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Criar conta',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Já tem uma conta? ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).maybePop();
                              },
                              child: const Text(
                                'Fazer login',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Ao criar uma conta, você concorda com nossos Termos de Uso e Política de Privacidade',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}