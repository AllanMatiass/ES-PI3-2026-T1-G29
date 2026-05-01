import 'package:flutter/material.dart';
import '../models/startup.dart';
import '../services/startup_service.dart';

class PriceHistoryChart extends StatefulWidget {
  final String startupId;
  final List<PriceHistoryItem> initialHistory;
  final String currency;

  const PriceHistoryChart({
    super.key,
    required this.startupId,
    required this.initialHistory,
    required this.currency,
  });

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  late List<PriceHistoryItem> history;
  String selectedFilter = 'YTD';
  bool isLoading = false;
  DateTimeRange? customRange;

  @override
  void initState() {
    super.initState();
    history = widget.initialHistory;
    // Forçamos a atualização para YTD no primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilter('YTD');
    });
  }

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHistory != widget.initialHistory) {
      setState(() {
        history = widget.initialHistory;
        selectedFilter = 'YTD';
        customRange = null;
      });
    }
  }

  Future<void> _selectCustomRange() async {
    final DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _MonthYearRangeDialog(initialRange: customRange),
    );

    if (picked != null) {
      setState(() {
        customRange = picked;
        selectedFilter = 'Custom';
      });
      _updateFilter('Custom');
    }
  }

  Future<void> _updateFilter(String filter) async {
    setState(() {
      selectedFilter = filter;
      isLoading = true;
    });

    try {
      String interval = 'monthly';
      Map<String, String>? range;

      final now = DateTime.now();
      final toDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      if (filter == '6M') {
        interval = 'semestrely';
        final from = now.subtract(const Duration(days: 180));
        range = {
          "from": "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}",
          "to": toDateStr
        };
      } else if (filter == '1Y') {
        interval = 'yearly';
        final from = now.subtract(const Duration(days: 365));
        range = {
          "from": "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}",
          "to": toDateStr
        };
      } else if (filter == 'YTD') {
        interval = 'ytd';
        range = {
          "from": "${now.year}-01-01",
          "to": toDateStr
        };
      } else if (filter == 'Custom' && customRange != null) {
        interval = 'monthly';
        range = {
          "from": "${customRange!.start.year}-${customRange!.start.month.toString().padLeft(2, '0')}-${customRange!.start.day.toString().padLeft(2, '0')}",
          "to": "${customRange!.end.year}-${customRange!.end.month.toString().padLeft(2, '0')}-${customRange!.end.day.toString().padLeft(2, '0')}"
        };
      }

      final result = await StartupService.getStartupPriceHistory(
        id: widget.startupId,
        historyInterval: interval,
        historyRange: range,
        historyLimit: 50,
      );

      if (mounted) {
        List<PriceHistoryItem> fetchedHistory = List<PriceHistoryItem>.from(result['history']);
        
        if (fetchedHistory.length > 50) {
          final sampled = <PriceHistoryItem>[];
          final step = (fetchedHistory.length / 50).ceil();
          for (var i = 0; i < fetchedHistory.length; i += step) {
            sampled.add(fetchedHistory[i]);
          }
          if (!sampled.contains(fetchedHistory.last)) {
            sampled.add(fetchedHistory.last);
          }
          fetchedHistory = sampled;
        }

        setState(() {
          history = fetchedHistory;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar gráfico: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Histórico de Preço',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(widget.currency,
                  style: const TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFilterButton('6M'),
              _buildFilterButton('1Y'),
              _buildFilterButton('YTD'),
              _buildCustomRangeButton(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : history.isEmpty
                    ? const Center(
                        child: Text('Histórico indisponível',
                            style: TextStyle(color: Colors.grey)))
                    : CustomPaint(
                        size: Size.infinite,
                        painter: _LineChartPainter(history: history),
                      ),
          ),
          const SizedBox(height: 10),
          if (history.isNotEmpty && !isLoading)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(history.first.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(_formatDate(history.last.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label) {
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => customRange = null);
        _updateFilter(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A84E) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRangeButton() {
    final bool isSelected = selectedFilter == 'Custom';
    return GestureDetector(
      onTap: _selectCustomRange,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A84E) : const Color(0xFFF5F5F5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return timestamp.split('T').first;
    }
  }
}

class _LineChartPainter extends CustomPainter {
  final List<PriceHistoryItem> history;
  _LineChartPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) {
      if (history.length == 1) {
        final Paint pointPaint = Paint()..color = const Color(0xFF00A84E);
        canvas.drawCircle(Offset(size.width / 2, size.height / 2), 5, pointPaint);
      }
      return;
    }

    final double minPrice = history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final double maxPrice = history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    
    final double range = maxPrice - minPrice == 0 ? 1 : (maxPrice - minPrice) * 1.2;
    final double offsetMin = minPrice - (range * 0.1);

    final double stepX = size.width / (history.length - 1);
    
    final Paint linePaint = Paint()
      ..color = const Color(0xFF00A84E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    
    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      final double y = size.height - ((history[i].price - offsetMin) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF00A84E).withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}

class _MonthYearRangeDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  const _MonthYearRangeDialog({this.initialRange});

  @override
  State<_MonthYearRangeDialog> createState() => _MonthYearRangeDialogState();
}

class _MonthYearRangeDialogState extends State<_MonthYearRangeDialog> {
  late int startMonth;
  late int startYear;
  late int endMonth;
  late int endYear;

  final List<String> months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  final List<int> years = List.generate(11, (index) => 2020 + index);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startMonth = widget.initialRange?.start.month ?? 1;
    startYear = widget.initialRange?.start.year ?? now.year - 1;
    endMonth = widget.initialRange?.end.month ?? now.month;
    endYear = widget.initialRange?.end.year ?? now.year;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar Período', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPickerRow('Início', startMonth, startYear, (m) => setState(() => startMonth = m), (y) => setState(() => startYear = y)),
          const SizedBox(height: 20),
          _buildPickerRow('Fim', endMonth, endYear, (m) => setState(() => endMonth = m), (y) => setState(() => endYear = y)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: () {
            final start = DateTime(startYear, startMonth);
            final end = DateTime(endYear, endMonth + 1, 0); // Last day of selected month
            if (start.isAfter(end)) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data inicial deve ser anterior à final')));
              return;
            }
            Navigator.pop(context, DateTimeRange(start: start, end: end));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A84E), foregroundColor: Colors.white),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _buildPickerRow(String label, int currentMonth, int currentYear, Function(int) onMonthChange, Function(int) onYearChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: currentMonth,
                isExpanded: true,
                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i], style: const TextStyle(fontSize: 14)))),
                onChanged: (v) => onMonthChange(v!),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: DropdownButton<int>(
                value: currentYear,
                isExpanded: true,
                items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString(), style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => onYearChange(v!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
