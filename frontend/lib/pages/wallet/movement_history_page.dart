// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/widgets/placeholders/empty_state_widget.dart';
import 'package:frontend/widgets/placeholders/error_state_widget.dart';
import '../../models/wallet_transaction.dart';
import '../../services/wallet_service.dart';
import '../../widgets/tiles/movement_list_tile.dart';
import '../../widgets/shimmer_placeholder.dart';

/// Página que exibe o histórico detalhado de movimentações financeiras (Depósitos e Saques).
/// Implementa rolagem infinita (Infinite Scroll) para otimização de performance e dados.
class MovementHistoryPage extends StatefulWidget {
  final bool isVisible; // Define se os valores monetários devem ser exibidos ou mascarados

  const MovementHistoryPage({super.key, required this.isVisible});

  @override
  State<MovementHistoryPage> createState() => _MovementHistoryPageState();
}

class _MovementHistoryPageState extends State<MovementHistoryPage> {
  // Lista acumulada de movimentações recuperadas da API
  final List<Movement> _movements = [];
  
  // Estados de controle de carregamento e erro
  bool _isLoading = true;
  String? _error;
  
  // Controle de Paginação
  String? _lastId; // ID da última movimentação carregada (usado como cursor no backend)
  bool _hasMore = true; // Indica se ainda existem dados para serem carregados
  
  // Controlador de scroll para detectar quando o usuário chega ao fim da lista
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore(); // Carregamento da primeira página
    _scrollController.addListener(_onScroll); // Monitora o scroll para paginação automática
  }

  @override
  void dispose() {
    // Libera o controlador para evitar vazamento de memória
    _scrollController.dispose();
    super.dispose();
  }

  /// Verifica se o usuário scrollou até o final da lista (com margem de 200px)
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore(); // Dispara carregamento da próxima página
    }
  }

  /// Busca o próximo lote de movimentações via WalletService
  Future<void> _loadMore() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Solicita 20 itens a partir do último ID conhecido
      final response = await WalletService.getUserMovements(
        limit: 20,
        lastMovementId: _lastId,
      );

      if (mounted) {
        setState(() {
          if (response.success) {
            final newData = response.data!.movements;
            _movements.addAll(newData);
            _lastId = response.data!.lastMovementId;
            
            // Se vieram menos de 20 itens ou o ID for nulo, a lista chegou ao fim
            _hasMore = newData.length == 20 && _lastId != null;
          } else {
            _error = response.message;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Erro ao carregar movimentações: $e";
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
        title: const Text('Movimentações'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        // Permite resetar a lista e recarregar tudo do zero (Pull to Refresh)
        onRefresh: () async {
          setState(() {
            _movements.clear();
            _lastId = null;
            _hasMore = true;
          });
          await _loadMore();
        },
        child: _movements.isEmpty && _isLoading
            ? _buildLoadingState() // Exibe Skeleton (Shimmer)
            : _error != null && _movements.isEmpty
            ? ErrorStateWidget(errorMessage: _error, onRetry: _loadMore) // Tela de erro
            : _movements.isEmpty
            ? const EmptyStateWidget( // Feedback de lista vazia
                icon: Icons.history,
                title: 'Nenhuma movimentação',
                message: 'Seus depósitos e saques aparecerão aqui.',
              )
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                itemCount: _movements.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  // Exibe indicador de progresso no final da lista se houver mais páginas
                  if (index == _movements.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  // Renderiza o item de movimentação individual
                  return MovementListTile(
                    movement: _movements[index],
                    isVisible: widget.isVisible,
                  );
                },
              ),
      ),
    );
  }

  // Constrói uma lista de placeholders animados enquanto carrega os dados iniciais
  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) =>
          const ShimmerPlaceholder(height: 70, borderRadius: 12),
    );
  }
}
