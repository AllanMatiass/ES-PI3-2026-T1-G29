// Autor: Allan Giovanni Matias Páes
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/event.dart';

class SentimentBadge extends StatelessWidget {
  final NewsSentiment sentiment;
  final bool compact;

  const SentimentBadge({
    super.key,
    required this.sentiment,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color = _getColor();
    final IconData icon = _getIcon();
    final String label = sentiment.label;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    return switch (sentiment) {
      NewsSentiment.excellent => AppColors.warning,
      NewsSentiment.good => AppColors.success,
      NewsSentiment.neutral => AppColors.grey600,
      NewsSentiment.bad => AppColors.danger,
      NewsSentiment.disaster => const Color(0xFF7F1D1D), // Dark Red
    };
  }

  IconData _getIcon() {
    return switch (sentiment) {
      NewsSentiment.excellent => Icons.star,
      NewsSentiment.good => Icons.trending_up,
      NewsSentiment.neutral => Icons.trending_flat,
      NewsSentiment.bad => Icons.trending_down,
      NewsSentiment.disaster => Icons.warning_amber_rounded,
    };
  }
}
