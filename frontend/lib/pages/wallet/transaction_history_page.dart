// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/widgets/states/empty_state_widget.dart';
import 'package:frontend/widgets/states/error_state_widget.dart';
import '../../models/transaction.dart';
import '../../services/transaction_service.dart';
import '../../widgets/tiles/transaction_list_tile.dart';
import '../../widgets/shimmer_placeholder.dart';

class TransactionHistoryPage extends StatefulWidget {
  final bool isVisible;

  const TransactionHistoryPage({super.key, required this.isVisible});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String? _lastId;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

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
          ? _buildLoadingState()
          : _error != null && _transactions.isEmpty
          ? ErrorStateWidget(errorMessage: _error, onRetry: _loadMore)
          : _transactions.isEmpty
          ? const EmptyStateWidget(
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
                if (index == _transactions.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return TransactionListTile(
                  transaction: _transactions[index],
                  isVisible: widget.isVisible,
                );
              },
            ),
    );
  }

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
