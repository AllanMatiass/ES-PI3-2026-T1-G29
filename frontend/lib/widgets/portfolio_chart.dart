// Autor: Gemini CLI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/portfolio.dart';
import '../services/wallet_service.dart';
import '../widgets/modals/feedback_modal.dart';
import '../constants/colors.dart';

/// Widget que exibe o gráfico de valorização do patrimônio do usuário.
class PortfolioChart extends StatefulWidget {
  const PortfolioChart({super.key});

  @override
  State<PortfolioChart> createState() => _PortfolioChartState();
}

class _PortfolioChartState extends State<PortfolioChart> {
  List<PortfolioHistoryPoint> _history = [];
  String _selectedRange = 'YTD';
  bool _isLoading = true;
  int? _selectedIndex;
  double _totalValueCents = 0;
  double _variationPercent = 0;
  String _currency = 'BRL';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _selectedIndex = null;
    });

    try {
      final result = await WalletService.getPortfolioValuation(range: _selectedRange);

      if (mounted) {
        if (result.success && result.data != null) {
          setState(() {
            _history = result.data!.history;
            _totalValueCents = result.data!.totalValueCents;
            _variationPercent = result.data!.variationPercent;
            _currency = result.data!.currency;
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

  void _handleRangeChange(String range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
    });
    _loadData();
  }

  void _handleTap(Offset localPosition, Size size) {
    if (_history.length < 2) return;
    
    final double stepX = size.width / (_history.length - 1);
    final int index = (localPosition.dx / stepX).round().clamp(0, _history.length - 1);
    
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
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
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

  Widget _buildHeader(ThemeData theme) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
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
                  color: (_variationPercent >= 0 ? AppColors.primary : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_variationPercent >= 0 ? '+' : ''}${_variationPercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _variationPercent >= 0 ? AppColors.primary : Colors.red,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFilters() {
    final ranges = ['1D', '1W', '1M', '1Y', 'YTD'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ranges.map((r) => _buildFilterButton(r)).toList(),
    );
  }

  Widget _buildFilterButton(String range) {
    final isSelected = _selectedRange == range;
    return GestureDetector(
      onTap: () => _handleRangeChange(range),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          range,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChartArea(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _history.isEmpty
              ? const Center(child: Text('Sem dados no período'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanUpdate: (details) => _handleTap(details.localPosition, constraints.biggest),
                      onTapDown: (details) => _handleTap(details.localPosition, constraints.biggest),
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

  Widget _buildFooter(ThemeData theme) {
    if (_history.isEmpty || _isLoading) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDate(_history.first.timestamp),
          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
        ),
        if (_selectedIndex != null)
          Text(
            _formatDate(_history[_selectedIndex!].timestamp),
            style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        Text(
          _formatDate(_history.last.timestamp),
          style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      if (_selectedRange == '1D') {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

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

    final values = history.map((e) => e.valueCents).toList();
    final double minVal = values.reduce((a, b) => a < b ? a : b);
    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    
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
    
    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((history[i].valueCents - offsetMin) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Gradient fill
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

    if (selectedIndex != null && selectedIndex! < history.length) {
      final double x = selectedIndex! * stepX;
      final double y = size.height - ((history[selectedIndex!].valueCents - offsetMin) / range * size.height);

      final Paint selectionPaint = Paint()
        ..color = isDark ? Colors.white38 : Colors.black26
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), selectionPaint);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = isDark ? Colors.black : Colors.white);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _PortfolioLinePainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.selectedIndex != selectedIndex || oldDelegate.isDark != isDark;
  }
}
