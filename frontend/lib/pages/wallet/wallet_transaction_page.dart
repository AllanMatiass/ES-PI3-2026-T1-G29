import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/user_state.dart';
import '../../models/user.dart';
import '../../constants/colors.dart';
import '../../services/wallet_service.dart';
import '../../widgets/modals/feedback_modal.dart';

enum WalletTransactionType { deposit, withdraw }

class WalletTransactionPage extends StatefulWidget {
  final WalletTransactionType type;

  const WalletTransactionPage({super.key, required this.type});

  @override
  State<WalletTransactionPage> createState() => _WalletTransactionPageState();
}

class _WalletTransactionPageState extends State<WalletTransactionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  String? _selectedMethod;
  bool _isLoading = false;

  bool get isDeposit => widget.type == WalletTransactionType.deposit;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onQuickAmountSelected(double amount) {
    setState(() {
      _amountController.text = _currencyFormat.format(amount);
      _formKey.currentState?.validate();
    });
  }

  bool _isFormValid() {
    final cleanText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amountInCents = int.tryParse(cleanText) ?? 0;

    return amountInCents >= 1000 &&
        (isDeposit ? _selectedMethod != null : true);
  }

  Future<void> _handleTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cleanText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amountInCents = int.tryParse(cleanText) ?? 0;

    final response = isDeposit
        ? await WalletService.deposit(amountInCents / 100.0)
        : await WalletService.withdraw(amountInCents / 100.0);

    if (mounted) {
      setState(() => _isLoading = false);
      final data = response.data;
      if (response.success && data != null) {
        final currentUser = UserState.user;
        if (currentUser != null) {
          // Update user state using copyWith and the new balance from API
          final updatedUser = currentUser.copyWith(
            wallet: currentUser.wallet.copyWith(
              balanceInCents: data.newBalance.toDouble(),
            ),
          );
          UserState.updateUser(updatedUser);
        }

        FeedbackModal.show(
          context: context,
          title: isDeposit ? 'Depósito Realizado' : 'Saque Realizado',
          message:
              'Sua transação de ${_currencyFormat.format(amountInCents / 100)} foi processada com sucesso.',
          type: FeedbackType.success,
          onConfirm: () => Navigator.pop(context),
        );
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro na Transação',
          message:
              response.message ??
              'Ocorreu um erro ao processar sua solicitação.',
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isDeposit ? 'Depositar Saldo' : 'Sacar Saldo'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 32,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  onChanged: () => setState(() {}),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ValueListenableBuilder<UserProfile?>(
                        valueListenable: UserState.userNotifier,
                        builder: (context, userData, _) {
                          final balance = userData?.wallet.balanceInCents ?? 0;
                          return Text(
                            'Saldo atual: ${_currencyFormat.format(balance / 100)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.grey400
                                  : AppColors.grey600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'R\$ 0,00',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.grey700
                                : AppColors.grey300,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _CurrencyInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Informe o valor';
                          final cleanText = value.replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          );
                          final amountInCents = int.tryParse(cleanText) ?? 0;
                          if (amountInCents <= 0) return 'Valor inválido';
                          if (amountInCents < 1000)
                            return 'Mínimo de R\$ 10,00';

                          if (!isDeposit) {
                            final balance =
                                UserState.user?.wallet.balanceInCents ?? 0;
                            if (amountInCents > balance)
                              return 'Saldo insuficiente';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _QuickAmountChip(
                            amount: 20,
                            onTap: () => _onQuickAmountSelected(20),
                          ),
                          _QuickAmountChip(
                            amount: 50,
                            onTap: () => _onQuickAmountSelected(50),
                          ),
                          _QuickAmountChip(
                            amount: 100,
                            onTap: () => _onQuickAmountSelected(100),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      if (isDeposit) ...[
                        Text(
                          'Selecione o método',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
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
                      ] else ...[
                        Text(
                          'O valor será enviado para sua conta bancária cadastrada.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.grey400
                                : AppColors.grey600,
                          ),
                        ),
                      ],

                      const Spacer(),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: (_isFormValid() && !_isLoading)
                            ? _handleTransaction
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: isDark
                              ? AppColors.grey800
                              : AppColors.grey200,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                            : Text(
                                isDeposit
                                    ? 'Confirmar Depósito'
                                    : 'Confirmar Saque',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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

  const _QuickAmountChip({required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      label: Text('R\$ ${amount.toInt()}'),
      onPressed: onTap,
      backgroundColor: isDark ? AppColors.grey800 : AppColors.grey100,
      labelStyle: TextStyle(
        color: isDark ? AppColors.white : AppColors.black,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isDark ? AppColors.grey700 : AppColors.grey300),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.grey700 : AppColors.grey300),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.grey400 : AppColors.grey600),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.grey400 : AppColors.grey600,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : Icon(
                Icons.circle_outlined,
                color: isDark ? AppColors.grey700 : AppColors.grey300,
              ),
        onTap: () => onTap(value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    double value = double.parse(cleanText);
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String newText = formatter.format(value / 100);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
