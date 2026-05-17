import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarketFilters extends StatelessWidget {
  final String searchStartup;
  final TextEditingController priceController;
  final Function(String) onSearchChanged;
  final Function(String) onMaxPriceChanged;

  const MarketFilters({
    super.key,
    required this.searchStartup,
    required this.priceController,
    required this.onSearchChanged,
    required this.onMaxPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: onSearchChanged,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Startup...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00A84E)),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.colorScheme.onSurface),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
              ],
              onChanged: onMaxPriceChanged,
              decoration: InputDecoration(
                hintText: 'Máx R\$',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
