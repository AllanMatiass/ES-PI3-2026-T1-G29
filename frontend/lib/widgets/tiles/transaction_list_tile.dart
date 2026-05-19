// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../constants/colors.dart';
import '../animations/animated_currency.dart';
import '../modals/transaction_detail_modal.dart';

class TransactionListTile extends StatelessWidget {
  final Transaction transaction;
  final bool isVisible;

  const TransactionListTile({
    super.key,
    required this.transaction,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBuy = transaction.transactionType.contains('BUY');
    final date = DateTime.fromMillisecondsSinceEpoch(transaction.createdAt.seconds * 1000);
    final formattedDate = DateFormat('dd MMM, HH:mm', 'pt_BR').format(date);

    return InkWell(
      onTap: () => TransactionDetailModal.show(context, transaction, isVisible),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (isBuy ? AppColors.success : AppColors.danger).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isBuy ? Icons.arrow_downward : Icons.arrow_upward,
          color: isBuy ? AppColors.success : AppColors.danger,
        ),
      ),
      title: Text(
        transaction.startupName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        '$formattedDate • ${isVisible ? transaction.qtdTokens : '••••'} tokens',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedCurrency(
              valueCents: transaction.totalCents,
              isVisible: isVisible,
              prefix: isBuy ? '- R\$' : '+ R\$',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isBuy ? AppColors.danger : AppColors.success,
              ),
            ),
          ),
          Text(
            _getTransactionTypeName(transaction.transactionType),
            style: TextStyle(
              fontSize: 10, 
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

  String _getTransactionTypeName(String type) {
    switch (type) {
      case 'BUY_FROM_STARTUP':
        return 'Compra Direta';
      case 'USER_TRADE':
        return 'Negociação P2P';
      default:
        return 'Transação';
    }
  }
}
