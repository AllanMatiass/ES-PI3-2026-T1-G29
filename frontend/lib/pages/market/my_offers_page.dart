// Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/services/offer_service.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/cards/my_offer_card.dart';

class MyOffersView extends StatefulWidget {
  const MyOffersView({super.key});

  @override
  State<MyOffersView> createState() => _MyOffersViewState();
}

class _MyOffersViewState extends State<MyOffersView> {
  List<Map<String, dynamic>> _myOffers = [];
  bool _isLoading = true;
  String _selectedStatus = 'ALL';

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
    final result = await OfferService.getMyOffers();
    
    if (mounted) {
      if (result.success) {
        setState(() {
          _myOffers = result.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        FeedbackModal.show(
          context: context,
          title: 'Erro ao carregar',
          message: result.message ?? 'Erro ao carregar minhas ofertas',
          type: FeedbackType.error,
        );
      }
    }
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
                            return MyOfferCard(offer: offer);
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
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
        ),
      ),
    );
  }
}
