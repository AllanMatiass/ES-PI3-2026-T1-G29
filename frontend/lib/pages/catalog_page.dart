// Autor: Allan Giovanni Matias Paes e Pedro Vinicius Romanato
import 'package:flutter/material.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/models/startup.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/pages/startup_details.dart';

import 'package:intl/intl.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late Future<List<StartupListItem>> _startupsFuture;
  String _searchQuery = "";
  StartupStage? _selectedStage;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  final NumberFormat _decimalFormat = NumberFormat.decimalPattern('pt_BR');

  @override
  void initState() {
    super.initState();
    _loadStartups();
  }

  void _loadStartups() {
    setState(() {
      _startupsFuture = StartupService.listStartups();
    });
  }

  Future<void> _handleRefresh() async {
    _loadStartups();
    await _startupsFuture;
  }

  String _formatCurrency(int cents) {
    return _currencyFormat.format(cents / 100);
  }

  String _formatNumber(int number) {
    return _decimalFormat.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Investir',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar startups...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00A84E)),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildFilterChip(null, 'Todas'),
                const SizedBox(width: 8),
                _buildFilterChip(StartupStage.nova, 'Novas'),
                const SizedBox(width: 8),
                _buildFilterChip(StartupStage.em_operacao, 'Em Operação'),
                const SizedBox(width: 8),
                _buildFilterChip(StartupStage.em_expansao, 'Em Expansão'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: FutureBuilder<List<StartupListItem>>(
                future: _startupsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonLoading();
                  } else if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(child: Text('Nenhuma startup encontrada.', style: TextStyle(color: theme.colorScheme.onSurface))),
                        ),
                      ],
                    );
                  }

                  var startups = snapshot.data!;

                  if (_searchQuery.isNotEmpty) {
                    startups = startups
                        .where((s) =>
                            s.name.toLowerCase().contains(_searchQuery) ||
                            s.shortDescription.toLowerCase().contains(_searchQuery))
                        .toList();
                  }
                  if (_selectedStage != null) {
                    startups = startups.where((s) => s.stage == _selectedStage).toList();
                  }

                  if (startups.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(child: Text('Nenhuma startup corresponde aos filtros.', style: TextStyle(color: theme.colorScheme.onSurface))),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    itemCount: startups.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final startup = startups[index];
                      return _buildStartupCard(startup);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(StartupStage? stage, String label) {
    final theme = Theme.of(context);
    bool isSelected = _selectedStage == stage;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStage = selected ? stage : null;
        });
      },
      selectedColor: const Color(0xFF00A84E).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF00A84E) : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      side: BorderSide(
        color: isSelected ? const Color(0xFF00A84E) : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildStartupCard(StartupListItem startup) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Image and Basic Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: startup.coverImageUrl != null
                      ? Image.network(
                          startup.coverImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildLogoPlaceholder(80),
                        )
                      : _buildLogoPlaceholder(80),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              startup.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: theme.colorScheme.onSurface),
                            ),
                          ),
                          if (startup.priceVariation != null)
                            _buildVariationBadge(startup.priceVariation!),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStageColor(startup.stage).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          startup.stage.toDisplayString(),
                          style: TextStyle(
                            color: _getStageColor(startup.stage),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${startup.id}',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              startup.shortDescription,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.5),
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),

          // Financial and Token Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                    'Capital Levantado',
                    _formatCurrency(startup.capitalRaisedCents),
                    Icons.account_balance),
                const SizedBox(height: 12),
                _buildInfoRow(
                    'Total de Tokens',
                    _formatNumber(startup.totalTokensIssued),
                    Icons.token_outlined),
                const SizedBox(height: 12),
                _buildInfoRow(
                    'Preço Atual do Token',
                    _formatCurrency(startup.currentTokenPriceCents),
                    Icons.monetization_on_outlined),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StartupDetailsPage(startupId: startup.id),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00A84E),
                      side: const BorderSide(color: Color(0xFF00A84E)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ver detalhes',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A84E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Investir',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Tags
          if (startup.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: startup.tags.map((tag) => _buildTag(tag)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF00A84E)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildVariationBadge(double variation) {
    bool isPositive = variation >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPositive
            ? const Color(0xFF00A84E).withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: isPositive ? const Color(0xFF00A84E) : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${isPositive ? '+' : ''}${variation.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? const Color(0xFF00A84E) : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        tag,
        style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildLogoPlaceholder(double size) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: const Icon(Icons.business, color: Color(0xFF00A84E), size: 32),
    );
  }

  Widget _buildSkeletonLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 250,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }
  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Erro ao carregar startups: $error', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStartups,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStageColor(StartupStage stage) {
    switch (stage) {
      case StartupStage.nova:
        return Colors.blue;
      case StartupStage.em_operacao:
        return Colors.green;
      case StartupStage.em_expansao:
        return Colors.orange;
    }
  }
}
