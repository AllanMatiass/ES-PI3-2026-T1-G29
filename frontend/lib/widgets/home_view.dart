// Autor: Allan Giovanni Matias Paes
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/pages/my_offers_page.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import 'package:frontend/models/api_response.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import 'package:frontend/services/user_state.dart';
import 'package:frontend/widgets/animated_currency.dart';
import 'package:frontend/widgets/animated_counter.dart';

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

  // Extrai as iniciais do primeiro e último nome para compor o avatar circular.
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
                        _buildHeader(isDark, userData),
                        const SizedBox(height: 32),

                        // Saldo
                        isLoading ? _buildBalanceShimmer() : _buildBalanceCard(userData),
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

  // Constrói o widget de cabeçalho com saudação e controles de tema/menu.
  Widget _buildHeader(bool isDark, UserProfile? userData) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá,',
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
            ),
            Text(
              userData?.name ?? widget.userName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
              },
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              offset: const Offset(0, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (value) async {
                if (value == 'offers') {
                  if (mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const MyOffersView()),
                    );
                  }
                } else if (value == 'logout') {
                  await AuthService.signOut();
                  if (mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'offers',
                  child: Row(
                    children: [
                      Icon(Icons.local_offer_outlined, color: theme.colorScheme.onSurface, size: 20),
                      const SizedBox(width: 12),
                      const Text('Minhas Ofertas'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: theme.colorScheme.onSurface, size: 20),
                      const SizedBox(width: 12),
                      const Text('Sair'),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF00A84E),
                child: Text(
                  getInitials(userData?.name ?? widget.userName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Constrói o card principal que exibe o saldo do usuário com opção de ocultar valores.
  Widget _buildBalanceCard(UserProfile? userData) {
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
          AnimatedCurrency(
            valueCents: userData?.wallet.balanceInCents ?? 0,
            isVisible: _isBalanceVisible,
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
                const Text(
                  'Total Investido: ',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                AnimatedCurrency(
                  valueCents: userData?.wallet.totalInvestedCents ?? 0,
                  isVisible: _isBalanceVisible,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
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

  // Gera a lista de cards de investimento, calculando lucros e variações de mercado para cada startup.
  Widget _buildInvestmentsList(UserProfile userData) {
    final theme = Theme.of(context);
    return Column(
      children: userData.wallet.positions.map((position) {
        final startup = _startupsMap[position.startupId];
        final currentPriceCents = startup?.currentTokenPriceCents.toDouble() ?? 0.0;
        
        // O cálculo do valor atual multiplica a quantidade de tokens pelo preço de mercado.
        final currentValueCents = position.qtdTokens * currentPriceCents;
        // O lucro em centavos é a diferença entre o valor atual e o valor total investido.
        final profitCents = currentValueCents - position.investedCents;
        // A porcentagem de lucro é calculada dividindo o lucro pelo investimento inicial.
        final profitPercentage = position.investedCents <= 0
            ? 0.0
            : (profitCents / position.investedCents) * 100;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
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
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.business, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          position.startupName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        AnimatedCounter(
                          value: position.qtdTokens,
                          suffix: 'tokens',
                          isVisible: _isBalanceVisible,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (profitCents >= 0 || !_isBalanceVisible ? const Color(0xFF00A84E) : const Color(0xFFEF4444)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isBalanceVisible 
                          ? '${profitCents >= 0 ? '+' : ''}${profitPercentage.toStringAsFixed(0)}%'
                          : '••%',
                      style: TextStyle(
                        color: profitCents >= 0 || !_isBalanceVisible ? const Color(0xFF00A84E) : const Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInvestmentDetailAnimated('Investido', position.investedCents),
                  _buildInvestmentDetailAnimated('Valor atual', currentValueCents),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInvestmentDetailAnimated(
                    'Lucro',
                    profitCents,
                    valueColor: profitCents >= 0 || !_isBalanceVisible ? const Color(0xFF00A84E) : const Color(0xFFEF4444),
                    showSign: true,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Constrói uma linha de detalhe do investimento com animação de valor monetário.
  Widget _buildInvestmentDetailAnimated(String label, double valueCents, {Color? valueColor, bool showSign = false}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 4),
        AnimatedCurrency(
          valueCents: valueCents,
          isVisible: _isBalanceVisible,
          prefix: showSign && valueCents >= 0 ? '+R\$' : 'R\$',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
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

  Widget _buildInvestmentsShimmerFixed() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(3, (index) => Shimmer.fromColors(
        baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      )),
    );
  }

  // Constrói um botão de ação rápida (Investir, Transferir, etc).
  Widget _buildActionButton(IconData icon, String label, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF00A84E), size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
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
