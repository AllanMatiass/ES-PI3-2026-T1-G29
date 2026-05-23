// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/widgets/charts/portfolio_chart.dart';
import 'package:frontend/widgets/states/empty_state_widget.dart';
import 'package:frontend/widgets/states/error_state_widget.dart';
import '../models/user.dart';
import '../models/startup.dart';
import '../models/transaction.dart';
import '../services/user_state.dart';
import '../services/startup_service.dart';
import '../services/transaction_service.dart';
import '../widgets/cards/wallet_balance_card.dart';
import '../widgets/tiles/transaction_list_tile.dart';
import '../widgets/cards/investment_card.dart';
import '../widgets/shimmer_placeholder.dart';
import '../models/api_response.dart';
import '../pages/wallet/transaction_history_page.dart';
import '../pages/wallet/all_assets_page.dart';

import '../widgets/headers/home_header.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  final GlobalKey<PortfolioChartState> _chartKey =
      GlobalKey<PortfolioChartState>();
  List<Transaction> _transactions = [];
  Map<String, StartupListItem> _startupsMap = {};
  bool _isLoading = true;
  String? _error;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        UserState.refreshUser(),
        TransactionService.getUserTransactions(limit: 5),
        StartupService.listStartups(),
        _chartKey.currentState?.refresh() ?? Future.value(),
      ]);

      final transactionResult =
          results[1] as ApiResponse<TransactionListResponse>;
      final startupsResult = results[2] as ApiResponse<List<StartupListItem>>;

      if (mounted) {
        setState(() {
          if (transactionResult.success && startupsResult.success) {
            _transactions = transactionResult.data!.transactions;
            _startupsMap = {for (var s in startupsResult.data!) s.id: s};
          } else {
            _error = transactionResult.message ?? startupsResult.message;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ValueListenableBuilder<UserProfile?>(
            valueListenable: UserState.userNotifier,
            builder: (context, userData, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: UserState.isLoadingNotifier,
                builder: (context, isUserLoading, _) {
                  final isInitialLoading =
                      _isLoading || (userData == null && isUserLoading);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppHeader(
                          title: 'Carteira',
                          userData: userData,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),

                        // Saldo
                        isInitialLoading
                            ? const ShimmerPlaceholder(
                                height: 180,
                                borderRadius: 24,
                              )
                            : WalletBalanceCard(
                                balanceCents:
                                    userData?.wallet.balanceInCents ?? 0,
                                totalInvestedCents:
                                    userData?.wallet.totalInvestedCents ?? 0,
                                isVisible: _isVisible,
                                onToggleVisibility: () =>
                                    setState(() => _isVisible = !_isVisible),
                              ),
                        const SizedBox(height: 32),

                        // Gráfico
                        Text(
                          'Valorização do Patrimônio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PortfolioChart(key: _chartKey),
                        const SizedBox(height: 32),

                        // Investimentos (Ativos)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Meus Ativos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AllAssetsPage(isVisible: _isVisible),
                                  ),
                                );
                              },
                              child: const Text('Ver todos'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInvestmentsSection(userData, isInitialLoading),
                        const SizedBox(height: 32),

                        // Transações
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Últimas Transações',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransactionHistoryPage(
                                          isVisible: _isVisible,
                                        ),
                                  ),
                                );
                              },
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                        _buildTransactionsSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentsSection(UserProfile? userData, bool isLoading) {
    if (isLoading || userData == null) {
      return Column(
        children: List.generate(
          2,
          (_) => const ShimmerPlaceholder(
            height: 160,
            borderRadius: 20,
            margin: EdgeInsets.only(bottom: 12),
          ),
        ),
      );
    }

    if (userData.wallet.positions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.pie_chart_outline,
        title: 'Sem ativos',
        message: 'Você ainda não possui tokens de startups.',
      );
    }

    final positions = userData.wallet.positions.take(2).toList();

    return Column(
      children: positions
          .map(
            (p) => InvestmentCard(
              position: p,
              startup: _startupsMap[p.startupId],
              isBalanceVisible: _isVisible,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTransactionsSection() {
    if (_isLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => const ShimmerPlaceholder(
            height: 70,
            borderRadius: 12,
            margin: EdgeInsets.only(bottom: 12),
          ),
        ),
      );
    }

    if (_error != null) {
      return ErrorStateWidget(errorMessage: _error, onRetry: _loadData);
    }

    if (_transactions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'Sem transações',
        message: 'Suas atividades aparecerão aqui.',
      );
    }

    return Column(
      children: _transactions
          .map(
            (t) => TransactionListTile(transaction: t, isVisible: _isVisible),
          )
          .toList(),
    );
  }
}
