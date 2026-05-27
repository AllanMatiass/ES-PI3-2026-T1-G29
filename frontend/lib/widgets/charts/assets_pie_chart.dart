// Autor: Allan Giovanni Matias Paes - 25008211
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as numberFormatter;
import '../../models/user.dart';
import '../../models/startup.dart';
import '../../constants/colors.dart';

class AssetsPieChart extends StatefulWidget {
  final List<WalletTokenPosition> positions;
  final Map<String, StartupListItem> startupsMap;
  final bool isBalanceVisible;

  const AssetsPieChart({
    super.key,
    required this.positions,
    required this.startupsMap,
    required this.isBalanceVisible,
  });

  @override
  State<AssetsPieChart> createState() => _AssetsPieChartState();
}

class _AssetsPieChartState extends State<AssetsPieChart> {
  int? _selectedIndex;

  final List<Color> _chartColors = AppColors.chartPalette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Processar dados
    double totalUnavailableCents = 0;
    int totalUnavailableTokens = 0;
    
    List<_PieSliceData> slices = [];
    
    for (var pos in widget.positions) {
      final startup = widget.startupsMap[pos.startupId];
      final currentPrice = startup?.currentTokenPriceCents ?? pos.averagePriceCents;
      
      // Tokens Indisponíveis (Bloqueados)
      if (pos.lockedTokens > 0) {
        totalUnavailableCents += pos.lockedTokens * currentPrice;
        totalUnavailableTokens += pos.lockedTokens;
      }
      
      // Tokens Disponíveis
      final availableTokens = pos.qtdTokens - pos.lockedTokens;
      if (availableTokens > 0) {
        final availableValue = availableTokens * currentPrice;
        final investedValue = availableTokens * pos.averagePriceCents;
        final profit = availableValue - investedValue;
        
        slices.add(_PieSliceData(
          startupName: pos.startupName,
          valueCents: availableValue.toDouble(),
          investedCents: investedValue,
          profitCents: profit,
          isUnavailable: false,
          tokensCount: availableTokens,
          color: _chartColors[slices.length % _chartColors.length],
        ));
      }
    }
    
    // Adicionar fatia de indisponíveis se houver
    if (totalUnavailableCents > 0) {
      slices.add(_PieSliceData(
        startupName: 'Tokens Indisponíveis',
        valueCents: totalUnavailableCents,
        investedCents: 0,
        profitCents: 0,
        isUnavailable: true,
        tokensCount: totalUnavailableTokens,
        color: AppColors.grey400,
      ));
    }

    if (slices.isEmpty) return const SizedBox.shrink();

