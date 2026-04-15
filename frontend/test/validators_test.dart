import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/validators.dart';

void main() {
  group('Validators Test', () {
    test('Email validator should return error message for invalid email', () {
      expect(Validators.validateEmail('invalid-email'), 'E-mail inválido');
      expect(Validators.validateEmail(''), 'E-mail é obrigatório');
    });

    test('Email validator should return null for valid email', () {
      expect(Validators.validateEmail('test@test.com'), null);
    });

    test('CPF validator should return error message for invalid CPF', () {
      expect(Validators.validateCPF('123'), 'CPF inválido');
      expect(Validators.validateCPF(''), 'CPF é obrigatório');
      expect(Validators.validateCPF('111.111.111-11'), 'CPF inválido');
    });

    test('CPF validator should return null for valid CPF', () {
      // Using a known valid CPF for testing purposes
      expect(Validators.validateCPF('881.973.540-73'), null);
    });

    test('Phone validator should return error message for invalid phone', () {
      expect(Validators.validatePhone('123'), 'Telefone inválido');
      expect(Validators.validatePhone(''), 'Telefone é obrigatório');
    });

    test('Phone validator should return null for valid phone', () {
      expect(Validators.validatePhone('11930541768'), null);
      expect(Validators.validatePhone('(11) 93054-1768'), null);
    });
  });
}
