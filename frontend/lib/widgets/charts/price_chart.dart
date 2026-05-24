// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';

/// Widget que exibe um gráfico de histórico de preços de uma startup.
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
  String customInterval = 'monthly';
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    history = widget.initialHistory;
    // Carrega o filtro inicial YTD (Year To Date)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFilter('YTD');
    });
  }

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza o histórico se as propriedades do widget mudarem
    if (oldWidget.initialHistory != widget.initialHistory) {
      setState(() {
        history = widget.initialHistory;
        selectedFilter = 'YTD';
        customRange = null;
        selectedIndex = null;
      });
    }
  }

  /// Exibe diálogo para seleção de intervalo personalizado de datas.
  Future<void> _selectCustomRange() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MonthYearRangeDialog(
        initialRange: customRange,
        initialInterval: customInterval,
      ),
    );

    if (result != null) {
      setState(() {
        customRange = result['range'];
        customInterval = result['interval'];
        selectedFilter = 'Custom';
        selectedIndex = null;
      });
      _updateFilter('Custom');
    }
  }

  /// Atualiza os dados do gráfico com base no filtro selecionado (1D, Semestre, 1 ano, YTD, Custom).
  /// Realiza cálculos de datas para definir o intervalo da busca na API.
  Future<void> _updateFilter(String filter) async {
    setState(() {
      selectedFilter = filter;
      isLoading = true;
      selectedIndex = null;
    });

    try {
      String interval = 'monthly';
      Map<String, String>? range;
      int? limit;

      final now = DateTime.now();
      final toDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Define o intervalo de tempo retroativo com base no filtro
      if (filter == '1D') {
        interval = 'daily';
        final from = now.subtract(const Duration(days: 1));
        range = {
          "from": "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}",
          "to": toDateStr
        };
      } else if (filter == 'Semestre') {
        interval = 'monthly';
        final from = DateTime(now.year, now.month - 6, now.day);
        range = {
          "from": "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}",
          "to": toDateStr
        };
        limit = 6;
      } else if (filter == '1 ano') {
        interval = 'monthly';
        final from = DateTime(now.year - 1, now.month, now.day);
        range = {
          "from": "${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}",
          "to": toDateStr
        };
        limit = 12;
      } else if (filter == 'YTD') {
        interval = 'ytd';
      } else if (filter == 'Custom' && customRange != null) {
        interval = customInterval;
        range = {
          "from": "${customRange!.start.year}-${customRange!.start.month.toString().padLeft(2, '0')}-${customRange!.start.day.toString().padLeft(2, '0')}",
          "to": "${customRange!.end.year}-${customRange!.end.month.toString().padLeft(2, '0')}-${customRange!.end.day.toString().padLeft(2, '0')}"
        };
      }

      // Busca os dados históricos no serviço
      final result = await StartupService.getStartupPriceHistory(
        id: widget.startupId,
        historyInterval: interval,
        historyRange: range,
        historyLimit: filter != 'Custom' ? limit : null,
      );

      if (mounted) {
        if (result.success) {
          setState(() {
            history = List<PriceHistoryItem>.from(result.data!['history']);
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          FeedbackModal.show(
            context: context,
            title: 'Erro ao carregar',
            message: result.message ?? 'Erro ao atualizar gráfico',
            type: FeedbackType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        FeedbackModal.show(
          context: context,
          title: 'Erro',
          message: 'Erro ao atualizar gráfico: $e',
          type: FeedbackType.error,
        );
      }
    }
  }

  /// Identifica qual ponto do gráfico foi tocado com base na posição X do toque.
  void _handleTap(Offset localPosition, Size size) {
    if (history.length < 2) return;
    
    // Divide a largura total pela quantidade de intervalos entre os pontos
    final double stepX = size.width / (history.length - 1);
    // Calcula o índice arredondando a posição X pelo tamanho do passo
    final int index = (localPosition.dx / stepX).round().clamp(0, history.length - 1);
    
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.1)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Histórico de Preço',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.colorScheme.onSurface
                        )),
                    // Exibe o preço do ponto selecionado pelo usuário
                    if (selectedIndex != null)
                      Text(
                        '${_formatDate(history[selectedIndex!].timestamp)}: ${widget.currency} ${history[selectedIndex!].price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00A84E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              Text(widget.currency,
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Botões de filtro
          AbsorbPointer(
            absorbing: isLoading,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('1D'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Semestre'),
                  const SizedBox(width: 8),
                  _buildFilterButton('1 ano'),
                  const SizedBox(width: 8),
                  _buildFilterButton('YTD'),
                  const SizedBox(width: 8),
                  _buildCustomRangeButton(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Área do gráfico
          SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AbsorbPointer(
                  absorbing: isLoading,
                  child: GestureDetector(
                    onPanUpdate: (details) => _handleTap(details.localPosition, constraints.biggest),
                    onTapDown: (details) => _handleTap(details.localPosition, constraints.biggest),
                    child: SizedBox(
                      width: double.infinity,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A84E)))
                          : history.isEmpty
                              ? Center(
                                  child: Text('Histórico indisponível',
                                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant)))
                              : CustomPaint(
                                  size: Size.infinite,
                                  painter: _LineChartPainter(
                                    history: history,
                                    lineColor: const Color(0xFF00A84E),
                                    selectedIndex: selectedIndex,
                                    isDark: isDark,
                                  ),
                                ),
                    ),
                  ),
                );
              }
            ),
          ),
          const SizedBox(height: 10),
          // Exibe a primeira e última data do intervalo no eixo X
          if (history.isNotEmpty && !isLoading)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(history.first.timestamp),
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                Text(_formatDate(history.last.timestamp),
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
              ],
            )
        ],
      ),
    );
  }

  /// Constrói botão de filtro padrão.
  Widget _buildFilterButton(String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => customRange = null);
        _updateFilter(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00A84E) 
              : (isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.2) : theme.colorScheme.surfaceVariant.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  /// Botão para acionar o calendário e escolher datas customizadas.
  Widget _buildCustomRangeButton() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isSelected = selectedFilter == 'Custom';
    return GestureDetector(
      onTap: _selectCustomRange,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF00A84E) 
              : (isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.2) : theme.colorScheme.surfaceVariant.withOpacity(0.3)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Formata a data ISO para o padrão brasileiro DD/MM/AAAA.
  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return timestamp.split('T').first;
    }
  }
}

