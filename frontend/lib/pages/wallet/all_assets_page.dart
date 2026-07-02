// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/widgets/placeholders/empty_state_widget.dart';
import 'package:frontend/widgets/placeholders/error_state_widget.dart';
import '../../models/api_response.dart';
import '../../models/user.dart';
import '../../models/startup.dart';
import '../../states/user_state.dart';
import '../../services/startup_service.dart';
import '../../widgets/cards/investment_card.dart';
import '../../widgets/shimmer_placeholder.dart';

/// Página que exibe a listagem completa de todos os tokens (ativos) que o usuário possui.
/// Cruza dados da carteira do usuário com informações de mercado (preços, logos) das startups.
class AllAssetsPage extends StatefulWidget {
  final bool
  isVisible; // Define se os valores financeiros devem ser exibidos ou ocultos (olho)

  const AllAssetsPage({super.key, required this.isVisible});

  @override
  State<AllAssetsPage> createState() => _AllAssetsPageState();
}

class _AllAssetsPageState extends State<AllAssetsPage> {
  // Mapa para acesso rápido aos detalhes das startups (Key: ID da Startup)
  Map<String, StartupListItem> _startupsMap = {};

  // Estados de controle da interface
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData(); // Carrega dados do usuário e mercado simultaneamente
  }

  /// Realiza o carregamento paralelo dos dados necessários para montar a tela de ativos
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Dispara as duas requisições em paralelo para otimizar a performance
      final results = await Future.wait([
        UserState.refreshUser(), // Atualiza posições e saldo do usuário
        StartupService.listStartups(), // Busca lista de startups para obter nomes/logos
      ]);

      final startupsResponse = results[1] as ApiResponse<List<StartupListItem>>;

      if (mounted) {
        setState(() {
          if (startupsResponse.success) {
            // Converte a lista em mapa para lookup durante a renderização da lista
            _startupsMap = {for (var s in startupsResponse.data!) s.id: s};
          } else {
            _error =
                startupsResponse.message ?? "Erro ao carregar dados do mercado";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erro inesperado: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Meus Ativos'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _buildBody(),
    );
  }

  /// Constrói o corpo da página reagindo a mudanças no estado global do usuário
  Widget _buildBody() {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserState.userNotifier,
      builder: (context, userData, _) {
        // Estado de Carregamento: Exibe placeholders animados (Shimmers)
        if (_isLoading || userData == null) {
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 5,
            itemBuilder: (_, __) => const ShimmerPlaceholder(
              height: 160,
              borderRadius: 20,
              margin: EdgeInsets.only(bottom: 16),
            ),
          );
        }

        // Estado de Erro: Exibe widget de erro com opção de re-tentativa
        if (_error != null) {
          return ErrorStateWidget(errorMessage: _error, onRetry: _loadData);
        }

        final investments = userData.wallet.positions;

        // Estado de Lista Vazia: Informa ao usuário que ele não possui investimentos
        if (investments.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.pie_chart_outline,
            title: 'Sem ativos',
            message: 'Você ainda não possui tokens de startups.',
          );
        }

        // Lista de Ativos: Renderiza cada posição do usuário usando o InvestmentCard
        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: investments.length,
            itemBuilder: (context, index) {
              final investment = investments[index];
              return InvestmentCard(
                position: investment,
                // Passa os detalhes da startup (nome/logo) recuperados do mapa
                startup: _startupsMap[investment.startupId],
                isBalanceVisible: widget.isVisible,
              );
            },
          ),
        );
      },
    );
  }
}
