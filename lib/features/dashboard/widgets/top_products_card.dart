// lib/features/dashboard/widgets/top_products_card.dart

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Lista dos Top 5 produtos mais vendidos.
class TopProductsCard extends StatelessWidget {
  final List<MapEntry<String, int>> top5;

  const TopProductsCard({super.key, required this.top5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (top5.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxQty = top5.first.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
          Text('Top 5 Produtos Mais Vendidos',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          ...top5.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final progress = maxQty > 0 ? product.value / maxQty : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Posição
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: index == 0
                          ? AppColors.primary
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: index == 0
                              ? AppColors.white
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nome do produto + barra
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.key,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.divider,
                            color: AppColors.primary.withOpacity(
                              1.0 - (index * 0.15),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Quantidade
                  Text(
                    '${product.value}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
