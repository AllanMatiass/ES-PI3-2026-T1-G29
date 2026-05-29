// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget semelhante ao [AnimatedCounter], porém otimizado especificamente para 
/// valores financeiros. Ele recebe o valor em centavos e cuida da conversão,
/// animação decimal e formatação para a moeda corrente (BRL - Real).
class AnimatedCurrency extends StatelessWidget {
  final double valueCents; // O valor total em centavos para evitar imprecisões flutuantes
  final TextStyle style;
  final String prefix; // Permite trocar a moeda, embora R$ seja o padrão no Mescla Invest
  final bool isVisible; // Controle de privacidade do saldo

  const AnimatedCurrency({
    super.key,
    required this.valueCents,
    required this.style,
    this.prefix = 'R\$',
    this.isVisible = true, // Visível por padrão
  });

  @override
  Widget build(BuildContext context) {
    // Máscara de privacidade para ocultar o saldo em tela cheia (Card da Carteira)
    if (!isVisible) {
      return Text('••••••', style: style);
    }

    // TweenAnimation interpolando de 0 até o total de centavos (double)
    // A animação acontece na casa dos centavos, e a formatação transforma isso
    // na string correta (ex: animando de R$ 0,00 até R$ 10.000,50)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: valueCents),
      duration: const Duration(milliseconds: 1000), // Duração padronizada da UI (1s)
      curve: Curves.easeOutExpo, // Acelera no começo, freia para o usuário conseguir ler o fim
      builder: (context, value, child) {
        
        // Conversão em tempo real do frame da animação (centavos -> double formatado BRL)
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
