// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/pages/market/my_offers_page.dart';
import 'package:frontend/services/user_state.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/error_state_widget.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/widgets/shimmer_placeholder.dart';

import 'package:frontend/widgets/headers/home_header.dart';
import 'package:frontend/widgets/cards/balance_card.dart';
import 'package:frontend/widgets/quick_action_button.dart';
import 'package:frontend/widgets/cards/investment_card.dart';

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
                            ? const ShimmerPlaceholder(height: 180, borderRadius: 24)
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
                            ? Column(
                                children: List.generate(3, (index) => const ShimmerPlaceholder(
                                  height: 80, 
                                  borderRadius: 20,
                                  margin: EdgeInsets.only(bottom: 16),
                                )),
                              )
                            : (_error != null
                                ? ErrorStateWidget(errorMessage: _error, onRetry: _loadInitialData)
                                : (userData?.wallet.positions.isEmpty ?? true
                                    ? EmptyStateWidget(
                                        icon: Icons.account_balance_wallet_outlined,
                                        title: 'Nenhum investimento ainda',
                                        message: 'Comece a investir em startups agora mesmo!',
                                        buttonLabel: 'Explorar Oportunidades',
                                        onButtonPressed: widget.onNavigateToCatalog,
                                      )
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
}
