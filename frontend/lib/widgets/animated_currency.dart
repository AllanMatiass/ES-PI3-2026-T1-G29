// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que anima a transição de um valor monetário (em centavos) formatando para BRL.
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
    // Máscara de privacidade para o saldo
    if (!isVisible) {
      return Text('••••••', style: style);
    }

    // Anima o valor de 0 até o total de centavos
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: valueCents),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        // Converte centavos para reais (/100) e formata com locale pt_BR
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