/// Painter responsável por desenhar a linha do gráfico e o preenchimento gradiente.
class _LineChartPainter extends CustomPainter {
  final List<PriceHistoryItem> history;
  final Color lineColor;
  final int? selectedIndex;
  final bool isDark;

  _LineChartPainter({
    required this.history,
    required this.lineColor,
    this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) {
      if (history.length == 1) {
        final Paint pointPaint = Paint()..color = lineColor;
        canvas.drawCircle(Offset(size.width / 2, size.height / 2), 5, pointPaint);
      }
      return;
    }

    // Identifica os valores mínimo e máximo para escalar o gráfico verticalmente
    final double minPrice = history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final double maxPrice = history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    
    // Cálculo de margem: adiciona 20% de respiro no topo e base para o gráfico não encostar nas bordas
    final double range = maxPrice - minPrice == 0 ? 1 : (maxPrice - minPrice) * 1.2;
    final double offsetMin = minPrice - (range * 0.1);

    // Distância horizontal entre cada ponto
    final double stepX = size.width / (history.length - 1);
    
    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    
    // Mapeamento de coordenadas: transforma valores de preço em coordenadas Y da tela
    for (int i = 0; i < history.length; i++) {
      final double x = i * stepX;
      // Inverte o Y (0 é o topo da tela) e aplica a proporção do preço dentro do range calculado
      final double y = size.height - ((history[i].price - offsetMin) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Desenha o preenchimento gradiente abaixo da linha
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

    // Desenha o indicador visual (linha vertical e ponto) quando o usuário interage
    if (selectedIndex != null && selectedIndex! < history.length) {
      final double x = selectedIndex! * stepX;
      final double y = size.height - ((history[selectedIndex!].price - offsetMin) / range * size.height);

      final Paint selectionPaint = Paint()
        ..color = isDark ? Colors.white70 : Colors.black45
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Linha vertical de guia
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), selectionPaint);

      // Círculos concêntricos para destacar o ponto selecionado
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = isDark ? Colors.black : Colors.white);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.selectedIndex != selectedIndex || oldDelegate.isDark != isDark;
  }
}

