// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';

/// Widget utilitário que cria um efeito visual de "odômetro" para números inteiros.
/// Ele anima o valor de 0 até o valor final (`value`) de forma fluida.
/// É utilizado em painéis (dashboards) para dar dinamismo ao carregamento de métricas,
/// como "Quantidade de Tokens" ou "Total de Startups".
class AnimatedCounter extends StatelessWidget {
  final int value; // O número final que a animação deve alcançar
  final TextStyle style; // Estilo de texto aplicado ao contador
  final String suffix; // Texto opcional para adicionar após o número (ex: " tokens")
  final bool isVisible; // Se false, oculta o número para proteção de privacidade

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.isVisible = true, // Visível por padrão
  });

  @override
  Widget build(BuildContext context) {
    // Máscara de privacidade: Substitui o número e a animação por caracteres de censura.
    // Conecta-se diretamente aos botões de "olho" nas telas de saldo.
    if (!isVisible) {
      return Text('•••• $suffix', style: style);
    }

    // Utiliza TweenAnimationBuilder para interpolar o valor de 0 até o alvo.
    // Ele reconstrói apenas este widget Text durante a animação (alta performance).
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1000), // Duração fixa de 1 segundo
      // A curva easeOutExpo começa muito rápido e freia suavemente no fim,
      // imitando o comportamento físico de um placar giratório de moedas.
      curve: Curves.easeOutExpo,
      builder: (context, val, child) {
        return Text(
          '${val.toInt()} $suffix',
          style: style,
        );
      },
    );
  }
}
