import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class CardSobreStartup extends StatefulWidget {
  final String descricao;
  const CardSobreStartup({super.key, required this.descricao});

  @override
  State<CardSobreStartup> createState() => _CardSobreStartupState();
}

class _CardSobreStartupState extends State<CardSobreStartup> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sobre a startup',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                text: widget.descricao,
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              );
              final tp = TextPainter(
                text: span,
                maxLines: 3,
                textAlign: TextAlign.left,
                textDirection: ui.TextDirection.ltr,
              );
              tp.layout(maxWidth: constraints.maxWidth);
              final needsExpansion = tp.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.descricao,
                    maxLines: isExpanded ? null : 3,
                    overflow: isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                  if (needsExpansion)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => isExpanded = !isExpanded),
                        child: Row(
                          children: [
                            Text(isExpanded ? 'Ver menos' : 'Ver mais',
                                style: const TextStyle(
                                    color: Color(0xFF00A84E),
                                    fontWeight: FontWeight.bold)),
                            Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF00A84E)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
