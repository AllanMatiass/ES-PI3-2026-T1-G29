// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/states/user_state.dart';
import 'package:frontend/widgets/charts/price_chart.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:frontend/widgets/modals/confirmation_modal.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/startup.dart';
import '../../services/user_service.dart';
import '../../services/offer_service.dart';
import '../../services/startup_service.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value = double.parse(
      newValue.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String newText = formatter.format(value / 100);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class MaxValueInputFormatter extends TextInputFormatter {
  final int maxValue;

  MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}

// Página que permite ao usuário criar uma oferta de venda para seus tokens no balcão.
class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  // Chave para validação e submissão do formulário
  final _formKey = GlobalKey<FormState>();
  
  // Estados de controle de carregamento
  bool _isLoading = true; // Carregamento inicial (posições do usuário)
  bool _isSubmitting = false; // Estado durante o envio da oferta
  bool _isLoadingChart = false; // Carregamento dos dados de mercado da startup selecionada

  // Dados do usuário e da startup selecionada
  List<WalletTokenPosition> _positions = []; // Tokens que o usuário possui na carteira
  WalletTokenPosition? _selectedPosition; // Posição (startup) selecionada para venda
  StartupData? _selectedStartupData; // Dados financeiros (preço médio, gráfico) da startup selecionada

  // Controladores de entrada de dados
  final TextEditingController _qtdController = TextEditingController(); // Quantidade de tokens a vender
  final TextEditingController _priceController = TextEditingController(); // Preço pedido por cada token
  
  // Data de expiração da oferta (padrão 30 dias a partir de hoje)
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadUserTokens(); // Busca as posições da carteira do usuário ao carregar a tela
  }

  @override
  void dispose() {
    // Limpeza de recursos para evitar vazamento de memória
    _qtdController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Recupera os tokens que o usuário possui utilizando o estado global (UserState).
  // Isso garante sincronia com o cabeçalho e outras telas da aplicação.
  Future<void> _loadUserTokens() async {
    setState(() => _isLoading = true);
    
    // Sincroniza e atualiza o estado global da carteira do usuário
    await UserState.refreshUser();

    if (mounted) {
      final profile = UserState.userNotifier.value;
      if (profile != null) {
        setState(() {
          // Filtra apenas startups onde o usuário possui tokens desbloqueados disponíveis para venda
          _positions = profile.wallet.positions
              .where((p) => (p.qtdTokens - p.lockedTokens) > 0)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        FeedbackModal.show(
          context: context,
          title: 'Erro ao carregar',
          message: 'Erro ao carregar os dados da sua carteira. Tente novamente.',
          type: FeedbackType.error,
        );
        Navigator.of(context).pop();
      }
    }
  }

  /// Busca dados de mercado (histórico e resumo) para auxiliar o usuário na precificação da oferta
  Future<void> _loadStartupDetails(String startupId) async {
    setState(() => _isLoadingChart = true);
    final result = await StartupService.getStartupDetails(startupId);
    if (mounted) {
      if (result.success) {
        setState(() {
          _selectedStartupData = result.data;
          _isLoadingChart = false;
        });
      } else {
        setState(() => _isLoadingChart = false);
      }
    }
  }

  /// Valida e envia a nova oferta de venda para o sistema
  Future<void> _submit() async {
    // Validações básicas do formulário
    if (!_formKey.currentState!.validate() || _selectedPosition == null) return;

    // Garante que a oferta não expire hoje
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (_expiresAt.isBefore(todayEnd) ||
        _expiresAt.isAtSameMomentAs(todayEnd)) {
      if (mounted) {
        FeedbackModal.show(
          context: context,
          title: 'Data Inválida',
          message: 'A data de expiração deve ser pelo menos amanhã.',
          type: FeedbackType.error,
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final int qtd = int.parse(_qtdController.text);
      // Converte o texto da moeda para inteiro em centavos
      String priceText = _priceController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final int priceCents = int.parse(priceText);
      final totalCents = qtd * priceCents;

      // Solicita confirmação explícita antes de criar o compromisso de venda
      final confirmed = await ConfirmationModal.show(
        context: context,
        title: 'Confirmar Venda',
        description: 'Você está criando uma oferta para vender tokens da ${_selectedPosition!.startupName}.',
        rows: [
          ConfirmationRowData(
            label: 'Quantidade:',
            value: '$qtd tokens',
          ),
          ConfirmationRowData(
            label: 'Preço unitário:',
            value: _formatCurrency(priceCents.toDouble()),
          ),
          ConfirmationRowData(
            label: 'Total a receber:',
            value: _formatCurrency(totalCents.toDouble()),
            isTotal: true,
          ),
        ],
        note: 'Nota: Os tokens ficarão bloqueados até que a oferta seja aceita ou cancelada.',
      );

      if (confirmed != true) {
        setState(() => _isSubmitting = false);
        return;
      }

      // Efetiva a criação da oferta via API
      final result = await OfferService.createOffer(
        startupId: _selectedPosition!.startupId,
        qtdTokens: qtd,
        tokenPriceCents: priceCents,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (result.success) {
          FeedbackModal.show(
            context: context,
            title: 'Oferta Publicada!',
            message:
                'Sua oferta agora está visível para outros investidores no balcão.',
            type: FeedbackType.success,
            onConfirm: () => Navigator.of(context).pop(true),
            buttonText: 'Ótimo!',
          );
        } else {
          FeedbackModal.show(
            context: context,
            title: 'Erro na Publicação',
            message: result.message ?? 'Não foi possível publicar sua oferta',
            type: FeedbackType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        FeedbackModal.show(
          context: context,
          title: 'Erro na Publicação',
          message: 'Não foi possível publicar sua oferta: $e',
          type: FeedbackType.error,
        );
      }
    }
  }

  /// Formata um valor numérico para o padrão de moeda Real (R$)
  String _formatCurrency(double cents) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(cents / 100);
  }

  /// Botão de atalho para preencher o preço rapidamente com valores de mercado
  Widget _buildQuickPriceButton(String label, double cents) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _priceController.text = _formatCurrency(cents);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Publicar Oferta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Carregando seus tokens...'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Selecione a startup e defina os termos da sua oferta.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Dropdown para seleção da Startup (baseado no que o usuário possui na carteira)
                        DropdownButtonFormField<WalletTokenPosition>(
                          value: _selectedPosition,
                          dropdownColor: theme.colorScheme.surface,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Startup',
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(
                              Icons.business,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.dividerColor.withOpacity(0.2),
                              ),
                            ),
                          ),
                          items: _positions.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(
                                p.startupName,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPosition = value;
                              _selectedStartupData = null;
                              _qtdController.clear();
                            });
                            if (value != null) {
                              _loadStartupDetails(value.startupId);
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Selecione uma startup' : null,
                        ),
                        // Exibe informações de mercado assim que uma startup é selecionada
                        if (_selectedPosition != null) ...[
                          const SizedBox(height: 24),
                          _buildMarketSummary(),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campo de Quantidade
                            Expanded(
                              child: TextFormField(
                                controller: _qtdController,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Quantidade',
                                  labelStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  hintText: _selectedPosition != null
                                      ? '${_selectedPosition!.qtdTokens - _selectedPosition!.lockedTokens}'
                                      : '0',
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  helperText: _selectedPosition != null
                                      ? 'Saldo: ${_selectedPosition!.qtdTokens - _selectedPosition!.lockedTokens}'
                                      : null,
                                  helperStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.dividerColor.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  if (_selectedPosition != null)
                                    MaxValueInputFormatter(
                                      _selectedPosition!.qtdTokens - _selectedPosition!.lockedTokens,
                                    ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Obrigatório';
                                  final int? qtd = int.tryParse(value);
                                  if (qtd == null || qtd <= 0) return 'Mín 1';
                                  if (_selectedPosition != null &&
                                      qtd > (_selectedPosition!.qtdTokens - _selectedPosition!.lockedTokens)) {
                                    return 'Sem saldo';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Campo de Preço Unitário
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Preço/Token',
                                  labelStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  hintText: _selectedStartupData != null
                                      ? _formatCurrency(
                                          _selectedStartupData!
                                              .summary.averagePrice * 100,
                                        )
                                      : 'R\$ 0,00',
                                  hintStyle: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.dividerColor.withOpacity(
                                        0.2,
                                      ),
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  CurrencyInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Obrigatório';
                                  String priceText = value.replaceAll(
                                    RegExp(r'[^0-9]'),
                                    '',
                                  );
                                  final int? priceCents = int.tryParse(
                                    priceText,
                                  );
                                  if (priceCents == null || priceCents <= 0)
                                    return 'Mín R\$ 0,01';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        // Sugestões de preço baseadas nos dados reais de mercado
                        if (_selectedStartupData != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Spacer(),
                              _buildQuickPriceButton(
                                'Usar valor de mercado',
                                _selectedStartupData!.summary.currentPrice * 100,
                              ),
                              const SizedBox(width: 8),
                              _buildQuickPriceButton(
                                'Usar valor médio',
                                _selectedStartupData!.summary.averagePrice * 100,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Seletor de Data de Expiração
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final tomorrow = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            ).add(const Duration(days: 1));

                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _expiresAt.isBefore(tomorrow)
                                  ? tomorrow
                                  : _expiresAt,
                              firstDate: tomorrow,
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: isDark
                                      ? ThemeData.dark().copyWith(
                                          colorScheme: ColorScheme.dark(
                                            primary: AppColors.primary,
                                            onPrimary: Colors.white,
                                            surface: theme.colorScheme.surface,
                                            onSurface:
                                                theme.colorScheme.onSurface,
                                          ),
                                          dialogBackgroundColor:
                                              theme.colorScheme.surface,
                                        )
                                      : theme,
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _expiresAt = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  23,
                                  59,
                                  59,
                                );
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Expira em',
                              labelStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_expiresAt),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Botão de Submissão final
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Publicar Oferta',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,

                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Renderiza um resumo de mercado e o gráfico histórico para a startup selecionada
  Widget _buildMarketSummary() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingChart) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(
            isDark ? 0.1 : 0.2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_selectedStartupData == null) return const SizedBox.shrink();

    final summary = _selectedStartupData!.summary;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(
          isDark ? 0.05 : 0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de Mercado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(
                'Atual',
                currencyFormat.format(summary.currentPrice),
              ),
              _buildMetric(
                'Médio',
                currencyFormat.format(summary.averagePrice),
              ),
              _buildMetric(
                'Mín/Máx',
                '${summary.lowestPrice.toStringAsFixed(0)}/${summary.highestPrice.toStringAsFixed(0)}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height:
                360, // Gráfico de histórico para validar a tendência de preço
            child: PriceHistoryChart(
              startupId: _selectedPosition!.startupId,
              initialHistory: _selectedStartupData!.history,
              currency: 'BRL',
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um pequeno card de métrica financeira
  Widget _buildMetric(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
