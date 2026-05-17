import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/widgets/feedback_modal.dart';

class DocumentsDownloadCard extends StatelessWidget {
  final String? pitchDeckUrl;
  final String? businessPlanUrl;
  final String? executiveSummary;

  const DocumentsDownloadCard({
    super.key,
    this.pitchDeckUrl,
    this.businessPlanUrl,
    this.executiveSummary,
  });

  bool get _hasAny =>
      pitchDeckUrl != null ||
      businessPlanUrl != null ||
      executiveSummary != null;

  Future<void> _launch(BuildContext context, String? url, String label) async {
    if (url == null || url.isEmpty) {
      FeedbackModal.show(
        context: context,
        title: 'Indisponível',
        message: '$label não disponível',
        type: FeedbackType.info,
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        FeedbackModal.show(
          context: context,
          title: 'Erro',
          message: 'Não foi possível abrir $label',
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documentos',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          _DocItem(
            icon: Icons.slideshow_rounded,
            label: 'Apresentação para investidores',
            available: pitchDeckUrl != null,
            onTap: () => _launch(context, pitchDeckUrl, 'Pitch Deck'),
          ),
          Divider(height: 20, color: theme.dividerColor.withOpacity(0.1)),
          _DocItem(
            icon: Icons.description_rounded,
            label: 'Plano de negócios',
            available: businessPlanUrl != null,
            onTap: () => _launch(context, businessPlanUrl, 'Business Plan'),
          ),
          Divider(height: 20, color: theme.dividerColor.withOpacity(0.1)),
          _DocItem(
            icon: Icons.summarize_rounded,
            label: 'Resumo Executivo',
            available: executiveSummary != null,
            onTap: () =>
                _launch(context, executiveSummary, 'Executive Summary'),
          ),
        ],
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool available;
  final VoidCallback onTap;

  const _DocItem({
    required this.icon,
    required this.label,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = available ? const Color(0xFF00A84E) : theme.colorScheme.onSurfaceVariant.withOpacity(0.5);

    return InkWell(
      onTap: available ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: available
                    ? const Color(0xFF00A84E).withOpacity(0.1)
                    : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: available ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            Icon(
              available
                  ? Icons.download_rounded
                  : Icons.lock_outline_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
