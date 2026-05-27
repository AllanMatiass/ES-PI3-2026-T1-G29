// Autor: Allan Giovanni Matias Paes - 25008211

/// Classe utilitária para validação de campos de formulário.
class Validators {
  /// Valida se o e-mail possui um formato básico correto usando Regex.
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

  /// Valida o CPF seguindo o algoritmo oficial de dígitos verificadores.
  /// Explicação do cálculo:
  /// 1. Limpa a string mantendo apenas números.
  /// 2. Verifica se tem 11 dígitos e não é uma sequência repetida (ex: 111.111.111-11).
  /// 3. Cálculo do 1º dígito: Soma ponderada dos 9 primeiros dígitos (pesos de 10 a 2). 
  ///    O dígito é o resto de (soma * 10) / 11.
  /// 4. Cálculo do 2º dígito: Soma ponderada dos 10 primeiros dígitos (pesos de 11 a 2).
  ///    O dígito é o resto de (soma * 10) / 11.
  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    // Remove caracteres não numéricos
    final cpf = value.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11) {
      return 'CPF inválido';
    }

    // CPF inválido se todos os dígitos forem iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    List<int> digits = cpf.split('').map(int.parse).toList();

    // Validação do Primeiro Dígito Verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += digits[i] * (10 - i); // Pesos decrescentes de 10 a 2
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (firstDigit != digits[9]) return 'CPF inválido';

    // Validação do Segundo Dígito Verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += digits[i] * (11 - i); // Pesos decrescentes de 11 a 2
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    if (secondDigit != digits[10]) return 'CPF inválido';

    return null; // CPF válido
  }

  /// Valida se o telefone tem entre 10 e 11 dígitos numéricos.
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
