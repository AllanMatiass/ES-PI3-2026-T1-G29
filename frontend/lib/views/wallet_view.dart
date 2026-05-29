// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/pages/wallet/movement_history_page.dart';
import 'package:frontend/widgets/charts/portfolio_chart.dart';
import 'package:frontend/widgets/placeholders/empty_state_widget.dart';
import 'package:frontend/widgets/placeholders/error_state_widget.dart';
import '../models/user.dart';
import '../models/startup.dart';
import '../models/transaction.dart';
import '../states/user_state.dart';
import '../services/startup_service.dart';
import '../services/transaction_service.dart';
import '../widgets/cards/wallet_balance_card.dart';
import '../widgets/tiles/transaction_list_tile.dart';
import '../widgets/shimmer_placeholder.dart';
import '../models/api_response.dart';
import '../pages/wallet/transaction_history_page.dart';
import '../pages/wallet/all_assets_page.dart';
import '../widgets/charts/assets_pie_chart.dart';
import '../widgets/headers/home_header.dart';

/// Visão principal da área financeira (Carteira) do investidor.
/// Age como um dashboard consolidando saldo fiduciário (BRL), portfólio de tokens,
/// histórico de evolução patrimonial (gráfico) e as últimas transações e movimentações.
class WalletView extends StatefulWidget {
  const WalletView({super.key});

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  // Chave global usada para forçar o recarregamento interno do gráfico de evolução patrimonial
  final GlobalKey<PortfolioChartState> _chartKey = GlobalKey<PortfolioChartState>();
  
  // Dados de exibição resumida
  List<Transaction> _transactions = []; // Últimas 5 negociações de tokens
  Map<String, StartupListItem> _startupsMap = {}; // Mapa auxiliar para nome e logo das startups
  
  // Estados de controle da interface
  bool _isLoading = true;
  String? _error;
  bool _isVisible = true; // Controla a privacidade (ocultar/mostrar valores financeiros)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Centraliza o carregamento de todos os widgets e dados do dashboard da carteira.
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Dispara 4 requisições em paralelo para otimizar o tempo de tela
      final results = await Future.wait([
        UserState.refreshUser(), // Atualiza Saldo e Posições
        TransactionService.getUserTransactions(limit: 5), // Histórico recente
        StartupService.listStartups(), // Dados auxiliares (Logos/Nomes)
        _chartKey.currentState?.refresh() ?? Future.value(), // Atualiza linha do gráfico
      ]);

      final transactionResult = results[1] as ApiResponse<TransactionListResponse>;
      final startupsResult = results[2] as ApiResponse<List<StartupListItem>>;

      if (mounted) {
        setState(() {
          if (transactionResult.success && startupsResult.success) {
            _transactions = transactionResult.data!.transactions;
            // Cria um mapa para linkar o startupId das transações com o nome da empresa
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
          // Reage imediatamente a qualquer mudança no estado global (ex: um depósito que acabou de ser feito)
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
                    physics: const AlwaysScrollableScrollPhysics(), // Permite pull-to-refresh mesmo sem preencher a tela
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppHeader(
                          title: 'Carteira',
                          userData: userData,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),

                        // Bloco 1: Card de Saldo e Botões de Depósito/Saque
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

                        // Bloco 2: Gráfico interativo de rentabilidade do portfólio (FlChart)
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

                        // Bloco 3: Distribuição de Ativos (Gráfico de Pizza)
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

                        // Bloco 4: Extrato (Entradas e Saídas)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Movimentações',
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
                                        MovementHistoryPage(
                                          isVisible: _isVisible,
                                        ),
                                  ),
                                );
                              },
                              child: const Text('Ver todas'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acompanhe seus depósitos e saques',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Bloco 5: Recibo das Últimas Negociações de Tokens (Compra/Venda)
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

  /// Renderiza o gráfico de pizza (AssetsPieChart) se houverem posições abertas na carteira.
  Widget _buildInvestmentsSection(UserProfile? userData, bool isLoading) {
    if (isLoading || userData == null) {
      return const ShimmerPlaceholder(
        height: 250,
        borderRadius: 20,
      );
    }

    if (userData.wallet.positions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.pie_chart_outline,
        title: 'Sem ativos',
        message: 'Você ainda não possui tokens de startups.',
      );
    }

    return AssetsPieChart(
      positions: userData.wallet.positions,
      startupsMap: _startupsMap,
      isBalanceVisible: _isVisible,
    );
  }

  /// Renderiza a lista resumida (Top 5) de transações na base do dashboard.
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
