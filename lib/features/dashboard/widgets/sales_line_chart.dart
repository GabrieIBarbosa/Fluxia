// lib/features/dashboard/widgets/sales_line_chart.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Gráfico de linha — vendas por dia (estilo clean, sem grade excessiva).
class SalesLineChart extends StatelessWidget {
  final Map<String, double> vendasPorDia;

  const SalesLineChart({super.key, required this.vendasPorDia});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = vendasPorDia.entries.toList();

    if (entries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Sem dados para o gráfico.')),
      );
    }

    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].value));
      labels.add(entries[i].key);
    }

    final maxY =
        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

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
          Text(
            'Vendas por Dia',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.divider.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        // Mostra apenas alguns labels para não aglomerar
                        if (entries.length > 7 && idx % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: entries.length <= 15,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.25),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          'R\$ ${spot.y.toStringAsFixed(2)}',
                          const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
