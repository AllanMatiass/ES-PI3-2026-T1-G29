import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;

  MyOfferCard({super.key, required this.offer});

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  String _formatCurrency(int cents) {
    return _currencyFormat.format(cents / 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = offer['status'] ?? 'OPEN';
    final remaining = offer['remainingQtdTokens'] ?? 0;
    final initial = offer['initialQtdTokens'] ?? 0;
    final sold = offer['soldQtdTokens'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                offer['startupName'] ?? 'Startup',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(context, Icons.token_outlined, '$remaining / $initial', label: 'tokens rest.'),
              _buildInfoItem(context, Icons.monetization_on_outlined, _formatCurrency(offer['tokenPriceCents'] ?? 0), label: 'cada'),
            ],
          ),
          Divider(height: 24, color: theme.dividerColor.withOpacity(0.1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Ganho',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  Text(
                    _formatCurrency(offer['totalEarnedCents'] ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF00A84E),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Vendidos',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  Text(
                    '$sold tokens',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String value, {String? label}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (label != null)
              Text(
                label,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status;

    switch (status.toUpperCase()) {
      case 'OPEN':
        color = Colors.green;
        text = 'Aberta';
        break;
      case 'ACCEPTED':
        color = Colors.blue;
        text = 'Finalizada';
        break;
      case 'CANCELLED':
        color = Colors.red;
        text = 'Cancelada';
        break;
      case 'EXPIRED':
        color = Colors.orange;
        text = 'Expirada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
