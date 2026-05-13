import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedCurrency extends StatelessWidget {
  final double valueCents;
  final TextStyle style;
  final String prefix;
  final bool isVisible;

  const AnimatedCurrency({
    super.key,
    required this.valueCents,
    required this.style,
    this.prefix = 'R\$',
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return Text('••••••', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: valueCents),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        final formatted = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: prefix,
        ).format(value / 100);
        
        return Text(
          formatted,
          style: style,
        );
      },
    );
  }
}
