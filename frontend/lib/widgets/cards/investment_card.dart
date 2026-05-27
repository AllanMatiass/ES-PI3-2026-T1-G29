// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/widgets/animations/animated_currency.dart';
import 'package:frontend/widgets/animations/animated_counter.dart';
import 'package:frontend/constants/colors.dart';

class InvestmentCard extends StatelessWidget {
  final WalletTokenPosition position;
  final StartupListItem? startup;
  final bool isBalanceVisible;

  const InvestmentCard({
    super.key,
    required this.position,
    this.startup,
    required this.isBalanceVisible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final currentPriceCents = position is WalletTokenPositionDTO
        ? (position as WalletTokenPositionDTO).currentTokenPriceCents
        : (startup?.currentTokenPriceCents.toDouble() ?? 0.0);

    final currentValueCents = position is WalletTokenPositionDTO
        ? (position as WalletTokenPositionDTO).currentValueCents
        : (position.qtdTokens * currentPriceCents);

    final profitCents = currentValueCents - position.investedCents;
    final profitPercentage = position.investedCents <= 0
        ? 0.0
        : (profitCents / position.investedCents) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.business,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      position.startupName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    AnimatedCounter(
                      value: position.qtdTokens,
                      suffix: 'tokens',
                      isVisible: isBalanceVisible,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    if (isBalanceVisible && position.qtdTokens > 0) ...[
                      const SizedBox(height: 8),
                      _buildTokenDistributionBar(context),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (profitCents >= 0 || !isBalanceVisible
                              ? AppColors.primary
                              : AppColors.danger)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isBalanceVisible
                      ? '${profitCents >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(0)}%'
                      : '••%',
                  style: TextStyle(
                    color: profitCents >= 0 || !isBalanceVisible
                        ? AppColors.primary
                        : AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetail(
                context,
                'Investido',
                position.investedCents.toDouble(),
              ),
              _buildDetail(context, 'Valor atual', currentValueCents),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetail(
                context,
                'Lucro',
                profitCents,
                valueColor: profitCents >= 0 || !isBalanceVisible
                    ? AppColors.primary
                    : AppColors.danger,
                showSign: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDistributionBar(BuildContext context) {
    final theme = Theme.of(context);
    final total = position.qtdTokens;
    final locked = position.lockedTokens;
    final available = total - locked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: Row(
              children: [
                if (available > 0)
                  Flexible(
                    flex: available,
                    child: Container(color: AppColors.primary),
                  ),
                if (locked > 0)
                  Flexible(
                    flex: locked,
                    child: Container(color: AppColors.grey400),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildTokenLabel(
              context,
              'Disponível: $available',
              AppColors.primary,
            ),
            if (locked > 0) ...[
              const SizedBox(width: 12),
              _buildTokenLabel(
                context,
                'Bloqueado: $locked',
                AppColors.grey400,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTokenLabel(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDetail(
    BuildContext context,
    String label,
    double valueCents, {
    Color? valueColor,
    bool showSign = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedCurrency(
          valueCents: valueCents,
          isVisible: isBalanceVisible,
          prefix: showSign && valueCents >= 0 ? '+R\$' : 'R\$',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
