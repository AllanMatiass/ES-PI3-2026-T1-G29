// Autor: Allan Giovanni Matias Páes
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/wallet_transaction.dart';
import '../../constants/colors.dart';
import '../animations/animated_currency.dart';

class MovementListTile extends StatelessWidget {
  final Movement movement;
  final bool isVisible;

  const MovementListTile({
    super.key,
    required this.movement,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeposit = movement.type == 'DEPOSIT';
    final date = movement.createdAt.toDateTime();
    final formattedDate = DateFormat('dd MMM, HH:mm', 'pt_BR').format(date);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: (isDeposit ? AppColors.success : AppColors.danger).withOpacity(
            0.1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isDeposit ? Icons.add_circle_outline : Icons.remove_circle_outline,
          color: isDeposit ? AppColors.success : AppColors.danger,
        ),
      ),
      title: Text(
        isDeposit ? 'Depósito' : 'Saque',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        formattedDate,
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
              valueCents: movement.amountInCents.toDouble(),
              isVisible: isVisible,
              prefix: isDeposit ? '+ R\$' : '- R\$',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDeposit ? AppColors.success : AppColors.danger,
              ),
            ),
          ),
          Text(
            isDeposit ? 'Concluído' : 'Processado',
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
