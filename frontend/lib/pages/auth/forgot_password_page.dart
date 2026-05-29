// Autor: Pedro Vinícius Romanato - 25004075

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';

/// Tela responsável pela recuperação de senha do usuário
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

/// Estado da tela ForgotPasswordPage
class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  /// Chave utilizada para validar o formulário
  final _formKey = GlobalKey<FormState>();

  /// Controller responsável por capturar o texto digitado no campo de email
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    // Libera o controller da memória ao destruir a tela
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtém o tema atual da aplicação
    final theme = Theme.of(context);
    return Scaffold(
      // Define a cor de fundo da tela
      backgroundColor: theme.scaffoldBackgroundColor,
      // Barra superior da tela
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        // Botão para voltar para a tela anterior
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      // Permite rolagem caso o teclado cubra parte do conteúdo
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Formulário da tela
          child: Form(
            key: _formKey,
            child: Column(
              // Faz os elementos ocuparem toda a largura horizontal possível
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone ilustrativo no topo da tela
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 60,
                    height: 50,
                    decoration: BoxDecoration(
                      // Cor de fundo com opacidade reduzida
                      color: AppColors.primary.withOpacity(0.1),
                      // Bordas arredondadas
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Ícone de email
                    child: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
                // Espaçamento vertical
                const SizedBox(height: 24),
                // Título principal da tela
                Text(
                  'Esqueceu a senha?',

                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                // Texto explicativo
                Text(
                  'Digite seu email e enviaremos um código para redefinir sua senha',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                // Label do campo de email
                Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                // Campo de entrada do email
                Align(
                  alignment: Alignment.centerLeft,

                  child: SizedBox(
                    width: 300,

                    child: TextFormField(
                      // Controller responsável pelo valor digitado
                      controller: _emailController,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'seu@email.com',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botão responsável por enviar o email de recuperação
                Align(
                  alignment: Alignment.centerLeft,

                  child: SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Solicita ao Firebase o envio do email de recuperação
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(
                            email: _emailController.text.trim(),
                          );
                          // Verifica se a tela ainda está montada
                          if (mounted) {
                            // Exibe modal de sucesso
                            FeedbackModal.show(
                              context: context,
                              title: 'Email Enviado',
                              message:
                              'Email de recuperação enviado! Considere verificar sua caixa de Spam.',
                              type: FeedbackType.success,
                              // Ao confirmar, navega para a tela de login
                              onConfirm: () =>
                                  Navigator.of(context).pushNamed('/login'),
                            );
                          }
                        } catch (e) {
                          // Verifica se a tela ainda existe antes de mostrar o modal
                          if (mounted) {
                            // Exibe modal de erro
                            FeedbackModal.show(
                              context: context,
                              title: 'Erro',
                              message:
                              'Erro ao enviar link de recuperação de senha.',
                              type: FeedbackType.error,
                            );
                          }
                        }
                      },
                      // Estilo visual do botão
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enviar código',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}