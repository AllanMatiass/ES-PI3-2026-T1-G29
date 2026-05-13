import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import 'package:frontend/widgets/price_chart.dart';
import 'package:intl/intl.dart';

class MaxValueInputFormatter extends TextInputFormatter {
  final int maxValue;

  MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}

class BuyFromStartupPage extends StatefulWidget {
  final String startupId;
  final String startupName;
  final int tokenPriceCents;
  final String? logoUrl;

  const BuyFromStartupPage({
    super.key,
    required this.startupId,
    required this.startupName,
    required this.tokenPriceCents,
    this.logoUrl,
  });

  @override
  State<BuyFromStartupPage> createState() => _BuyFromStartupPageState();
}

class _BuyFromStartupPageState extends State<BuyFromStartupPage> {
  StartupData? _startupData;
  bool _isLoading = true;
  int _selectedTokens = 1;
  bool _isPurchasing = false;
  final TextEditingController _quantityController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _quantityController.text = _selectedTokens.toString();
    _loadStartupDetails();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadStartupDetails() async {
    try {
      final data = await StartupService.getStartupDetails(widget.startupId);
      setState(() {
        _startupData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar detalhes: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedTokens <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A quantidade deve ser maior que zero')),
      );
      return;
    }

    setState(() => _isPurchasing = true);
    try {
      await StartupService.buyTokensFromStartup(
        startupId: widget.startupId,
        qtdTokens: _selectedTokens,
      );

      if (mounted) {
        FeedbackModal.show(
          context: context,
          title: 'Investimento Realizado!',
          message: 'Você adquiriu $_selectedTokens tokens da ${widget.startupName}.',
          type: FeedbackType.success,
          onConfirm: () => Navigator.of(context).pop(true),
          buttonText: 'Voltar para o Portfólio',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackModal.show(
          context: context,
          title: 'Erro no Investimento',
          message: 'Não foi possível completar seu investimento: $e',
          type: FeedbackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  String _formatCurrency(num cents) {
    return _currencyFormat.format(cents / 100);
  }

  @override
  Widget build(BuildContext context) {
    final totalCents = _selectedTokens * widget.tokenPriceCents;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Confirmar Investimento',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStartupInfo(),
                  const SizedBox(height: 24),
                  _buildFinancialAnalysis(),
                  const SizedBox(height: 24),
                  _buildPriceChart(),
                  const SizedBox(height: 24),
                  _buildPurchaseSelector(),
                  const SizedBox(height: 32),
                  _buildBottomButton(totalCents),
                ],
              ),
            ),
    );
  }

  Widget _buildStartupInfo() {
    final theme = Theme.of(context);
    final logoUrl = _startupData?.logoUrl ?? widget.logoUrl;
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          backgroundImage: logoUrl != null && logoUrl.isNotEmpty
              ? NetworkImage(logoUrl)
              : null,
          child: (logoUrl == null || logoUrl.isEmpty)
              ? Icon(Icons.business, color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.startupName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                _startupData?.segment ?? 'Setor não informado',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialAnalysis() {
    final theme = Theme.of(context);
    final marketPrice = _startupData?.currentTokenPriceCents ?? widget.tokenPriceCents;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações de Investimento',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          _buildAnalysisRow(
            'Preço por Token',
            _formatCurrency(marketPrice),
            Icons.account_balance_outlined,
          ),
          const SizedBox(height: 12),
          _buildAnalysisRow(
            'Valuation Atual',
            _formatCurrency(_startupData?.valuation ?? 0),
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value, IconData icon, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChart() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de Preços',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 350,
          child: PriceHistoryChart(
            startupId: widget.startupId,
            initialHistory: _startupData?.history ?? [],
            currency: 'BRL',
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseSelector() {
    final theme = Theme.of(context);
    // Para startups, vamos assumir um limite alto se não soubermos o disponível exato
    final int availableTokens = (_startupData != null) 
        ? (_startupData!.totalTokens - _startupData!.circulatingTokens) 
        : 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantidade de tokens',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildCounterButton(Icons.remove, () {
                  if (_selectedTokens > 1) {
                    setState(() {
                      _selectedTokens--;
                      _quantityController.text = _selectedTokens.toString();
                    });
                  }
                }),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00A84E), width: 2),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      MaxValueInputFormatter(availableTokens > 0 ? availableTokens : 1000000),
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        final val = int.tryParse(value) ?? 1;
                        setState(() {
                          _selectedTokens = val;
                        });
                      } else {
                        setState(() {
                          _selectedTokens = 0;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _buildCounterButton(Icons.add, () {
                  if (_selectedTokens < availableTokens || availableTokens <= 0) {
                    setState(() {
                      _selectedTokens++;
                      _quantityController.text = _selectedTokens.toString();
                    });
                  }
                }),
              ],
            ),
            if (availableTokens > 0)
              Text(
                'Disponível: $availableTokens',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF00A84E)),
      ),
    );
  }

  Widget _buildBottomButton(int totalCents) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total do Investimento',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              _formatCurrency(totalCents),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A84E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPurchasing ? null : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A84E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isPurchasing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Confirmar Investimento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00A84E)),
          const SizedBox(height: 16),
          Text(
            'Carregando dados da ${widget.startupName}...',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
