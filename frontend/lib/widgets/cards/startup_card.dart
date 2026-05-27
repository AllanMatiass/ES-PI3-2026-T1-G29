// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/startup.dart';
import '../../pages/invest/startup/startup_details.dart';
import '../../pages/invest/startup/buy_from_startup_page.dart';

class StartupCard extends StatelessWidget {
  final StartupListItem startup;

  StartupCard({super.key, required this.startup});

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  final NumberFormat _decimalFormat = NumberFormat.decimalPattern('pt_BR');

  String _formatCurrency(int cents) {
    return _currencyFormat.format(cents / 100);
  }

  String _formatNumber(int number) {
    return _decimalFormat.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StartupDetailsPage(startupId: startup.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Image and Basic Info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: startup.coverImageUrl != null
                          ? Image.network(
                              startup.coverImageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildLogoPlaceholder(context, 80),
                            )
                          : _buildLogoPlaceholder(context, 80),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  startup.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (startup.priceVariation != null)
                                _buildVariationBadge(startup.priceVariation!),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStageColor(startup.stage).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              startup.stage.toDisplayString(),
                              style: TextStyle(
                                color: _getStageColor(startup.stage),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  startup.shortDescription,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),

              // Financial and Token Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'Capital Levantado',
                      _formatCurrency(startup.capitalRaisedCents),
                      Icons.account_balance,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Total de Tokens',
                      _formatNumber(startup.totalTokensIssued),
                      Icons.token_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Preço Atual do Token',
                      _formatCurrency(startup.currentTokenPriceCents),
                      Icons.monetization_on_outlined,
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StartupDetailsPage(startupId: startup.id),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00A84E),
                          side: const BorderSide(color: Color(0xFF00A84E)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ver detalhes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuyFromStartupPage(
                                startupId: startup.id,
                                startupName: startup.name,
                                tokenPriceCents: startup.currentTokenPriceCents,
                                logoUrl: startup.coverImageUrl,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A84E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Investir',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tags
              if (startup.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: startup.tags
                        .map((tag) => _buildTag(context, tag))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00A84E)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildVariationBadge(double variation) {
    bool isPositive = variation >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF00A84E).withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? const Color(0xFF00A84E) : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${variation.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? const Color(0xFF00A84E) : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String tag) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context, double size) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: const Icon(Icons.business, color: Color(0xFF00A84E), size: 32),
    );
  }

  Color _getStageColor(StartupStage stage) {
    switch (stage) {
      case StartupStage.nova:
        return Colors.blue;
      case StartupStage.em_operacao:
        return Colors.green;
      case StartupStage.em_expansao:
        return Colors.orange;
    }
  }
}
