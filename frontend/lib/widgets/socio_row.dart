// Autor: Pedro Romanato - 25004075
import 'package:flutter/material.dart';

/// mostrando avatar com iniciais, nome, cargo e percentual de participação.
class SocioRow extends StatelessWidget {
  /// Iniciais do nome do sócio (ex: "PR" para Pedro Romanato)
  final String iniciais;

  /// Nome completo do sócio
  final String nome;

  /// Cargo ou função do sócio na empresa
  final String cargo;

  /// Percentual de participação societária
  final String porcentagem;

  const SocioRow({
    super.key,
    required this.iniciais,
    required this.nome,
    required this.cargo,
    required this.porcentagem,
  });

  @override
  Widget build(BuildContext context) {
    // se adapta de acrodo com o tema mudando as cores
    final theme = Theme.of(context);
    return Row(
      children: [
        // Avatar circular com as iniciais do sócio
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF00A84E).withOpacity(0.1),
          child: Text(
            iniciais,
            style: const TextStyle(
              color: Color(0xFF00A84E),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Coluna central com nome e cargo, expandida para ocupar o espaço disponível
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome completo do sócio
              Text(
                nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              // Cargo/função do sócio
              Text(
                cargo,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Percentual de participação societária exibido em destaque
        Text(
          porcentagem,
          style: const TextStyle(
            color: Color(0xFF00A84E),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
