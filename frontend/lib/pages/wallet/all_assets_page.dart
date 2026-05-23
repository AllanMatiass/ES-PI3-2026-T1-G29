// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/widgets/states/empty_state_widget.dart';
import 'package:frontend/widgets/states/error_state_widget.dart';
import '../../models/api_response.dart';
import '../../models/user.dart';
import '../../models/startup.dart';
import '../../services/user_state.dart';
import '../../services/startup_service.dart';
import '../../widgets/cards/investment_card.dart';
import '../../widgets/shimmer_placeholder.dart';

class AllAssetsPage extends StatefulWidget {
  final bool isVisible;

  const AllAssetsPage({super.key, required this.isVisible});

  @override
  State<AllAssetsPage> createState() => _AllAssetsPageState();
}

class _AllAssetsPageState extends State<AllAssetsPage> {
  Map<String, StartupListItem> _startupsMap = {};
  bool _isLoading = true;
  String? _error;

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
        StartupService.listStartups(),
      ]);

      final startupsResponse = results[1] as ApiResponse<List<StartupListItem>>;

      if (mounted) {
        setState(() {
          if (startupsResponse.success) {
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

  Widget _buildBody() {
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserState.userNotifier,
      builder: (context, userData, _) {
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

        if (_error != null) {
          return ErrorStateWidget(errorMessage: _error, onRetry: _loadData);
        }

        final investments = userData.wallet.positions;

        if (investments.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.pie_chart_outline,
            title: 'Sem ativos',
            message: 'Você ainda não possui tokens de startups.',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: investments.length,
            itemBuilder: (context, index) {
              final investment = investments[index];
              return InvestmentCard(
                position: investment,
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
