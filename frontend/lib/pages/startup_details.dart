//Autor: Pedro Vinicius Romanato & Allan Giovanni Matias Paes

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import 'package:intl/intl.dart';
import '../models/startup.dart';
import '../services/startup_service.dart';
import '../widgets/price_chart.dart';
import './faq_page.dart';
import 'package:frontend/pages/buy_from_startup_page.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class StartupDetailsPage extends StatefulWidget {
  final String startupId;

  const StartupDetailsPage({super.key, required this.startupId});

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  StartupData? _startupData;
  bool _isLoading = true;
  String? _errorMessage;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  final NumberFormat _decimalFormat = NumberFormat.decimalPattern('pt_BR');

  final NumberFormat _percentFormat = NumberFormat.decimalPattern('pt_BR')
    ..minimumFractionDigits = 1
    ..maximumFractionDigits = 2;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await StartupService.getStartupDetails(widget.startupId);
    if (mounted) {
      if (result.success) {
        setState(() {
          _startupData = result.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
        FeedbackModal.show(
          context: context,
          title: 'Erro ao carregar',
          message: result.message ?? 'Não foi possível carregar os detalhes da startup',
          type: FeedbackType.error,
        );
      }
    }
  }

  String _formatCurrency(num value) {
    return _currencyFormat.format(value);
  }

  String _formatNumber(num value) {
    return _decimalFormat.format(value);
  }

  String _formatPercent(num value) {
    return _percentFormat.format(value);
  }

  String gerarIniciais(String nome) {
    List<String> partes = nome.trim().split(" ");
    if (partes.length >= 2) {
      return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase();
    }
    return partes[0].isNotEmpty ? partes[0][0].toUpperCase() : "?";
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: const Center(child: CircularProgressIndicator(color: Color(0xFF00A84E))));
    }

    if (_errorMessage != null || _startupData == null) {
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro: ${_errorMessage ?? "Erro desconhecido"}',
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Tentar Novamente'),
              )
            ],
          )));
    }

    final data = _startupData!;

    final double progressoBarra = data.totalTokens > 0
        ? (data.circulatingTokens / data.totalTokens).clamp(0.0, 1.0)
        : 0.0;

    final double percentualVendido = progressoBarra * 100;

    Color corRisco = const Color.fromARGB(255, 255, 102, 0);
    if (data.riskLabel.toLowerCase().contains("baixo")) corRisco = Colors.green;
    if (data.riskLabel.toLowerCase().contains("alto")) corRisco = Colors.red;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: FixedHeader(
        name: data.name,
        segment: data.segment,
        logoPath: data.logoUrl,
        shortDescription: data.shortDescription,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF00A84E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card de Retorno
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: data.expectedReturn >= 0
                        ? const Color(0xFF25A830)
                        : Colors.redAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Retorno esperado',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      Row(
                        children: [
                          Icon(
                              data.expectedReturn >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: Colors.white,
                              size: 30),
                          const SizedBox(width: 8),
                          Text('${data.expectedReturn}x',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30)),
                        ],
                      ),
                      const Text('ao ano',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Risco e Prazo
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Risco',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 14)),
                            Text(
                              data.riskLabel.replaceAll("Risco ", ""),
                              style: TextStyle(
                                  color: corRisco,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(15)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prazo',
                                style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 14)),
                            Text(
                              data.horizon.split(" ").first,
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Gráfico de Preço
                PriceHistoryChart(
                  startupId: data.id,
                  initialHistory: data.history,
                  currency: data.meta.currency,
                ),
                const SizedBox(height: 15),

                // Métricas de Mercado
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Métricas de Mercado',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 15),
                      _buildMarketMetric('Valuation Atual',
                          _formatCurrency(data.valuation / 100)),
                      Divider(height: 30, color: theme.dividerColor.withOpacity(0.1)),
                      Row(
                        children: [
                          Expanded(
                              child: _buildMarketMetric('Preço Médio',
                                  _formatCurrency(data.summary.averagePrice))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildMarketMetric('Variação',
                                  '${_formatPercent(data.history.isNotEmpty ? data.history.last.variationPercent ?? 0 : 0)}%')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tokens em circulação',
                          style:
                              TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: progressoBarra,
                        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        color: const Color(0xFF00A84E),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatNumber(data.totalTokens)} emitidos',
                            style: TextStyle(
                                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            '${_formatPercent(percentualVendido)}% vendidos',
                            style: TextStyle(
                                fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                CardSobreStartup(descricao: data.longDescription),
                const SizedBox(height: 15),
                if (data.demoVideos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vídeo de demonstração',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: theme.colorScheme.onSurface)),
                          const SizedBox(height: 12),
                          DemoVideoPlayer(videoUrl: data.demoVideos.first),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                DocumentsDownloadCard(
                  pitchDeckUrl: data.pitchDeckUrl,
                  businessPlanUrl: data.businessPlanUrl,
                  executiveSummary: data.executiveSummary,
                ),
                const SizedBox(height: 15),
                // Tags
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(15)),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        data.tags.map((tag) => _buildTag(tag)).toList(),
                  ),
                ),
                const SizedBox(height: 15),

                // Sócios
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sócios',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20, color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 15),
                      ...data.founders.map((founder) => Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: _buildSocioRow(
                              context,
                              gerarIniciais(founder.name),
                              founder.name,
                              founder.role,
                              "${founder.equityPercent}%",
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Botão FAQ
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FAQPage(
                          questions: data.questions,
                          startupName: data.name,
                          logoUrl: data.logoUrl,
                          startupId: data.id,
                          access: data.access,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.question_answer_outlined),
                  label: const Text('FAQ da Startup',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00A84E),
                    side: const BorderSide(
                        color: Color(0xFF00A84E), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BuyFromStartupPage(
                          startupId: data.id,
                          startupName: data.name,
                          tokenPriceCents: data.currentTokenPriceCents,
                          logoUrl: data.logoUrl,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A84E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Investir agora',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildTag(String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurface)),
    );
  }

  Widget _buildMarketMetric(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: theme.colorScheme.onSurface)),
      ],
    );
  }
}

class FixedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String segment;
  final String logoPath;
  final String shortDescription;

  const FixedHeader(
      {super.key,
      required this.name,
      required this.segment,
      required this.logoPath,
      required this.shortDescription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          bottom: 15),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  logoPath,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.business, size: 50, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A84E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        segment.replaceFirst(segment[0], segment[0].toUpperCase()),
                        style: const TextStyle(
                          color: Color(0xFF00A84E),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            shortDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(200);
}

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
      decoration:
          BoxDecoration(color: theme.colorScheme.surface, border: Border.all(color: theme.dividerColor.withOpacity(0.1)), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sobre a startup',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                text: widget.descricao,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
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
                    overflow:
                        isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
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

Widget _buildSocioRow(
    BuildContext context, String iniciais, String nome, String cargo, String porcentagem) {
  final theme = Theme.of(context);
  return Row(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF00A84E).withOpacity(0.1),
        child: Text(iniciais,
            style: const TextStyle(
                color: Color(0xFF00A84E), fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nome,
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface)),
            Text(cargo,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      Text(porcentagem,
          style: const TextStyle(
              color: Color(0xFF00A84E),
              fontWeight: FontWeight.bold,
              fontSize: 16)),
    ],
  );
}
class DemoVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const DemoVideoPlayer({super.key, required this.videoUrl});

  @override
  State<DemoVideoPlayer> createState() => _DemoVideoPlayerState();
}

class _DemoVideoPlayerState extends State<DemoVideoPlayer> {
  late VideoPlayerController _controller;
  bool _hasError = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    if (!widget.videoUrl.startsWith('https://firebasestorage.googleapis.com/')) {
      setState(() => _hasError = true);
      return;
    }

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_hasError) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Vídeo Indisponível",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF00A84E))),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                _ControlsOverlay(controller: _controller),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF00A84E),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateOverlay);
  }

  @override
  void didUpdateWidget(_ControlsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateOverlay);
      widget.controller.addListener(_updateOverlay);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateOverlay);
    super.dispose();
  }

  void _updateOverlay() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isFinished = widget.controller.value.isInitialized &&
        widget.controller.value.position >= widget.controller.value.duration;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isFinished) {
          widget.controller.seekTo(Duration.zero);
          widget.controller.play();
        } else {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        }
      },
      child: Stack(
        children: <Widget>[
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 50),
            reverseDuration: const Duration(milliseconds: 200),
            child: widget.controller.value.isPlaying
                ? const SizedBox.shrink()
                : Container(
                    color: Colors.black26,
                    child: Center(
                      child: Icon(
                        isFinished ? Icons.replay : Icons.play_arrow,
                        color: Colors.white,
                        size: 100.0,
                        semanticLabel: isFinished ? 'Replay' : 'Play',
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}


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
