//Autores:
// Pedro Vinicius Romanato - 25004075
// Allan Giovanni Matias Paes - 25008211

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/charts/price_chart.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:frontend/widgets/socio_row.dart';
import 'package:intl/intl.dart';
import '../../../models/startup.dart';
import '../../../services/startup_service.dart';
import '../../../widgets/headers/startup_fixed_header.dart';
import '../../../widgets/cards/card_sobre_startup.dart';
import '../../../widgets/demo_video_player.dart';
import '../../../widgets/cards/documents_download_card.dart';
import 'faq_page.dart';
import 'package:frontend/pages/invest/startup/buy_from_startup_page.dart';
import 'package:frontend/services/event_service.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/pages/news/news_detail_page.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/widgets/shimmer_placeholder.dart';
import 'package:frontend/widgets/tiles/sentiment_badge.dart';

/// Página principal de detalhes de uma startup, agregando informações financeiras, 
/// histórico de preços, notícias, sócios e documentos para investimento.
class StartupDetailsPage extends StatefulWidget {
  final String startupId;

  const StartupDetailsPage({super.key, required this.startupId});

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  StartupData? _startupData; // Dados técnicos e financeiros da startup
  List<Event> _newsEvents = []; // Lista de notícias/eventos recentes vinculados à startup
  
  // Estados de controle de carregamento e erro
  bool _isLoading = true;
  bool _isLoadingNews = true;
  String? _errorMessage;

  // Formatadores para padronização de exibição (Moeda, Números e Percentuais)
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
    _loadData(); // Carrega os detalhes principais (Valuation, FAQ, Sócios)
    _loadNews(); // Carrega o feed de notícias específico desta startup
  }

  /// Busca os detalhes da startup via StartupService
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final result = await StartupService.getStartupDetails(widget.startupId);
    if (mounted) {
      if (result.success) {
        setState(() {
          _startupData = result.data;
          _isLoading = false;
        });
        return;
      }
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

  /// Busca notícias recentes relacionadas à startup via EventService
  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);
    final result = await EventService.listEvents(
      startupId: widget.startupId,
      limit: 3,
    );
    if (mounted) {
      if (result.success) {
        setState(() {
          _newsEvents = result.data?.events ?? [];
          _isLoadingNews = false;
        });
      } else {
        setState(() => _isLoadingNews = false);
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
    await Future.wait([_loadData(), _loadNews()]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Estado de Carregamento Principal
    if (_isLoading) {
      return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: const Center(child: CircularProgressIndicator(color: Color(0xFF00A84E))));
    }

    // Estado de Erro ou Dados Ausentes
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
          ))
      );
    }

    final data = _startupData!;

    // Cálculos de progresso da oferta de tokens
    final double progressoBarra = data.totalTokens > 0
        ? (data.circulatingTokens / data.totalTokens).clamp(0.0, 1.0)
        : 0.0;

    final double percentualVendido = progressoBarra * 100;

    // Lógica visual para indicação de risco
    Color corRisco = AppColors.warning;
    if (data.riskLabel.toLowerCase().contains("baixo")) corRisco = AppColors.primary;
    if (data.riskLabel.toLowerCase().contains("alto")) corRisco = AppColors.danger;

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
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card de Retorno Esperado (Destaque principal do investimento)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: data.expectedReturn >= 0
                        ? AppColors.primary
                        : AppColors.danger,
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

                // Seção de Risco e Prazo Estimado
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

                // Gráfico de Preço (Componente reutilizável para histórico de tokens)
                PriceHistoryChart(
                  startupId: data.id,
                  initialHistory: data.history,
                  currency: data.meta.currency,
                ),
                const SizedBox(height: 15),

                // Bloco de Métricas de Mercado (Valuation e Preços)
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
                      _buildMarketMetric('Valor de Mercado',
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
                                  '${_formatPercent(
                                      data.history.isNotEmpty
                                      ? data.history.last.variationPercent ?? 0
                                      : 0)}%'
                              )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Barra de Progresso de Venda de Tokens
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

                // Descrição Detalhada (Markdown/Texto longo)
                CardSobreStartup(descricao: data.longDescription),
                const SizedBox(height: 15),

                // Vídeos de Pitch ou Demonstração do Produto
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

                // Seção Dinâmica de Notícias e Eventos (Agregador de valor)
                _buildNewsSection(theme, data),
                const SizedBox(height: 15),

                // Documentos Oficiais para Download (Pitch Deck, Business Plan)
                DocumentsDownloadCard(
                  pitchDeckUrl: data.pitchDeckUrl,
                  businessPlanUrl: data.businessPlanUrl,
                  executiveSummary: data.executiveSummary,
                ),
                const SizedBox(height: 15),

                // Tags de Categorização
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

                // Lista de Fundadores e Sócios (Equipe por trás do projeto)
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
                            child: SocioRow(
                              iniciais: gerarIniciais(founder.name),
                              nome: founder.name,
                              cargo: founder.role,
                              porcentagem: "${founder.equityPercent}%",
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // CTA secundário: Canal de dúvidas
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
                  label: const Text('Perguntas Frequentes',
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

                // Conversão para Investimento
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

  Widget _buildNewsSection(ThemeData theme, StartupData data) {
    if (_isLoadingNews) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notícias Recentes',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          ...List.generate(3, (index) => const ShimmerPlaceholder(
            height: 80,
            borderRadius: 12,
            margin: EdgeInsets.only(bottom: 12),
          )),
        ],
      );
    }

    if (_newsEvents.isEmpty) return const SizedBox.shrink();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notícias Recentes',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: theme.colorScheme.onSurface)),
              TextButton(
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        userName: user?.displayName ?? 'Usuário',
                        initialIndex: 1,
                        initialStartupId: widget.startupId,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Mais notícias',
                    style: TextStyle(color: Color(0xFF00A84E), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._newsEvents.map((event) => _buildNewsTile(theme, event)),
        ],
      ),
    );
  }

  Widget _buildNewsTile(ThemeData theme, Event event) {
    final dateStr = DateFormat('dd/MM/yyyy').format(event.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SentimentBadge(sentiment: event.sentiment, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF00A84E)),
            ],
          ),
        ),
      ),
    );
  }
}