/// Diálogo para seleção de mês/ano e periodicidade do gráfico.
class _MonthYearRangeDialog extends StatefulWidget {
  final DateTimeRange? initialRange;
  final String initialInterval;
  const _MonthYearRangeDialog({this.initialRange, required this.initialInterval});

  @override
  State<_MonthYearRangeDialog> createState() => _MonthYearRangeDialogState();
}

class _MonthYearRangeDialogState extends State<_MonthYearRangeDialog> {
  late int startMonth;
  late int startYear;
  late int endMonth;
  late int endYear;
  late String selectedInterval;

  final List<String> months = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  final List<int> years = List.generate(11, (index) => 2020 + index);

  final List<Map<String, String>> intervals = [
    {'label': 'Diário', 'value': 'daily'},
    {'label': 'Mensal', 'value': 'monthly'},
    {'label': 'Semestral', 'value': 'semestrely'},
    {'label': 'Anual', 'value': 'yearly'},
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startMonth = widget.initialRange?.start.month ?? 1;
    startYear = widget.initialRange?.start.year ?? now.year - 1;
    endMonth = widget.initialRange?.end.month ?? now.month;
    endYear = widget.initialRange?.end.year ?? now.year;
    selectedInterval = widget.initialInterval;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      title: Text('Selecionar Período', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIntervalPicker(),
            const SizedBox(height: 20),
            _buildPickerRow('Início', startMonth, startYear, (m) => setState(() => startMonth = m), (y) => setState(() => startYear = y)),
            const SizedBox(height: 20),
            _buildPickerRow('Fim', endMonth, endYear, (m) => setState(() => endMonth = m), (y) => setState(() => endYear = y)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar', style: TextStyle(color: theme.colorScheme.onSurfaceVariant))),
        ElevatedButton(
          onPressed: () {
            final start = DateTime(startYear, startMonth);
            final end = DateTime(endYear, endMonth + 1, 0);
            if (start.isAfter(end)) {
              FeedbackModal.show(
                context: context,
                title: 'Data Inválida',
                message: 'Data inicial deve ser anterior à final',
                type: FeedbackType.info,
              );
              return;
            }
            Navigator.pop(context, {
              'range': DateTimeRange(start: start, end: end),
              'interval': selectedInterval,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A84E), foregroundColor: Colors.white),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  /// Dropdown para escolher a granularidade dos dados (mensal, semestral, anual).
  Widget _buildIntervalPicker() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Intervalo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: selectedInterval,
          isExpanded: true,
          dropdownColor: theme.colorScheme.surface,
          style: TextStyle(color: theme.colorScheme.onSurface),
          items: intervals.map((i) => DropdownMenuItem(value: i['value'], child: Text(i['label']!, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (v) => setState(() => selectedInterval = v!),
        ),
      ],
    );
  }

  /// Constrói linha com seletores de mês e ano.
  Widget _buildPickerRow(String label, int currentMonth, int currentYear, Function(int) onMonthChange, Function(int) onYearChange) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: currentMonth,
                isExpanded: true,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurface),
                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(months[i], style: const TextStyle(fontSize: 14)))),
                onChanged: (v) => onMonthChange(v!),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: DropdownButton<int>(
                value: currentYear,
                isExpanded: true,
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurface),
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
