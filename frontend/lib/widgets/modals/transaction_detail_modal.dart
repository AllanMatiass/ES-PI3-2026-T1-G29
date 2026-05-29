// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../constants/colors.dart';
import '../animations/animated_currency.dart';

/// Bottom Sheet Modal utilizado para exibir o detalhamento completo de uma transação 
/// de ativos (Compra/Venda de Tokens). Chamado ao clicar em um card no histórico de transações.
class TransactionDetailModal extends StatelessWidget {
  final Transaction transaction; // Objeto de domínio contendo os dados do recibo
  final bool isVisible; // Controle de privacidade propagado da WalletView

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    required this.isVisible,
  });

  /// Utilitário estático para invocar o modal de forma elegante a partir de qualquer tela,
  /// utilizando o padrão `showModalBottomSheet` do Material Design.
  static void show(
    BuildContext context,
    Transaction transaction,
    bool isVisible,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal cresça conforme o conteúdo (evita corte em telas pequenas)
      backgroundColor: Colors.transparent, // Fundo transparente para aplicar cantos arredondados no Container
      builder: (context) => TransactionDetailModal(
        transaction: transaction,
        isVisible: isVisible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Identifica se a operação de tokens foi uma COMPRA (saída de dinheiro) ou VENDA (entrada de dinheiro)
    final isBuy = transaction.transactionType.contains('BUY');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Modal abraça o conteúdo, não ocupando a tela inteira
        children: [
          // "Notch" ou "Pill" indicador de arrasto no topo do Bottom Sheet
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
          
          // Ícone ilustrativo da operação de caixa
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isBuy ? AppColors.success : AppColors.danger).withOpacity(
                0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBuy ? Icons.arrow_downward : Icons.arrow_upward,
              color: isBuy ? AppColors.success : AppColors.danger,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isBuy ? 'Compra de Tokens' : 'Venda de Tokens',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          
          // O FittedBox garante que valores milionários encolham em vez de quebrar a linha (overflow)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedCurrency(
              valueCents: transaction.totalCents,
              isVisible: isVisible, // Respeita a regra de censura
              prefix: isBuy ? '- R\$' : '+ R\$',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isBuy ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Detalhamento técnico do recibo
          _buildInfoSection(theme, isDark),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Caixa com os dados estruturados da transação ("Nota Fiscal")
  Widget _buildInfoSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _buildRow('Startup', transaction.startupName, theme),
          const Divider(height: 24),
          _buildRow(
            'Quantidade',
            isVisible ? '${transaction.qtdTokens} tokens' : '•••• tokens',
            theme,
          ),
          const Divider(height: 24),
          _buildRow(
            'Preço unitário',
            isVisible ? _formatUnit(transaction.tokenPriceCents) : '••••',
            theme,
          ),
          const Divider(height: 24),
          _buildRow(
            'Data',
            _capitalize(
              DateFormat('dd MMM yyyy, HH:mm', 'pt_BR').format(
                DateTime.fromMillisecondsSinceEpoch(
                  transaction.createdAt.seconds * 1000,
                ),
              ),
            ),
            theme,
          ),
          const Divider(height: 24),
          _buildRow(
            'ID da Transação',
            transaction.id.substring(0, 8).toUpperCase(),
            theme,
            isMonospace: true, // Fonte mono-espaçada é padrão-ouro de UX para exibição de Hashes/IDs
          ),
        ],
      ),
    );
  }

  /// Método auxiliar para alinhar Chave-Valor no recibo
  Widget _buildRow(
    String label,
    String value,
    ThemeData theme, {
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  /// Converte centavos do preço unitário em BRL formatado
  String _formatUnit(double cents) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(cents / 100);
  }

  /// Força o padrão Capitalized Strings na formatação de datas (ex: "10 de Maio" invés de "10 de maio")
  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
