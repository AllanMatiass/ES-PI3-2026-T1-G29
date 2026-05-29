// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/widgets/shimmer_placeholder.dart';
import 'package:frontend/widgets/tiles/sentiment_badge.dart';
import 'package:intl/intl.dart';

/// Página de leitura detalhada de uma notícia ou evento.
/// Exibe o conteúdo completo, tags, sentimento e informações da startup vinculada.
class NewsDetailPage extends StatefulWidget {
  final Event event; // O evento (notícia) a ser exibido

  const NewsDetailPage({super.key, required this.event});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  StartupData? _startup; // Dados da startup mencionada na notícia
  bool _isLoadingStartup = true; // Estado de carregamento do perfil da startup

  @override
  void initState() {
    super.initState();
    _loadStartup(); // Busca detalhes da startup para exibir o mini-perfil
  }

  /// Busca os dados da startup vinculada à notícia via ID
  Future<void> _loadStartup() async {
    final result = await StartupService.getStartupDetails(
      widget.event.startupId,
    );
    if (result.success && mounted) {
      setState(() {
        _startup = result.data;
        _isLoadingStartup = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingStartup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Formatação da data da notícia (Ex: 29 de Maio 2026, 14:00)
    final dateStr = DateFormat(
      'dd MMMM yyyy, HH:mm',
      'pt_BR',
    ).format(widget.event.createdAt);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Tags e Sentimento (Indicadores rápidos)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SentimentBadge(sentiment: widget.event.sentiment), // Badge de Positivo/Neutro/Negativo
                  ...widget.event.tags.map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Título Principal da Notícia
            Text(
              widget.event.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Autor da Notícia (Padrão: Mescla Invest)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      'assets/images/logo_sembg.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mescla Invest',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Autor Oficial',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Perfil da Startup relacionada (Contexto para o investidor)
            _buildStartupProfile(theme, isDark, dateStr),

            const SizedBox(height: 24),
            // Resumo/Lead da notícia em destaque
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.05,
                  ),
                ),
              ),
              child: Text(
                widget.event.summary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Conteúdo textual completo da notícia
            Text(
              widget.event.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Constrói o mini-perfil da startup vinculada à notícia
  Widget _buildStartupProfile(ThemeData theme, bool isDark, String dateStr) {
    if (_isLoadingStartup) {
      return const ShimmerPlaceholder(height: 60, borderRadius: 12);
    }

    if (_startup == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: _startup!.logoUrl != null
                ? NetworkImage(_startup!.logoUrl)
                : null,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: _startup!.logoUrl == null
                ? const Icon(Icons.business, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _startup!.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  dateStr,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
