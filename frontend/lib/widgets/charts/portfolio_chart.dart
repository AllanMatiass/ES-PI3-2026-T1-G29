// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/models/portfolio.dart';
import 'package:frontend/services/wallet_service.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:frontend/constants/colors.dart';
import 'package:intl/intl.dart';

/// Widget que exibe o gráfico de linha (Line Chart) da evolução patrimonial do usuário.
/// Conta com filtros de tempo (1D, 1W, 1M, 1Y, YTD) e interatividade de toque 
/// para visualizar o valor do patrimônio em datas específicas do passado.
class PortfolioChart extends StatefulWidget {
  const PortfolioChart({super.key});

  @override
  State<PortfolioChart> createState() => PortfolioChartState();
}

class PortfolioChartState extends State<PortfolioChart> {
  List<PortfolioHistoryPoint> _history = []; // Pontos do gráfico (Data vs Valor)
  String _selectedRange = 'YTD'; // Filtro temporal atual (Padrão: Year-to-Date)
  bool _isLoading = true; 
  
  // Índice do ponto selecionado via toque (Tooltip interativo)
  int? _selectedIndex; 
  
  // Metadados retornados pela API
  double _totalValueCents = 0; 
  double _variationPercent = 0;

  @override
  void initState() {
    super.initState();
    refresh(); // Carrega os dados ao montar o widget
  }

  /// Recarrega os dados do gráfico a partir da API.
  /// Pode ser chamado externamente através da `GlobalKey` pelo widget pai (`wallet_view.dart`)
  /// caso ocorra uma transação que altere o patrimônio (ex: depósito/saque/compra de token).
  Future<void> refresh() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _selectedIndex = null;
    });

    try {
      final result = await WalletService.getPortfolioValuation(
        range: _selectedRange,
      );

      if (mounted) {
        if (result.success && result.data != null) {
          setState(() {
            _history = result.data!.history;
            _totalValueCents = result.data!.totalValueCents;
            _variationPercent = result.data!.variationPercent;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          FeedbackModal.show(
            context: context,
            title: 'Erro ao carregar',
            message: result.message ?? 'Erro ao atualizar gráfico da carteira',
            type: FeedbackType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        FeedbackModal.show(
          context: context,
          title: 'Erro',
          message: 'Erro ao conectar ao servidor: $e',
          type: FeedbackType.error,
        );
      }
    }
  }

  /// Alterna o intervalo de tempo e recarrega a API (Ex: Trocar de 1M para 1Y)
  void _handleRangeChange(String range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
    });
    refresh();
  }

  /// Lógica de Geometria: Calcula qual ponto do gráfico foi tocado/arrastado.
  void _handleTap(Offset localPosition, Size size) {
    if (_history.length < 2) return;

    // Divide a largura do canvas pela quantidade de pontos para saber a distância (x) entre cada um
    final double stepX = size.width / (_history.length - 1);
    
    // Calcula o índice mais próximo da coordenada X tocada
    final int index = (localPosition.dx / stepX).round().clamp(
      0,
      _history.length - 1,
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 20),
          _buildFilters(),
          const SizedBox(height: 24),
          _buildChartArea(theme, isDark),
          const SizedBox(height: 12),
          _buildFooter(theme),
        ],
      ),
    );
  }

  /// Constrói o topo do card, exibindo o valor atual e a porcentagem de lucro/prejuízo
  Widget _buildHeader(ThemeData theme) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valorização do Patrimônio',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        // Se houver um ponto tocado no gráfico, exibe o valor dele (Tooltip)
        if (_selectedIndex != null)
          Text(
            currencyFormat.format(_history[_selectedIndex!].valueCents / 100),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          )
        else
        // Senão, exibe o valor total padrão atual e a badge de rendimento (%)
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                currencyFormat.format(_totalValueCents / 100),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      (_variationPercent >= 0 ? AppColors.primary : AppColors.danger)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_variationPercent >= 0 ? '+' : ''}${_variationPercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _variationPercent >= 0
                        ? AppColors.primary
                        : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Constrói a linha de botões de filtro (1D, 1W, etc)
  Widget _buildFilters() {
    final ranges = {
      '1D': '1 dia',
      '1W': '7 dias',
      '1M': '30 dias',
      '1Y': '1 ano',
      'YTD': 'Esse ano',
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ranges.entries
          .map((e) => _buildFilterButton(e.key, e.value))
          .toList(),
    );
  }

  Widget _buildFilterButton(String range, String label) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () => _handleRangeChange(range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// Constrói o Canvas (CustomPaint) onde a linha será desenhada
  Widget _buildChartArea(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _history.isEmpty
          ? const Center(child: Text('Sem dados no período'))
          : LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  // Captura toques e arrastes (Pan) para mover a agulha de seleção
                  onPanUpdate: (details) =>
                      _handleTap(details.localPosition, constraints.biggest),
                  onTapDown: (details) =>
                      _handleTap(details.localPosition, constraints.biggest),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _PortfolioLinePainter(
                      history: _history,
                      lineColor: AppColors.primary,
                      selectedIndex: _selectedIndex,
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Rodapé do gráfico que exibe as datas extremas e a data selecionada
  Widget _buildFooter(ThemeData theme) {
    if (_history.isEmpty || _isLoading) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDate(_history.first.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (_selectedIndex != null)
          Text(
            _formatDate(_history[_selectedIndex!].timestamp),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        Text(
          _formatDate(_history.last.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Formata as datas no eixo X baseando-se no intervalo de tempo
  /// (Ex: "14:30" para o gráfico de 1 Dia, ou "15/12" para os gráficos de Anos/Meses)
  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp).toLocal();
      if (_selectedRange == '1D') {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

// Pintor customizado para desenhar a linha do gráfico de evolução e a sombra gradiente.
class _PortfolioLinePainter extends CustomPainter {
  final List<PortfolioHistoryPoint> history;
  final Color lineColor;
  final int? selectedIndex;
  final bool isDark;

  _PortfolioLinePainter({
    required this.history,
    required this.lineColor,
    this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    // Normalização matemática: 
    // Encontra o menor e o maior valor para esticar/encolher o gráfico e caber na tela.
    final values = history.map((e) => e.valueCents).toList();
    final double minVal = values.reduce((a, b) => a < b ? a : b);
    final double maxVal = values.reduce((a, b) => a > b ? a : b);

    // Cria uma folga visual (15%) abaixo do ponto mais baixo
    final double range = maxVal - minVal == 0 ? 100 : (maxVal - minVal) * 1.3;
    final double offsetMin = minVal - (range * 0.15);

    final double stepX = size.width / (history.length - 1);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();

    // Desenha o caminho da linha traçando os pontos Y
    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      final double y =
          size.height -
          ((history[i].valueCents - offsetMin) / range * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Desenha o preenchimento translúcido sob a linha (Shader)
    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Se o usuário tocou no gráfico, desenha uma agulha vertical (Crosshair)
    // e duas bolinhas marcando o valor selecionado
    if (selectedIndex != null && selectedIndex! < history.length) {
      final double x = selectedIndex! * stepX;
      final double y =
          size.height -
          ((history[selectedIndex!].valueCents - offsetMin) /
              range *
              size.height);

      final Paint selectionPaint = Paint()
        ..color = isDark ? Colors.white38 : Colors.black26
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Agulha vertical
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), selectionPaint);
      
      // Bolinha externa (borda)
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = isDark ? Colors.black : Colors.white,
      );
      // Bolinha interna
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _PortfolioLinePainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
