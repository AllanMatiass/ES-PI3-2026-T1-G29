// Autor: Allan Giovanni Matias Paes

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mail é obrigatório';
    }
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    // Remove non-numeric characters
    final cpf = value.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) {
      return 'CPF inválido';
    }

    // CPF algorithm validation
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    List<int> digits = cpf.split('').map(int.parse).toList();

    // First digit
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (firstDigit != digits[9]) return 'CPF inválido';

    // Second digit
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    if (secondDigit != digits[10]) return 'CPF inválido';

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    final phone = value.replaceAll(RegExp(r'\D'), '');
    if (phone.length < 10 || phone.length > 11) {
      return 'Telefone inválido';
    }
    return null;
  }
}
