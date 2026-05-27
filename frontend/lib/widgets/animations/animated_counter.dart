// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';

/// Widget que anima a transição de um número inteiro de 0 até o valor final.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String suffix;
  final bool isVisible;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    // Se não estiver visível, exibe pontos (máscara de privacidade)
    if (!isVisible) {
      return Text('•••• $suffix', style: style);
    }

    // Utiliza TweenAnimationBuilder para interpolar o valor de 0 até o alvo em 1 segundo
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutExpo, // Curva de animação suave que desacelera no final
      builder: (context, val, child) {
        return Text(
          '${val.toInt()} $suffix',
          style: style,
        );
      },
    );
  }
}
