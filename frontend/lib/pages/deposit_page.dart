import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  
  String? _selectedMethod;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAmountSelected(double amount) {
    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
      // Trigger validation to update button state
      _formKey.currentState?.validate();
    });
  }

  bool _isFormValid() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
    return amount >= 10.0 && _selectedMethod != null;
  }

  Future<void> _handleDeposit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulação de processamento
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação de depósito enviada!')),
      );
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Depositar Saldo'),
      centerTitle: true,
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: IntrinsicHeight( // ✨ ADICIONE ESTE WIDGET AQUI
              child: Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Saldo atual: RS 0,00',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'RS 0,00',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Informe o valor';
                        final n = double.tryParse(value.replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Valor inválido';
                        if (n < 10.0) return 'Mínimo de RS 10,00';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _QuickAmountChip(amount: 20, onTap: () => _onQuickAmountSelected(20)),
                        _QuickAmountChip(amount: 50, onTap: () => _onQuickAmountSelected(50)),
                        _QuickAmountChip(amount: 100, onTap: () => _onQuickAmountSelected(100)),
                      ],
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      'Selecione o método',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    _MethodTile(
                      title: 'Pix',
                      subtitle: 'Aprovação imediata',
                      icon: Icons.qr_code,
                      value: 'pix',
                      selectedValue: _selectedMethod,
                      onTap: (val) => setState(() => _selectedMethod = val),
                    ),
                    const SizedBox(height: 12),
                    _MethodTile(
                      title: 'Boleto',
                      subtitle: 'Compensação em até 3 dias úteis',
                      icon: Icons.receipt_long,
                      value: 'boleto',
                      selectedValue: _selectedMethod,
                      onTap: (val) => setState(() => _selectedMethod = val),
                    ),
                    
                    const Spacer(), // 💡 Agora ele vai funcionar sem quebrar!
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: (_isFormValid() && !_isLoading) ? _handleDeposit : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirmar Depósito',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
 
  
}

class _QuickAmountChip extends StatelessWidget {
  final double amount;
  final VoidCallback onTap;

  const _QuickAmountChip({
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text('R\$ ${amount.toInt()}'),
      onPressed: onTap,
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: Colors.grey[300]!),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String? selectedValue;
  final ValueChanged<String> onTap;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colorScheme.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? colorScheme.primary.withOpacity(0.05) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? colorScheme.primary : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.primary : Colors.black87,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: isSelected 
          ? Icon(Icons.check_circle, color: colorScheme.primary) 
          : const Icon(Icons.circle_outlined, color: Colors.grey),
        onTap: () => onTap(value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}