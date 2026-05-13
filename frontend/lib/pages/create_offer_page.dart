import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/startup.dart';
import '../services/user_service.dart';
import '../services/offer_service.dart';
import '../services/startup_service.dart';
import '../widgets/price_chart.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value = double.parse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String newText = formatter.format(value / 100);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}

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

class CreateOfferPage extends StatefulWidget {
  const CreateOfferPage({super.key});

  @override
  State<CreateOfferPage> createState() => _CreateOfferPageState();
}

class _CreateOfferPageState extends State<CreateOfferPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<WalletTokenPosition> _positions = [];
  WalletTokenPosition? _selectedPosition;
  StartupData? _selectedStartupData;
  bool _isLoadingChart = false;
  
  final TextEditingController _qtdController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _loadUserTokens();
  }

  @override
  void dispose() {
    _qtdController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTokens() async {
    setState(() => _isLoading = true);
    final result = await UserService.getUserData();

    if (mounted) {
      if (result.success) {
        final UserProfile profile = result.data!;
        setState(() {
          _positions = profile.wallet.positions.where((p) => p.qtdTokens > 0).toList();
          _isLoading = false;
        });
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro ao carregar',
          message: result.message ?? 'Erro ao carregar seus tokens',
          type: FeedbackType.error,
        );
        Navigator.of(context).pop();
      }
    }
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedPosition == null) return;

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    if (_expiresAt.isBefore(todayEnd) || _expiresAt.isAtSameMomentAs(todayEnd)) {
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
      String priceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final int priceCents = int.parse(priceText);

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
            message: 'Sua oferta agora está visível para outros investidores no catálogo.',
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

  // Remove the old _showSuccessDialog method entirely


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Publicar Oferta',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
                  CircularProgressIndicator(color: Color(0xFF00A84E)),
                  SizedBox(height: 16),
                  Text('Carregando seus tokens...'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Selecione a startup e defina os termos da sua oferta.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        DropdownButtonFormField<WalletTokenPosition>(
                          value: _selectedPosition,
                          dropdownColor: theme.colorScheme.surface,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Startup',
                            labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: Icon(Icons.business, color: theme.colorScheme.onSurfaceVariant),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                            ),
                          ),
                          items: _positions.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.startupName, style: TextStyle(color: theme.colorScheme.onSurface)),
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
                          validator: (value) => value == null ? 'Selecione uma startup' : null,
                        ),
                        if (_selectedPosition != null) ...[
                          const SizedBox(height: 24),
                          _buildMarketSummary(),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _qtdController,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Quantidade',
                                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  helperText: _selectedPosition != null ? 'Saldo: ${_selectedPosition!.qtdTokens - _selectedPosition!.lockedTokens }' : null,
                                  helperStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  if (_selectedPosition != null) MaxValueInputFormatter(_selectedPosition!.qtdTokens),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Obrigatório';
                                  final int? qtd = int.tryParse(value);
                                  if (qtd == null || qtd <= 0) return 'Mín 1';
                                  if (_selectedPosition != null && qtd > _selectedPosition!.qtdTokens) {
                                    return 'Sem saldo';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                style: TextStyle(color: theme.colorScheme.onSurface),
                                decoration: InputDecoration(
                                  labelText: 'Preço/Token',
                                  labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  CurrencyInputFormatter(),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Obrigatório';
                                  String priceText = value.replaceAll(RegExp(r'[^0-9]'), '');
                                  final int? priceCents = int.tryParse(priceText);
                                  if (priceCents == null || priceCents <= 0) return 'Mín R\$ 0,01';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        InkWell(
                          onTap: () async {
                            final now = DateTime.now();
                            final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
                            
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _expiresAt.isBefore(tomorrow) ? tomorrow : _expiresAt,
                              firstDate: tomorrow,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: isDark ? ThemeData.dark().copyWith(
                                    colorScheme: ColorScheme.dark(
                                      primary: const Color(0xFF00A84E),
                                      onPrimary: Colors.white,
                                      surface: theme.colorScheme.surface,
                                      onSurface: theme.colorScheme.onSurface,
                                    ),
                                    dialogBackgroundColor: theme.colorScheme.surface,
                                  ) : theme,
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Expira em',
                              labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.onSurfaceVariant),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                              ),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_expiresAt),
                              style: TextStyle(color: theme.colorScheme.onSurface),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A84E),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Publicar Oferta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildMarketSummary() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoadingChart) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.1 : 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A84E))),
      );
    }

    if (_selectedStartupData == null) return const SizedBox.shrink();

    final summary = _selectedStartupData!.summary;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(isDark ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(isDark ? 0.2 : 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo de Mercado',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Atual', currencyFormat.format(summary.currentPrice)),
              _buildMetric('Médio', currencyFormat.format(summary.averagePrice)),
              _buildMetric('Mín/Máx', '${summary.lowestPrice.toStringAsFixed(0)}/${summary.highestPrice.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 360, // Increased height to avoid overflow and show more details
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

  Widget _buildMetric(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
      ],
    );
  }
}


