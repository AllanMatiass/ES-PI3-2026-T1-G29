// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/user_service.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  final String userName;
  final VoidCallback onNavigateToCatalog;

  const HomeView({
    super.key,
    required this.userName,
    required this.onNavigateToCatalog,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  UserProfile? _userData;
  Map<String, StartupListItem> _startupsMap = {};
  bool _isLoading = true;
  String? _error;
  bool _isBalanceVisible = true;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return;
    }

    try {
      final token = await user.getIdToken(true);
      
      if (token == null) {
        throw Exception("Falha ao obter token de acesso");
      }

      // Load user data and startups in parallel
      final results = await Future.wait([
        UserService.getUserData(user.uid, token),
        StartupService.listStartups(),
      ]);

      final userResult = results[0] as Map<String, dynamic>;
      final startupsList = results[1] as List<StartupListItem>;

      if (mounted) {
        setState(() {
          if (userResult['success']) {
            _userData = userResult['data'];
            _startupsMap = {for (var s in startupsList) s.id: s};
          } else {
            _error = userResult['error'];
            if (userResult['code'] == 'unauthenticated' || userResult['code'] == 'permission-denied') {
              AuthService.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erro ao carregar dados: $e";
          _isLoading = false;
        });
      }
    }
  }

  String _formatCents(double cents) {
    return _currencyFormat.format(cents / 100);
  }

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
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Saldo
                _isLoading ? _buildBalanceShimmer() : _buildBalanceCard(),
                const SizedBox(height: 32),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        Icons.account_balance_wallet,
                        'Investir',
                        onTap: widget.onNavigateToCatalog,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        Icons.swap_horiz,
                        'Transferir',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                          );
                        },
                      ),
                    ),
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

                _isLoading
                    ? _buildInvestmentsShimmer()
                    : (_error != null
                        ? _buildErrorState()
                        : (_userData?.wallet.positions.isEmpty ?? true
                            ? _buildEmptyState()
                            : _buildInvestmentsList())),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
              _userData?.name ?? widget.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          offset: const Offset(0, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) async {
            if (value == 'logout') {
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Color(0xFF1E293B), size: 20),
                  SizedBox(width: 12),
                  Text('Sair'),
                ],
              ),
            ),
          ],
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF00A84E),
            child: Text(
              getInitials(_userData?.name ?? widget.userName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A84E), Color(0xFF00873E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A84E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Total',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              IconButton(
                icon: Icon(
                  _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isBalanceVisible
                ? _formatCents(_userData?.wallet.balanceInCents ?? 0)
                : '••••••',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Total Investido: ${_formatCents(_userData?.wallet.totalInvestedCents ?? 0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildInvestmentsList() {
    return Column(
      children: _userData!.wallet.positions.map((position) {
        final startup = _startupsMap[position.startupId];
        final currentPriceCents = startup?.currentTokenPriceCents.toDouble() ?? 0.0;
        
        final currentValueCents = position.qtdTokens * currentPriceCents;
        final profitCents = currentValueCents - position.investedCents;
        final profitPercentage = position.investedCents <= 0
            ? 0.0
            : (profitCents / position.investedCents) * 100;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.startupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '${position.qtdTokens} tokens',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (profitCents >= 0 ? const Color(0xFF00A84E) : const Color(0xFFEF4444)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${profitCents >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: profitCents >= 0 ? const Color(0xFF00A84E) : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInvestmentDetail('Investido', _formatCents(position.investedCents)),
                  _buildInvestmentDetail('Valor atual', _formatCents(currentValueCents)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInvestmentDetail(
                    'Lucro',
                    '${profitCents >= 0 ? '+' : ''}${_formatCents(profitCents)}',
                    valueColor: profitCents >= 0 ? const Color(0xFF00A84E) : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvestmentDetail(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
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
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text(
            'Nenhum investimento ainda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comece a investir em startups agora mesmo!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onNavigateToCatalog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A84E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Explorar Oportunidades'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            'Ops! Algo deu errado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error ?? 'Não foi possível carregar seus dados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[700], fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadUserData,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsShimmer() {
    return Column(
      children: List.generate(3, (index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      )),
    );
  }

  Widget _buildActionButton(IconData icon, String label, {required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
        ),
      ),
    );
  }
}
