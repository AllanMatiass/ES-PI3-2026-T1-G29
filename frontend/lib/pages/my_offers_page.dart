import 'package:flutter/material.dart';
import 'package:frontend/services/offer_service.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class MyOffersView extends StatefulWidget {
  const MyOffersView({super.key});

  @override
  State<MyOffersView> createState() => _MyOffersViewState();
}

class _MyOffersViewState extends State<MyOffersView> {
  List<Map<String, dynamic>> _myOffers = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  void initState() {
    super.initState();
    _loadMyOffers();
  }

  List<Map<String, dynamic>> get _filteredOffers {
    if (_selectedStatus == 'ALL') return _myOffers;
    return _myOffers.where((offer) => (offer['status'] ?? 'OPEN').toString().toUpperCase() == _selectedStatus).toList();
  }

  Future<void> _loadMyOffers() async {
    setState(() => _isLoading = true);
    try {
      final offers = await OfferService.getMyOffers();
      setState(() {
        _myOffers = offers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar minhas ofertas: $e')),
        );
      }
    }
  }

  String _formatCurrency(int cents) {
    return _currencyFormat.format(cents / 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Minhas Ofertas',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMyOffers,
              child: _isLoading
                  ? _buildSkeletonLoading()
                  : _filteredOffers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredOffers.length,
                          itemBuilder: (context, index) {
                            final offer = _filteredOffers[index];
                            return _buildMyOfferCard(offer);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final theme = Theme.of(context);
    final statuses = [
      {'value': 'ALL', 'label': 'Todos'},
      {'value': 'OPEN', 'label': 'Abertas'},
      {'value': 'ACCEPTED', 'label': 'Finalizadas'},
      {'value': 'CANCELLED', 'label': 'Canceladas'},
      {'value': 'EXPIRED', 'label': 'Expiradas'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = status['value']!;
                });
              },
              selectedColor: const Color(0xFF00A84E).withOpacity(0.2),
              checkmarkColor: const Color(0xFF00A84E),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF00A84E) : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00A84E) : theme.dividerColor.withOpacity(0.1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyOfferCard(Map<String, dynamic> offer) {
    final theme = Theme.of(context);
    final status = offer['status'] ?? 'OPEN';
    final remaining = offer['remainingQtdTokens'] ?? 0;
    final initial = offer['initialQtdTokens'] ?? 0;
    final sold = offer['soldQtdTokens'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                offer['startupName'] ?? 'Startup',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(Icons.token_outlined, '$remaining / $initial', label: 'tokens rest.'),
              _buildInfoItem(Icons.monetization_on_outlined, _formatCurrency(offer['tokenPriceCents'] ?? 0), label: 'cada'),
            ],
          ),
          Divider(height: 24, color: theme.dividerColor.withOpacity(0.1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Ganho',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  Text(
                    _formatCurrency(offer['totalEarnedCents'] ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF00A84E),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Vendidos',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                  Text(
                    '$sold tokens',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, {String? label}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (label != null)
              Text(
                label,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String text = status;

    switch (status.toUpperCase()) {
      case 'OPEN':
        color = Colors.green;
        text = 'Aberta';
        break;
      case 'ACCEPTED':
        color = Colors.blue;
        text = 'Finalizada';
        break;
      case 'CANCELLED':
        color = Colors.red;
        text = 'Cancelada';
        break;
      case 'EXPIRED':
        color = Colors.orange;
        text = 'Expirada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final hasAnyOffers = _myOffers.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasAnyOffers ? Icons.search_off : Icons.local_offer_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasAnyOffers
                ? 'Nenhuma oferta encontrada para este status'
                : 'Você ainda não criou nenhuma oferta',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
