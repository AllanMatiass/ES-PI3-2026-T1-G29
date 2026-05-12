import 'package:flutter/material.dart';
import 'package:frontend/models/offer.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/offer_service.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import 'package:frontend/widgets/price_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class BuyOfferPage extends StatefulWidget {
  final OfferWithId offer;

  const BuyOfferPage({super.key, required this.offer});

  @override
  State<BuyOfferPage> createState() => _BuyOfferPageState();
}

class _BuyOfferPageState extends State<BuyOfferPage> {
  StartupData? _startupData;
  bool _isLoading = true;
  int _selectedTokens = 1;
  bool _isPurchasing = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _loadStartupDetails();
  }

  Future<void> _loadStartupDetails() async {
    try {
      final data = await StartupService.getStartupDetails(widget.offer.startupId);
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
    setState(() => _isPurchasing = true);
    try {
      await OfferService.acceptOffer(
        offerId: widget.offer.id,
        qtdTokens: _selectedTokens,
      );

      if (mounted) {
        FeedbackModal.show(
          context: context,
          title: 'Compra Realizada!',
          message: 'Você adquiriu $_selectedTokens tokens da ${widget.offer.startupName}.',
          type: FeedbackType.success,
          onConfirm: () => Navigator.of(context).pop(true),
          buttonText: 'Ir para Ofertas',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackModal.show(
          context: context,
          title: 'Erro na Compra',
          message: 'Não foi possível completar sua compra: $e',
          type: FeedbackType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  // Remove the old _showSuccessDialog method entirely


  String _formatCurrency(num cents) {
    return _currencyFormat.format(cents / 100);
  }

  @override
  Widget build(BuildContext context) {
    final totalCents = _selectedTokens * widget.offer.tokenPriceCents;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Confirmar Compra',
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
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          backgroundImage: _startupData?.logoUrl.isNotEmpty == true
              ? NetworkImage(_startupData!.logoUrl)
              : null,
          child: _startupData?.logoUrl.isEmpty == true
              ? Icon(Icons.business, color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.offer.startupName,
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
    final marketPrice = _startupData?.currentTokenPriceCents ?? 0;
    final offerPrice = widget.offer.tokenPriceCents;
    final discount = marketPrice > 0 ? ((marketPrice - offerPrice) / marketPrice * 100) : 0.0;

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
            'Análise Financeira',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          _buildAnalysisRow(
            'Preço de Mercado',
            _formatCurrency(marketPrice),
            Icons.account_balance_outlined,
          ),
          const SizedBox(height: 12),
          _buildAnalysisRow(
            'Preço nesta Oferta',
            _formatCurrency(offerPrice),
            Icons.local_offer_outlined,
            valueColor: offerPrice <= marketPrice ? const Color(0xFF00A84E) : const Color(0xFFEF4444),
          ),
          Divider(height: 32, color: theme.dividerColor.withOpacity(0.1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Oportunidade', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              Text(
                discount > 0 ? '${discount.toStringAsFixed(1)}% abaixo do mercado' : 'Preço de mercado',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: discount > 0 ? const Color(0xFF00A84E) : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
          height: 350, // Increased height to accommodate the internal controls of PriceHistoryChart
          child: PriceHistoryChart(
            startupId: widget.offer.startupId,
            initialHistory: _startupData?.history ?? [],
            currency: 'BRL',
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseSelector() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantidade desejada',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildCounterButton(Icons.remove, () {
                  if (_selectedTokens > 1) setState(() => _selectedTokens--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '$_selectedTokens',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                ),
                _buildCounterButton(Icons.add, () {
                  if (_selectedTokens < widget.offer.qtdTokens) setState(() => _selectedTokens++);
                }),
              ],
            ),
            Text(
              'Disponível: ${widget.offer.qtdTokens}',
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
              'Total a pagar',
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
                    'Confirmar Compra',
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
            'Carregando dados da ${widget.offer.startupName}...',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
