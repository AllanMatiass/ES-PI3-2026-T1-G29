// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import '../../constants/colors.dart';

/// Modal de confirmação genérico utilizado em operações sensíveis (ex: Comprar Tokens, Sacar, Transferir).
/// Exibe um resumo detalhado em formato de "Nota Fiscal/Recibo" antes que o usuário conclua a ação.
class ConfirmationModal extends StatelessWidget {
  final String title;
  final String description;
  final List<ConfirmationRowData> rows; // Linhas de dados (Chave -> Valor) para o resumo
  final String confirmButtonText;
  final String cancelButtonText;
  final Color? confirmButtonColor;
  final String? note; // Observação de rodapé (ex: "Os fundos ficarão bloqueados por X dias")

  const ConfirmationModal({
    super.key,
    required this.title,
    required this.description,
    required this.rows,
    this.confirmButtonText = 'Confirmar',
    this.cancelButtonText = 'Cancelar',
    this.confirmButtonColor,
    this.note,
  });

  /// Método utilitário assíncrono para exibir o modal de qualquer tela.
  /// Retorna `true` se o usuário confirmou a ação ou `false` (ou null) se cancelou/fechou.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String description,
    required List<ConfirmationRowData> rows,
    String confirmButtonText = 'Confirmar',
    String cancelButtonText = 'Cancelar',
    Color? confirmButtonColor,
    String? note,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationModal(
        title: title,
        description: description,
        rows: rows,
        confirmButtonText: confirmButtonText,
        cancelButtonText: cancelButtonText,
        confirmButtonColor: confirmButtonColor,
        note: note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      contentPadding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 8),
      actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Caixa cinza agrupando as linhas de resumo da transação
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: rows.map((row) => _buildRow(row)).toList(),
              ),
            ),
            if (note != null) ...[
              const SizedBox(height: 16),
              Text(
                note!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  cancelButtonText,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmButtonColor ?? AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(confirmButtonText),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói uma linha individual de dado (Ex: "Quantidade: 100 tokens")
  /// Se `isTotal` for true, adiciona um divisor visual e formata o texto em negrito/cor de destaque.
  Widget _buildRow(ConfirmationRowData row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          if (row.isTotal) 
            Divider(height: 16, color: AppColors.grey300),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                row.label,
                style: TextStyle(
                  color: AppColors.grey600,
                  fontSize: 13,
                ),
              ),
              Text(
                row.value,
                style: TextStyle(
                  fontWeight: row.isTotal ? FontWeight.bold : FontWeight.w500,
                  fontSize: row.isTotal ? 16 : 14,
                  color: row.isTotal ? AppColors.primary : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// DTO auxiliar para estruturar as informações que serão exibidas na lista do ConfirmationModal.
class ConfirmationRowData {
  final String label;
  final String value;
  final bool isTotal;

  ConfirmationRowData({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
}
