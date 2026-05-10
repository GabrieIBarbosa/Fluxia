// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/screens/chat_screen.dart';
import '../providers/csv_data_provider.dart';
import '../widgets/hero_metric_card.dart';
import '../widgets/mini_kpi_card.dart';
import '../widgets/sales_line_chart.dart';
import '../widgets/top_products_card.dart';
import 'home_upload_screen.dart';

/// Dashboard principal — exibe métricas e gráficos após processar o CSV.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final csvState = ref.watch(csvDataProvider);
    final data = csvState.data;
    final theme = Theme.of(context);

    if (data == null) {
      // Safety fallback — nunca deveria chegar aqui sem dados
      return const HomeUploadScreen();
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.dashboardTitle,
            style: theme.appBarTheme.titleTextStyle),
        leading: const SizedBox.shrink(),
        actions: [
          // Botão nova importação
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            tooltip: AppStrings.newImportButton,
            onPressed: () {
              ref.read(csvDataProvider.notifier).reset();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeUploadScreen()),
              );
            },
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () {
              ref.read(csvDataProvider.notifier).reset();
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Hero Metric: Faturamento Total ──
            HeroMetricCard(
              label: AppStrings.heroMetricLabel,
              value: data.faturamentoTotal,
            ),
            const SizedBox(height: 8),

            // ── KPIs secundários ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  MiniKpiCard(
                    label: AppStrings.totalOrdersLabel,
                    value: '${data.totalPedidos}',
                    icon: Icons.receipt_long_rounded,
                  ),
                  MiniKpiCard(
                    label: AppStrings.avgTicketLabel,
                    value: currencyFormat.format(data.ticketMedio),
                    icon: Icons.confirmation_number_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Gráfico de Linha: Vendas por Dia ──
            SalesLineChart(vendasPorDia: data.vendasPorDia),
            const SizedBox(height: 8),

            // ── Top 5 Produtos ──
            TopProductsCard(top5: data.top5Produtos),
            const SizedBox(height: 16),
          ],
        ),
      ),

      // ── FAB para abrir o Chat com IA ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          );
        },
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text('Consultor IA'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
    );
  }
}
