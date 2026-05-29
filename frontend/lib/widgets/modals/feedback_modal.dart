// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';

/// Define as categorias visuais de feedback, mapeadas para cores e ícones específicos.
enum FeedbackType { success, error, info }

/// Modal de feedback personalizado utilizado para exibir os resultados de 
/// operações importantes, como "Transação Concluída" ou "Erro de Conexão".
/// Este componente padroniza a UX de respostas do sistema em toda a aplicação.
class FeedbackModal extends StatelessWidget {
  final String title;
  final String message;
  final FeedbackType type;
  
  // Callback executado quando o usuário clica no botão principal (Ex: Fechar, Voltar para Home)
  final VoidCallback? onConfirm; 
  final String? buttonText;

  const FeedbackModal({
    super.key,
    required this.title,
    required this.message,
    this.type = FeedbackType.info,
    this.onConfirm,
    this.buttonText,
  });

  /// Exibe o modal sobrepondo a tela atual, aplicando uma animação customizada (Scale + Opacity).
  /// Modais de erro ou informação (FeedbackType.error ou info) permitem que o usuário 
  /// clique fora da caixa (barrierDismissible) para fechá-la. Modais de sucesso
  /// forçam o clique no botão para garantir que o callback `onConfirm` seja executado (ex: navegação).
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    FeedbackType type = FeedbackType.info,
    VoidCallback? onConfirm,
    String? buttonText,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: type != FeedbackType.success,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        // Animação de entrada "Bounce": O modal cresce um pouco além de 100% e volta ao tamanho normal.
        final curve = Curves.easeInOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curve,
          child: Opacity(
            opacity: anim1.value,
            child: FeedbackModal(
              title: title,
              message: message,
              type: type,
              onConfirm: onConfirm,
              buttonText: buttonText,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    // Define a identidade visual do modal com base no tipo de feedback.
    switch (type) {
      case FeedbackType.success:
        icon = Icons.check_rounded;
        color = const Color(0xFF00A84E); // Verde padrão Mescla Invest
        break;
      case FeedbackType.error:
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFEF4444); // Vermelho de alerta
        break;
      case FeedbackType.info:
        icon = Icons.info_outline_rounded;
        color = const Color(0xFF3B82F6); // Azul informativo
        break;
    }

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone central em destaque circular
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          // Botão de ação (Confirm/Dismiss)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirm != null) onConfirm!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText ??
                    (type == FeedbackType.error
                        ? 'Tentar novamente'
                        : 'Entendido'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