    final totalValue = slices.fold<double>(0, (sum, s) => sum + s.valueCents);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) => _handleTap(details.localPosition, constraints.biggest, slices),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _PieChartPainter(
                    slices: slices,
                    totalValue: totalValue,
                    selectedIndex: _selectedIndex,
                    isBalanceVisible: widget.isBalanceVisible,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildLegend(slices, totalValue),
      ],
    );
  }

  void _handleTap(Offset localPosition, Size size, List<_PieSliceData> slices) {
    final center = Offset(size.width / 2, size.height / 2);
    final distance = (localPosition - center).distance;
    final radius = math.min(size.width, size.height) / 2;

    if (distance > radius) {
      setState(() => _selectedIndex = null);
      return;
    }

    double angle = math.atan2(localPosition.dy - center.dy, localPosition.dx - center.dx);
    if (angle < 0) angle += 2 * math.pi;

    final totalValue = slices.fold<double>(0, (sum, s) => sum + s.valueCents);
    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final sweepAngle = (slices[i].valueCents / totalValue) * 2 * math.pi;
      
      // Normalizar ângulos para comparação
      double normalizedStart = startAngle;
      while (normalizedStart < 0) normalizedStart += 2 * math.pi;
      while (normalizedStart >= 2 * math.pi) normalizedStart -= 2 * math.pi;
      
      double normalizedEnd = normalizedStart + sweepAngle;
      
      bool isHit = false;
      if (normalizedEnd > 2 * math.pi) {
        isHit = angle >= normalizedStart || angle <= (normalizedEnd - 2 * math.pi);
      } else {
        isHit = angle >= normalizedStart && angle <= normalizedEnd;
      }

      if (isHit) {
        setState(() => _selectedIndex = (_selectedIndex == i ? null : i));
        return;
      }
      startAngle += sweepAngle;
    }
  }

  Widget _buildLegend(List<_PieSliceData> slices, double totalValue) {
    if (_selectedIndex == null) {
      return Text(
        'Toque em uma fatia para ver detalhes',
        style: TextStyle(color: AppColors.grey600, fontSize: 13),
      );
    }

    final slice = slices[_selectedIndex!];
    final currencyFormat = numberFormatter.NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final percent = (slice.valueCents / totalValue * 100).toStringAsFixed(1);

    if (slice.isUnavailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey600.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey600.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Text(
              'Tokens Indisponíveis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.grey700),
            ),
            const SizedBox(height: 4),
            Text(
              '${slice.tokensCount} tokens bloqueados em ofertas',
              style: TextStyle(color: AppColors.grey600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: slice.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: slice.color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                slice.startupName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text('($percent%)', style: TextStyle(color: AppColors.grey600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem('Investido', currencyFormat.format(slice.investedCents / 100)),
              _buildDetailItem(
                'Lucro/Prej.', 
                currencyFormat.format(slice.profitCents / 100),
                color: slice.profitCents >= 0 ? AppColors.primary : AppColors.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
        const SizedBox(height: 2),
        Text(
          widget.isBalanceVisible ? value : 'R\$ •••••',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PieSliceData {
  final String startupName;
  final double valueCents;
  final double investedCents;
  final double profitCents;
  final bool isUnavailable;
  final int tokensCount;
  final Color color;

  _PieSliceData({
    required this.startupName,
    required this.valueCents,
    required this.investedCents,
    required this.profitCents,
    required this.isUnavailable,
    required this.tokensCount,
    required this.color,
  });
}

class _PieChartPainter extends CustomPainter {
  final List<_PieSliceData> slices;
  final double totalValue;
  final int? selectedIndex;
  final bool isBalanceVisible;

  _PieChartPainter({
    required this.slices,
    required this.totalValue,
    this.selectedIndex,
    required this.isBalanceVisible,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final sweepAngle = (slice.valueCents / totalValue) * 2 * math.pi;
      final isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;

      if (isSelected) {
        // Destacar fatia selecionada
        final double offset = 8.0;
        final double middleAngle = startAngle + sweepAngle / 2;
        final Offset selectedCenter = center + Offset(math.cos(middleAngle) * offset, math.sin(middleAngle) * offset);
        final Rect selectedRect = Rect.fromCircle(center: selectedCenter, radius: radius);
        
        canvas.drawArc(selectedRect, startAngle, sweepAngle, true, paint);
        
        // Borda no selecionado
        final borderPaint = Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(selectedRect, startAngle, sweepAngle, true, borderPaint);
      } else {
        canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      }

      startAngle += sweepAngle;
    }

    // Desenhar círculo central (Donut chart effect)
    final innerRadius = radius * 0.6;
    final innerPaint = Paint()..color = AppColors.white;
    canvas.drawCircle(center, innerRadius, innerPaint);
    
    // Texto central
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Patrimônio',
        style: TextStyle(color: AppColors.grey600, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, 20));

    final totalText = isBalanceVisible 
      ? numberFormatter.NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalValue / 100)
      : 'R\$ •••••';
      
    final valuePainter = TextPainter(
      text: TextSpan(
        text: totalText,
        style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    valuePainter.layout();
    valuePainter.paint(canvas, center - Offset(valuePainter.width / 2, -4));
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex || oldDelegate.isBalanceVisible != isBalanceVisible;
  }
}
