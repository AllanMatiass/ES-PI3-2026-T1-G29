// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../animations/animated_currency.dart';

class InvestmentListTile extends StatelessWidget {
  final WalletTokenPosition position;
  final bool isVisible;

  const InvestmentListTile({
    super.key,
    required this.position,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.business, 
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.startupName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  isVisible ? '${position.qtdTokens} tokens' : '•••• tokens',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedCurrency(
                  valueCents: position.investedCents,
                  isVisible: isVisible,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                'Total Investido',
                style: TextStyle(
                  fontSize: 10, 
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
