// Autor: Allan Giovanni Matias Paes & Pedro

import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';

// Utilizamos StatefulWidget porque precisamos gerenciar o estado do campo de texto (o TextEditingController)
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: BackButton(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              // Faz com que os filhos da coluna tentem esticar horizontalmente
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone ilustrativo com fundo arredondado alinhado à esquerda
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 60,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24), // Espaçador vertical

                // Título principal da página
                Text(
                  'Esqueceu a senha?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

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

                // Campo onde o usuário digita o email
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 300,
                    child: TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'seu@email.com',
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5)),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão de envio
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          // Chama o serviço do Firebase para enviar o email de recuperação
                          // Usamos o .trim() para remover espaços em branco sem querer no começo ou fim do email
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: _emailController.text.trim(),
                          );

                          // O 'if (mounted)' é obrigatório no Flutter após um 'await'
                          // Ele verifica se a tela ainda está aberta antes de tentar mostrar o modal ou navegar
                          if (mounted) {
                            FeedbackModal.show(
                              context: context,
                              title: 'Email Enviado',
                              message:
                              'Email de recuperação enviado! Considere verificar sua caixa de Spam.',
                              type: FeedbackType.success,
                              // Ao fechar o modal de sucesso, redireciona o usuário para a tela de login
                              onConfirm: () =>
                                  Navigator.of(context).pushNamed('/login'),
                            );
                          }
                        } catch (e) {
                          // Registra o erro no console de debug para ajudar a encontrar problemas
                          log('Error on password recovery: $e');

                          // Caso ocorra um erro (ex: email mal formatado ou não existe), mostra o modal de erro
                          if (mounted) {
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
                            fontSize: 16, fontWeight: FontWeight.bold),
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