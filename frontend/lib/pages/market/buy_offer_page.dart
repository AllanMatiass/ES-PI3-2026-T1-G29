// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/offer.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/offer_service.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/services/user_state.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:frontend/widgets/price_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../services/user_service.dart';

/// Formatador para impedir a entrada de valores superiores ao máximo permitido.
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

/// Página para confirmação e execução da compra de tokens de uma oferta específica.
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
  final TextEditingController _quantityController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _quantityController.text = _selectedTokens.toString();
    _loadInitialData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  /// Carrega os dados necessários para a página, incluindo perfil do usuário e detalhes da startup.
  Future<void> _loadInitialData() async {
    if (UserState.userNotifier.value == null) {
      await UserState.refreshUser();
    }
    await _loadStartupDetails();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Busca detalhes atualizados da startup para análise financeira.
  Future<void> _loadStartupDetails() async {
    final result = await StartupService.getStartupDetails(widget.offer.startupId);
    if (mounted) {
      if (result.success) {
        setState(() {
          _startupData = result.data;
        });
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro ao carregar',
          message: result.message ?? 'Não foi possível carregar os detalhes da startup',
          type: FeedbackType.error,
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// Processa a intenção de compra, validando saldo e chamando o serviço de aceite de oferta.
  Future<void> _handlePurchase() async {
    final userBalanceCents = UserState.userNotifier.value?.wallet.balanceInCents ?? 0.0;
    // Cálculo do custo total da transação em centavos
    final totalCents = _selectedTokens * widget.offer.tokenPriceCents;

    if (_selectedTokens <= 0) {
      FeedbackModal.show(
        context: context,
        title: 'Quantidade Inválida',
        message: 'A quantidade deve ser maior que zero',
        type: FeedbackType.info,
      );
      return;
    }

    // Verificação de saldo disponível no perfil do usuário
    if (totalCents > userBalanceCents) {
      FeedbackModal.show(
        context: context,
        title: 'Saldo Insuficiente',
        message: 'Você não possui saldo suficiente para esta compra. Seu saldo atual é ${_formatCurrency(userBalanceCents)}.',
        type: FeedbackType.error,
        buttonText: 'Entendido',
      );
      return;
    }

    setState(() => _isPurchasing = true);
    final result = await OfferService.acceptOffer(
      offerId: widget.offer.id,
      qtdTokens: _selectedTokens,
    );

    if (mounted) {
      setState(() => _isPurchasing = false);
      if (result.success) {
        // Atualiza o saldo do usuário após a compra bem-sucedida
        UserState.refreshUser();

        FeedbackModal.show(
          context: context,
          title: 'Compra Realizada!',
          message: 'Você adquiriu $_selectedTokens tokens da ${widget.offer.startupName}.',
          type: FeedbackType.success,
          onConfirm: () => Navigator.of(context).pop(true),
          buttonText: 'Ir para Ofertas',
        );
        return;
      }

      FeedbackModal.show(
        context: context,
        title: 'Erro na Compra',
        message: result.message ?? 'Não foi possível completar sua compra',
        type: FeedbackType.error,
      );
      }  }

  /// Formata valores monetários de centavos para Real (BRL).
  String _formatCurrency(num cents) {
    return _currencyFormat.format(cents / 100);
  }

  @override
  Widget build(BuildContext context) {
    final totalCents = _selectedTokens * widget.offer.tokenPriceCents;
    final theme = Theme.of(context);

    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserState.userNotifier,
      builder: (context, userData, child) {
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
                      _buildBottomButton(totalCents, userData),
                    ],
                  ),
                ),
        );
      }
    );
  }

  /// Cabeçalho com informações básicas da startup.
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

  /// Seção de análise financeira que compara o preço da oferta com o de mercado.
  Widget _buildFinancialAnalysis() {
    final theme = Theme.of(context);
    final marketPrice = _startupData?.currentTokenPriceCents ?? 0;
    final offerPrice = widget.offer.tokenPriceCents;
    
    // Cálculo do percentual de desconto/oportunidade em relação ao preço de mercado
    // Fórmula: ((Mercado - Oferta) / Mercado) * 100
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

  /// Gráfico de histórico de preços da startup.
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
            startupId: widget.offer.startupId,
            initialHistory: _startupData?.history ?? [],
            currency: 'BRL',
          ),
        ),
      ],
    );
  }

  /// Seletor de quantidade de tokens para compra.
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
                      MaxValueInputFormatter(widget.offer.qtdTokens),
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
                  if (_selectedTokens < widget.offer.qtdTokens) {
                    setState(() {
                      _selectedTokens++;
                      _quantityController.text = _selectedTokens.toString();
                    });
                  }
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

  /// Rodapé com exibição do saldo do usuário, total da compra e botão de ação.
  Widget _buildBottomButton(int totalCents, UserProfile? userData) {
    final theme = Theme.of(context);
    final userBalanceCents = userData?.wallet.balanceInCents ?? 0.0;
    final isInsufficient = totalCents > userBalanceCents;

    return Column(
      children: [
        if (userData != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seu Saldo Disponível',
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  _formatCurrency(userBalanceCents),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isInsufficient ? const Color(0xFFEF4444) : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total a pagar',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              _formatCurrency(totalCents),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isInsufficient ? const Color(0xFFEF4444) : const Color(0xFF00A84E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isPurchasing || isInsufficient) ? null : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInsufficient ? theme.disabledColor : const Color(0xFF00A84E),
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
                : Text(
                    isInsufficient ? 'Saldo Insuficiente' : 'Confirmar Compra',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  /// Exibição de tela de carregamento enquanto os dados iniciais são buscados.
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
