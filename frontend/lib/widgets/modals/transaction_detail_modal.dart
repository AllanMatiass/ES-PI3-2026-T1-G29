// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../constants/colors.dart';
import '../animations/animated_currency.dart';

class TransactionDetailModal extends StatelessWidget {
  final Transaction transaction;
  final bool isVisible;

  const TransactionDetailModal({
    super.key,
    required this.transaction,
    required this.isVisible,
  });

  static void show(
    BuildContext context,
    Transaction transaction,
    bool isVisible,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    final isBuy = transaction.transactionType.contains('BUY');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedCurrency(
              valueCents: transaction.totalCents,
              isVisible: isVisible,
              prefix: isBuy ? '- R\$' : '+ R\$',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isBuy ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 32),
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
            isMonospace: true,
          ),
        ],
      ),
    );
  }

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

  String _formatUnit(double cents) {
    return NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(cents / 100);
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
