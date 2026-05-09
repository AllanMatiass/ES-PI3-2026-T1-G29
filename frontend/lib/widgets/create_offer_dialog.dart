import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/offer_service.dart';

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

class CreateOfferDialog extends StatefulWidget {
  const CreateOfferDialog({super.key});

  @override
  State<CreateOfferDialog> createState() => _CreateOfferDialogState();
}

class _CreateOfferDialogState extends State<CreateOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<WalletTokenPosition> _positions = [];
  WalletTokenPosition? _selectedPosition;
  
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final idToken = await user.getIdToken();
      final result = await UserService.getUserData(user.uid, idToken!);

      if (result['success'] == true) {
        final UserProfile profile = result['data'];
        setState(() {
          _positions = profile.wallet.positions.where((p) => p.qtdTokens > 0).toList();
          _isLoading = false;
        });
      } else {
        throw Exception(result['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar seus tokens: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedPosition == null) return;

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    if (_expiresAt.isBefore(todayEnd) || _expiresAt.isAtSameMomentAs(todayEnd)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A data de expiração deve ser pelo menos amanhã')),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final int qtd = int.parse(_qtdController.text);
      
      // Extract numeric value from currency mask
      String priceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final int priceCents = int.parse(priceText);

      if (priceCents <= 0) {
        throw Exception('O preço deve ser maior que zero');
      }

      await OfferService.createOffer(
        startupId: _selectedPosition!.startupId,
        qtdTokens: qtd,
        tokenPriceCents: priceCents,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta criada com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar oferta: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando seus tokens...'),
                ],
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Criar Nova Oferta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<WalletTokenPosition>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Startup',
                          border: OutlineInputBorder(),
                        ),
                        items: _positions.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('${p.startupName} (${p.qtdTokens} disp.)'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPosition = value;
                            _qtdController.clear();
                          });
                        },
                        validator: (value) => value == null ? 'Selecione uma startup' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _qtdController,
                        decoration: InputDecoration(
                          labelText: 'Quantidade de Tokens',
                          hintText: _selectedPosition != null ? 'Máx: ${_selectedPosition!.qtdTokens}' : null,
                          border: const OutlineInputBorder(),
                          helperText: _selectedPosition != null ? 'Você possui ${_selectedPosition!.qtdTokens} tokens' : null,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          if (_selectedPosition != null) MaxValueInputFormatter(_selectedPosition!.qtdTokens),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Informe a quantidade';
                          final int? qtd = int.tryParse(value);
                          if (qtd == null || qtd <= 0) return 'A quantidade deve ser maior que zero';
                          if (_selectedPosition != null && qtd > _selectedPosition!.qtdTokens) {
                            return 'Você possui apenas ${_selectedPosition!.qtdTokens} tokens';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Preço por Token',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Informe o preço';
                          String priceText = value.replaceAll(RegExp(r'[^0-9]'), '');
                          final int? priceCents = int.tryParse(priceText);
                          if (priceCents == null || priceCents <= 0) return 'O preço deve ser maior que zero';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
                          
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _expiresAt.isBefore(tomorrow) ? tomorrow : _expiresAt,
                            firstDate: tomorrow,
                            lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          decoration: const InputDecoration(
                            labelText: 'Expira em',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(_expiresAt)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A84E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            : const Text('Criar Oferta'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
