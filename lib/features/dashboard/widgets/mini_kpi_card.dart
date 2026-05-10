// lib/features/dashboard/widgets/mini_kpi_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Card compacto para KPIs secundários (Total de Pedidos, Ticket Médio).
class MiniKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const MiniKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
