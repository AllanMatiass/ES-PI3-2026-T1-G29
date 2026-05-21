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
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/widgets/shimmer_placeholder.dart';

import 'package:frontend/widgets/headers/home_header.dart';
import 'package:frontend/widgets/cards/balance_card.dart';
import 'package:frontend/widgets/quick_action_button.dart';
import 'package:frontend/widgets/cards/startup_card.dart';

// Visão principal da tela inicial, responsável por exibir saldo, ações rápidas e lista de startups em destaque.
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
  List<StartupListItem> _featuredStartups = [];
  bool _isLoadingStartups = true;
  String? _error;
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Carrega os dados do usuário e a lista de startups em destaque.
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
            // Ordenamos as startups pela maior variação de preço e pegamos as 3 primeiras
            final sortedStartups = List<StartupListItem>.from(startupsResult.data!)
              ..sort((a, b) => (b.priceVariation ?? 0).compareTo(a.priceVariation ?? 0));
            
            _featuredStartups = sortedStartups.take(3).toList();
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
                        AppHeader(
                          title: 'Início',
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
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Startups em Destaque
                        Text(
                          'Oportunidades em Destaque',
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
                                  height: 180, 
                                  borderRadius: 20,
                                  margin: EdgeInsets.only(bottom: 16),
                                )),
                              )
                            : (_error != null
                                ? ErrorStateWidget(errorMessage: _error, onRetry: _loadInitialData)
                                : (_featuredStartups.isEmpty
                                    ? EmptyStateWidget(
                                        icon: Icons.business_center_outlined,
                                        title: 'Nenhuma oportunidade agora',
                                        message: 'Fique atento às próximas rodadas de investimento!',
                                      )
                                    : _buildFeaturedStartups())),
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

  // Gera a lista de cards de startups em destaque.
  Widget _buildFeaturedStartups() {
    return Column(
      children: _featuredStartups.map((startup) {
        return StartupCard(
          startup: startup,
        );
      }).toList(),
    );
  }
}
