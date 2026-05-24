// Autor: Pedro Romanato
import 'package:flutter/material.dart';

class SocioRow extends StatelessWidget {
  final String iniciais;
  final String nome;
  final String cargo;
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
    final theme = Theme.of(context);
    return Row(
      children: [
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
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
