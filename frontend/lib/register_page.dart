import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9AA3AE)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
    Widget _buildFormLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        required ? '$label *' : label,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF556179),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).maybePop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preencha seus dados para começar',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF59627A),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Nome completo', required: true),
                        TextFormField(
                          controller: _nameController,
                          decoration: _buildInputDecoration('João Silva'),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe seu nome completo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildFormLabel('CPF', required: true),
                        TextFormField(
                          controller: _cpfController,
                          decoration: _buildInputDecoration('000.000.000-00'),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe seu CPF';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildFormLabel('Telefone'),
                        TextFormField(
                          controller: _phoneController,
                          decoration: _buildInputDecoration('(00) 00000-0000'),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 18),
                        _buildFormLabel('Email', required: true),
                        TextFormField(
                          controller: _emailController,
                          decoration: _buildInputDecoration('seu@email.com'),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe seu email';
                            }
                            if (!RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}").hasMatch(value)) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildFormLabel('Senha', required: true),
                        TextFormField(
                          controller: _passwordController,
                          decoration: _buildInputDecoration('Mínimo 8 caracteres').copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF6B7280),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.length < 8) {
                              return 'A senha deve ter pelo menos 8 caracteres';
                            }
                            return null;
                          },
                        ),
