// lib/features/dashboard/widgets/hero_metric_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

/// Card principal — "Faturamento do Período" com valor grande e em negrito.
class HeroMetricCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const HeroMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.attach_money_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(value),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}
