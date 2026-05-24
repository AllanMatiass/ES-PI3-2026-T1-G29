// Autor: Gemini CLI
import 'package:flutter/material.dart';
import 'package:frontend/widgets/placeholders/empty_state_widget.dart';
import 'package:frontend/widgets/placeholders/error_state_widget.dart';
import '../../models/wallet_transaction.dart';
import '../../services/wallet_service.dart';
import '../../widgets/tiles/movement_list_tile.dart';
import '../../widgets/shimmer_placeholder.dart';

class MovementHistoryPage extends StatefulWidget {
  final bool isVisible;

  const MovementHistoryPage({super.key, required this.isVisible});

  @override
  State<MovementHistoryPage> createState() => _MovementHistoryPageState();
}

class _MovementHistoryPageState extends State<MovementHistoryPage> {
  final List<Movement> _movements = [];
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
        onRefresh: () async {
          setState(() {
            _movements.clear();
            _lastId = null;
            _hasMore = true;
          });
          await _loadMore();
        },
        child: _movements.isEmpty && _isLoading
            ? _buildLoadingState()
            : _error != null && _movements.isEmpty
                ? ErrorStateWidget(errorMessage: _error, onRetry: _loadMore)
                : _movements.isEmpty
                    ? const EmptyStateWidget(
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
                          if (index == _movements.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return MovementListTile(
                            movement: _movements[index],
                            isVisible: widget.isVisible,
                          );
                        },
                      ),
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
