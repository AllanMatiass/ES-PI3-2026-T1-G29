// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';

// Define os tipos de feedback que o modal pode exibir.
enum FeedbackType { success, error, info }

// Modal de feedback personalizado para exibir mensagens de sucesso, erro ou informação.
class FeedbackModal extends StatelessWidget {
  final String title;
  final String message;
  final FeedbackType type;
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

  // Método estático para exibir o modal de feedback com uma animação de escala personalizada.
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

    // Define o ícone e a cor com base no tipo de feedback recebido.
    switch (type) {
      case FeedbackType.success:
        icon = Icons.check_rounded;
        color = const Color(0xFF00A84E);
        break;
      case FeedbackType.error:
        icon = Icons.error_outline_rounded;
        color = const Color(0xFFEF4444);
        break;
      case FeedbackType.info:
        icon = Icons.info_outline_rounded;
        color = const Color(0xFF3B82F6);
        break;
    }

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
