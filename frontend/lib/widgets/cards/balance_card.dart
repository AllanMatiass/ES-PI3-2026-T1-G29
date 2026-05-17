import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/widgets/animations/animated_currency.dart';
import 'package:frontend/constants/colors.dart';

class BalanceCard extends StatelessWidget {
  final UserProfile? userData;
  final bool isVisible;
  final VoidCallback onToggleVisibility;

  const BalanceCard({
    super.key,
    required this.userData,
    required this.isVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo Total',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCurrency(
            valueCents: userData?.wallet.balanceInCents ?? 0,
            isVisible: isVisible,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: AppColors.white, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Total Investido: ',
                  style: TextStyle(color: AppColors.white, fontSize: 12),
                ),
                AnimatedCurrency(
                  valueCents: userData?.wallet.totalInvestedCents ?? 0,
                  isVisible: isVisible,
                  style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
