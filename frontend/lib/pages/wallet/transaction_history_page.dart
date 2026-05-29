// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:flutter/material.dart';
import 'package:frontend/widgets/placeholders/empty_state_widget.dart';
import 'package:frontend/widgets/placeholders/error_state_widget.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../widgets/tiles/transaction_list_tile.dart';
import '../../widgets/shimmer_placeholder.dart';

/// Página que exibe o histórico detalhado de negociações de tokens (Compra e Venda).
/// Abrange transações tanto do mercado primário (startup) quanto balcão.
class TransactionHistoryPage extends StatefulWidget {
  final bool isVisible; // Define se os valores financeiros devem ser exibidos ou mascarados

  const TransactionHistoryPage({super.key, required this.isVisible});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  // Lista acumulada de transações recuperadas via API
  final List<Transaction> _transactions = [];
  
  // Estados de controle de carregamento e erro
  bool _isLoading = true;
  String? _error;
  
  // Controle de Paginação
  String? _lastId; // ID da última transação (cursor para busca sequencial no backend)
  bool _hasMore = true; // Indica se existem mais transações a serem carregadas
  
  // Controlador para monitorar o fim da lista e disparar o carregamento da próxima página
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore(); // Busca o primeiro lote de dados
    _scrollController.addListener(_onScroll); // Ativa o listener de rolagem infinita
  }

  @override
  void dispose() {
    // Libera recursos para evitar memory leak
    _scrollController.dispose();
    super.dispose();
  }

  /// Verifica a posição do scroll para decidir se deve carregar mais itens
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  /// Recupera o próximo lote de 20 transações via TransactionService
  Future<void> _loadMore() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await TransactionService.getUserTransactions(
        limit: 20,
        lastTransactionId: _lastId,
      );

      if (mounted) {
        setState(() {
          if (response.success) {
            final newData = response.data!.transactions;
            _transactions.addAll(newData);
            _lastId = response.data!.lastTransactionId;
            
            // Determina se a lista chegou ao fim baseado na quantidade de retorno
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
          _error = e.toString();
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
        title: const Text('Histórico de Transações'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _transactions.isEmpty && _isLoading
          ? _buildLoadingState() // Exibe Skeleton (Shimmer) inicial
          : _error != null && _transactions.isEmpty
          ? ErrorStateWidget(errorMessage: _error, onRetry: _loadMore) // Feedback de erro
          : _transactions.isEmpty
          ? const EmptyStateWidget( // Feedback para carteira sem movimentações de tokens
              icon: Icons.history,
              title: 'Nenhuma transação',
              message: 'Suas transações aparecerão aqui.',
            )
          : ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _transactions.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                // Renderiza spinner de carregamento no final se houver mais páginas pendentes
                if (index == _transactions.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                // Exibe o card detalhado da transação
                return TransactionListTile(
                  transaction: _transactions[index],
                  isVisible: widget.isVisible,
                );
              },
            ),
    );
  }

  /// Constrói a lista de shimmers enquanto carrega os dados iniciais
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
