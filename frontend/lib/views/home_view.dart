// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/pages/my_offers_page.dart';
import 'package:frontend/services/user_state.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import 'package:frontend/models/api_response.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import 'package:frontend/widgets/home_header.dart';
import 'package:frontend/widgets/balance_card.dart';
import 'package:frontend/widgets/quick_action_button.dart';
import 'package:frontend/widgets/investment_card.dart';

// Visão principal da tela inicial, responsável por exibir saldo, ações rápidas e lista de investimentos.
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
  Map<String, StartupListItem> _startupsMap = {};
  bool _isLoadingStartups = true;
  String? _error;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Carrega os dados do usuário e a lista de startups em paralelo para otimizar o tempo de carregamento.
  Future<void> _loadInitialData() async {
    if (mounted) {
      setState(() {
        _isLoadingStartups = true;
        _error = null;
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return;
    }

    try {
      // Executa as chamadas de API simultaneamente utilizando Future.wait.
      final results = await Future.wait([
        UserState.refreshUser(),
        StartupService.listStartups(),
      ]);

      final startupsResult = results[1] as ApiResponse<List<StartupListItem>>;

      if (mounted) {
        setState(() {
          if (startupsResult.success) {
            _startupsMap = {for (var s in startupsResult.data!) s.id: s};
          } else {
            _error = startupsResult.message;
          }
          _isLoadingStartups = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erro ao carregar dados: $e";
          _isLoadingStartups = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserState.userNotifier,
      builder: (context, userData, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: UserState.isLoadingNotifier,
          builder: (context, isUserLoading, child) {
            final isLoading = _isLoadingStartups || (userData == null && isUserLoading);
            
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => Future.wait([
                    UserState.refreshUser(),
                    _loadInitialData(),
                  ]),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        HomeHeader(
                          userName: widget.userName,
                          userData: userData,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),

                        // Saldo
                        isLoading 
                            ? _buildBalanceShimmer() 
                            : BalanceCard(
                                userData: userData,
                                isVisible: _isBalanceVisible,
                                onToggleVisibility: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
                              ),
                        const SizedBox(height: 32),

                        // Botões
                        Row(
                          children: [
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.account_balance_wallet,
                                label: 'Investir',
                                onTap: widget.onNavigateToCatalog,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: QuickActionButton(
                                icon: Icons.swap_horiz,
                                label: 'Transferir',
                                onTap: () {
                                  FeedbackModal.show(
                                    context: context,
                                    title: 'Em breve',
                                    message: 'Funcionalidade em desenvolvimento',
                                    type: FeedbackType.info,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Investimentos
                        Text(
                          'Meus Investimentos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 24),

                        isLoading
                            ? _buildInvestmentsShimmer()
                            : (_error != null
                                ? _buildErrorState()
                                : (userData?.wallet.positions.isEmpty ?? true
                                    ? _buildEmptyState()
                                    : _buildInvestmentsList(userData!))),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Gera a lista de cards de investimento, calculando lucros e variações de mercado para cada startup.
  Widget _buildInvestmentsList(UserProfile userData) {
    return Column(
      children: userData.wallet.positions.map((position) {
        return InvestmentCard(
          position: position,
          startup: _startupsMap[position.startupId],
          isBalanceVisible: _isBalanceVisible,
        );
      }).toList(),
    );
  }

  Widget _buildBalanceShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
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

  // Exibe um estado vazio amigável quando o usuário não possui investimentos.
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'Nenhum investimento ainda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece a investir em startups agora mesmo!',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
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

  // Exibe uma mensagem de erro com opção de tentar novamente.
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          const Text(
            'Ops! Algo deu errado',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _error ?? 'Não foi possível carregar seus dados.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadInitialData,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentsShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(3, (index) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
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
}

