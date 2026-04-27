// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/services/auth.dart';

class HomeView extends StatelessWidget {
  final String userName;
  const HomeView({super.key, required this.userName});

  String getInitials(String name) {
    List<String> names = name.trim().split(" ");
    String initials = "";
    if (names.isNotEmpty) {
      if (names[0].isNotEmpty) initials += names[0][0];
      if (names.length > 1 && names[names.length - 1].isNotEmpty) {
        initials += names[names.length - 1][0];
      }
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Olá,',
                        style: TextStyle(fontSize: 16, color: Color(0xFF59627A)),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF00A84E),
                    child: Text(
                      getInitials(userName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Saldo (placeholder)
              _buildEmptyCard('Saldo Total'),
              const SizedBox(height: 32),

              // Botões
              Row(
                children: [
                  Expanded(child: _buildActionButton(Icons.account_balance_wallet, 'Investir')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildActionButton(Icons.swap_horiz, 'Transferir')),
                ],
              ),
              const SizedBox(height: 32),

              // Investimentos
              const Text(
                'Meus Investimentos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),

              _buildEmptyState(),

              const SizedBox(height: 32),

              Center(
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF1E293B)),
                  onPressed: () async {
                    await AuthService.signOut();
                    if (context.mounted) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Em breve',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: const [
          Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Nenhum investimento ainda',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            'Funcionalidade em desenvolvimento',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00A84E), size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}