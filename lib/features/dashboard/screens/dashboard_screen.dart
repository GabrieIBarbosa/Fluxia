// lib/features/dashboard/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/excel_parser_service.dart';
import '../providers/spreadsheet_data_provider.dart';
import '../widgets/hero_metric_card.dart';
import '../widgets/mini_kpi_card.dart';
import '../widgets/monthly_comparison_chart.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/top_products_card.dart';

enum DashboardKpi {
  faturamento('Faturamento', AppColors.primary),
  lucro('Lucro', AppColors.ciano),
  lucroPercentual('Lucro %', AppColors.primary),
  ticketMedio('Ticket Medio', AppColors.secundaria),
  pedidosCompleted('Pedidos Concluídos', AppColors.ciano),
  devolucoes('Devolucoes', AppColors.error);

  final String label;
  final Color color;

  const DashboardKpi(this.label, this.color);
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardKpi _selectedKpi = DashboardKpi.faturamento;

  @override
  Widget build(BuildContext context) {
    final spreadsheetState = ref.watch(spreadsheetDataProvider);
    final data = spreadsheetState.activeData;
    final theme = Theme.of(context);
    final activeMonthLabel = _activeMonthLabel(spreadsheetState);
    final monthlyMetrics = _buildMonthlyMetrics(spreadsheetState, _selectedKpi);
    final chartConfig = _kpiChartConfig(_selectedKpi);
    final currency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    if (spreadsheetState.status == SpreadsheetStatus.loading) {
      return const SafeArea(top: false, child: SkeletonLoading());
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(
              state: spreadsheetState,
              monthLabel: activeMonthLabel,
            ),
            _SpreadsheetSelector(state: spreadsheetState),
            if (data == null)
              _EmptyDashboard(state: spreadsheetState)
            else ...[
              HeroMetricCard(
                label: 'Faturamento Total',
                value: data.faturamentoTotal,
                icon: Icons.trending_up_rounded,
                subtitle: 'Resumo consolidado das planilhas selecionadas',
                badge: 'XLSX',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    MiniKpiCard(
                      label: 'Lucro Total',
                      value: currency.format(data.lucroTotal),
                      icon: Icons.attach_money_rounded,
                      accentColor: AppColors.ciano,
                      caption: 'Somente pedidos concluídos',
                    ),
                    MiniKpiCard(
                      label: 'Lucro %',
                      value: '${data.lucroPercentual.toStringAsFixed(1)}%',
                      icon: Icons.percent_rounded,
                      accentColor: AppColors.primary,
                      caption: 'Lucro / faturamento',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    MiniKpiCard(
                      label: 'Ticket Médio',
                      value: currency.format(data.ticketMedio),
                      icon: Icons.sell_outlined,
                      accentColor: AppColors.secundaria,
                      caption: 'Faturamento / concluídos',
                    ),
                    MiniKpiCard(
                      label: 'Pedidos Concluídos',
                      value: '${data.pedidosCompleted}',
                      icon: Icons.check_circle_outline_rounded,
                      accentColor: AppColors.ciano,
                      caption: 'Status exatamente COMPLETED',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    MiniKpiCard(
                      label: 'Devoluções',
                      value: '${data.pedidosDevolucao}',
                      icon: Icons.assignment_return_outlined,
                      accentColor: AppColors.error,
                      caption: 'Status contendo DEVOLUCAO',
                    ),
                    MiniKpiCard(
                      label: 'Planilha ativa',
                      value: _activeSheetName(spreadsheetState),
                      icon: Icons.description_outlined,
                      accentColor: AppColors.amarelo,
                      caption: 'Fonte atual do dashboard',
                    ),
                  ],
                ),
              ),
              _SummaryCard(
                state: spreadsheetState,
                data: data,
                monthLabel: activeMonthLabel,
              ),
              if (monthlyMetrics.isNotEmpty)
                Column(
                  children: [
                    _KpiSelector(
                      selectedKpi: _selectedKpi,
                      onSelected: (kpi) {
                        setState(() => _selectedKpi = kpi);
                      },
                    ),
                    MonthlyComparisonChart(
                      data: monthlyMetrics,
                      title: chartConfig.title,
                      legendLabel: chartConfig.legendLabel,
                      color: chartConfig.color,
                      formatValue: chartConfig.formatValue,
                    ),
                  ],
                ),
              TopProductsCard(
                title: 'Top 10 Produtos mais vendidos',
                subtitle: 'Ordenado por quantidade vendida',
                topItems: data.top10Produtos,
                itemRevenue: {
                  for (final item in data.top10ProdutosReceita)
                    item.key: item.value,
                },
              ),
              TopProductsCard(
                title: 'Top 10 Anúncios mais vendidos',
                subtitle: 'Agrupado por Tipo Anúncio, com fallback em SKU',
                topItems: data.top10Anuncios,
                itemRevenue: {
                  for (final item in data.top10AnunciosReceita)
                    item.key: item.value,
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Todos os indicadores foram calculados no momento da importação da planilha XLSX e persistidos no Firebase. O dashboard apenas consome o resumo da planilha ativa.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _activeSheetName(SpreadsheetDataState state) {
    try {
      final selected =
          state.spreadsheets.where((sheet) => sheet.selected).toList();
      if (selected.isEmpty) return '-';
      if (selected.length == 1) {
        return selected.first.name.replaceAll('.xlsx', '');
      }
      return '${selected.length} planilhas';
    } catch (_) {
      return '-';
    }
  }

  String _activeMonthLabel(SpreadsheetDataState state) {
    try {
      final selected =
          state.spreadsheets.where((sheet) => sheet.selected).toList();
      if (selected.isEmpty) return '-';
      if (selected.length == 1) {
        final summary = selected.first.summary;
        final key = summary.mesReferencia ??
            _keyFromDate(summary.dataInicio ?? summary.dataFim);
        final label = summary.mesReferenciaLabel ??
            (key != null ? _labelFromKey(key) : null);
        return label ?? '-';
      }

      final selectedKeys = <String>{};
      for (final sheet in selected) {
        final summary = sheet.summary;
        final key = summary.mesReferencia ??
            _keyFromDate(summary.dataInicio ?? summary.dataFim);
        if (key != null && key.isNotEmpty) {
          selectedKeys.add(key);
        }
      }

      if (selectedKeys.length == 1) {
        return _labelFromKey(selectedKeys.first);
      }
      return 'Multiplos meses';
    } catch (_) {
      return '-';
    }
  }

  List<MonthlyMetric> _buildMonthlyMetrics(
    SpreadsheetDataState state,
    DashboardKpi kpi,
  ) {
    final selected = state.spreadsheets.where((sheet) => sheet.selected);
    final totals = <String, _MonthlyAccumulator>{};

    for (final sheet in selected) {
      final summary = sheet.summary;
      final key = summary.mesReferencia ??
          _keyFromDate(summary.dataInicio ?? summary.dataFim);
      if (key == null || key.isEmpty) continue;

      final label = summary.mesReferenciaLabel ?? _labelFromKey(key);
      final acc = totals.putIfAbsent(
        key,
        () => _MonthlyAccumulator(key: key, label: label),
      );
      acc.faturamento += summary.faturamentoTotal;
      acc.lucro += summary.lucroTotal;
      acc.pedidosCompleted += summary.pedidosCompleted;
      acc.pedidosDevolucao += summary.pedidosDevolucao;
    }

    final metrics = totals.values.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return metrics
        .map((item) => MonthlyMetric(
              label: item.label,
              value: _valueForKpi(item, kpi),
            ))
        .toList();
  }

  double _valueForKpi(_MonthlyAccumulator item, DashboardKpi kpi) {
    switch (kpi) {
      case DashboardKpi.faturamento:
        return item.faturamento;
      case DashboardKpi.lucro:
        return item.lucro;
      case DashboardKpi.lucroPercentual:
        return item.faturamento > 0
            ? (item.lucro / item.faturamento) * 100
            : 0.0;
      case DashboardKpi.ticketMedio:
        return item.pedidosCompleted > 0
            ? item.faturamento / item.pedidosCompleted
            : 0.0;
      case DashboardKpi.pedidosCompleted:
        return item.pedidosCompleted.toDouble();
      case DashboardKpi.devolucoes:
        return item.pedidosDevolucao.toDouble();
    }
  }

  _KpiChartConfig _kpiChartConfig(DashboardKpi kpi) {
    final currencyShort = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 0,
    );
    final currencyFull = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    switch (kpi) {
      case DashboardKpi.faturamento:
        return _KpiChartConfig(
          title: 'Faturamento por Mes',
          legendLabel: 'Faturamento',
          color: DashboardKpi.faturamento.color,
          formatValue: (value) => currencyShort.format(value),
        );
      case DashboardKpi.lucro:
        return _KpiChartConfig(
          title: 'Lucro por Mes',
          legendLabel: 'Lucro',
          color: DashboardKpi.lucro.color,
          formatValue: (value) => currencyShort.format(value),
        );
      case DashboardKpi.lucroPercentual:
        return _KpiChartConfig(
          title: 'Lucro % por Mes',
          legendLabel: 'Lucro %',
          color: DashboardKpi.lucroPercentual.color,
          formatValue: (value) => '${value.toStringAsFixed(1)}%',
        );
      case DashboardKpi.ticketMedio:
        return _KpiChartConfig(
          title: 'Ticket Medio por Mes',
          legendLabel: 'Ticket Medio',
          color: DashboardKpi.ticketMedio.color,
          formatValue: (value) => currencyFull.format(value),
        );
      case DashboardKpi.pedidosCompleted:
        return _KpiChartConfig(
          title: 'Pedidos Concluídos por Mês',
          legendLabel: 'Pedidos Concluídos',
          color: DashboardKpi.pedidosCompleted.color,
          formatValue: (value) => value.toStringAsFixed(0),
        );
      case DashboardKpi.devolucoes:
        return _KpiChartConfig(
          title: 'Devolucoes por Mes',
          legendLabel: 'Devolucoes',
          color: DashboardKpi.devolucoes.color,
          formatValue: (value) => value.toStringAsFixed(0),
        );
    }
  }

  String? _keyFromDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  String _labelFromKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return key;
    const names = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${names[month - 1]}/$year';
  }
}

class _MonthlyAccumulator {
  final String key;
  final String label;
  double faturamento = 0;
  double lucro = 0;
  int pedidosCompleted = 0;
  int pedidosDevolucao = 0;

  _MonthlyAccumulator({
    required this.key,
    required this.label,
  });
}

class _KpiChartConfig {
  final String title;
  final String legendLabel;
  final Color color;
  final String Function(double) formatValue;

  const _KpiChartConfig({
    required this.title,
    required this.legendLabel,
    required this.color,
    required this.formatValue,
  });
}

class _DashboardHeader extends StatelessWidget {
  final SpreadsheetDataState state;
  final String? monthLabel;

  const _DashboardHeader({required this.state, this.monthLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.activeSpreadsheetId == null
                      ? '${state.spreadsheets.length} planilhas importadas'
                      : 'Exibindo planilha ativa'
                          '${_monthSuffix(monthLabel)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.quaternaria,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _monthSuffix(String? monthLabel) {
    if (monthLabel == null || monthLabel.trim().isEmpty || monthLabel == '-') {
      return '';
    }
    return ' • $monthLabel';
  }
}

class _SpreadsheetSelector extends ConsumerWidget {
  final SpreadsheetDataState state;

  const _SpreadsheetSelector({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (state.spreadsheets.isEmpty) {
      return const SizedBox(height: 16);
    }

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: state.spreadsheets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final spreadsheet = state.spreadsheets[index];

          return FilterChip(
            selected: spreadsheet.selected,
            onSelected: (value) => ref
                .read(spreadsheetDataProvider.notifier)
                .setSpreadsheetSelected(spreadsheet.id, value),
            showCheckmark: false,
            avatar: Icon(
              Icons.circle,
              size: 9,
              color:
                  spreadsheet.selected ? AppColors.amarelo : AppColors.textHint,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    spreadsheet.name.replaceAll('.xlsx', ''),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (spreadsheet.selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: spreadsheet.selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: AppColors.background,
            selectedColor: AppColors.primaryLight,
            side: BorderSide(
              color:
                  spreadsheet.selected ? AppColors.primary : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _KpiSelector extends StatelessWidget {
  final DashboardKpi selectedKpi;
  final ValueChanged<DashboardKpi> onSelected;

  const _KpiSelector({
    required this.selectedKpi,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = DashboardKpi.values;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final kpi = items[index];
          final selected = kpi == selectedKpi;

          return FilterChip(
            selected: selected,
            onSelected: (_) => onSelected(kpi),
            showCheckmark: false,
            avatar: Icon(
              Icons.circle,
              size: 9,
              color: selected ? kpi.color : AppColors.textHint,
            ),
            label: Text(kpi.label),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? kpi.color : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: AppColors.background,
            selectedColor: AppColors.primaryLight,
            side: BorderSide(
              color: selected ? kpi.color : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SpreadsheetDataState state;
  final SpreadsheetAggregatedData data;
  final String? monthLabel;

  const _SummaryCard({
    required this.state,
    required this.data,
    this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );

    final activeName = state.spreadsheets
        .firstWhere((sheet) => sheet.selected)
        .name
        .replaceAll('.xlsx', '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryPill(
                  label: 'Pedidos Concluídos',
                  value: '${data.pedidosCompleted}',
                  icon: Icons.done_all_rounded,
                  color: AppColors.ciano,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryPill(
                  label: 'Devoluções',
                  value: '${data.pedidosDevolucao}',
                  icon: Icons.keyboard_return_rounded,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.chartGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo ativo',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (monthLabel != null && monthLabel!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Mes: $monthLabel',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  formatter.format(data.lucroTotal),
                  style: const TextStyle(
                    color: AppColors.ciano,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  final SpreadsheetDataState state;

  const _EmptyDashboard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFiles = state.spreadsheets.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 50, 32, 32),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.ciano.withOpacity(0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: AppColors.primary,
                size: 46,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              hasFiles ? 'Selecione uma planilha' : 'Seu dashboard está vazio',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              hasFiles
                  ? 'Escolha uma ou mais planilhas acima para exibir os KPIs processados.'
                  : 'Importe um XLSX na aba Home para visualizar faturamento, lucro, pedidos concluídos, devoluções e rankings.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (!hasFiles) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _StepRow(
                      number: '1',
                      text: 'Vá para a aba Home',
                      icon: Icons.home_rounded,
                    ),
                    SizedBox(height: 14),
                    _StepRow(
                      number: '2',
                      text: 'Toque no botão XLSX para importar',
                      icon: Icons.upload_file_rounded,
                    ),
                    SizedBox(height: 14),
                    _StepRow(
                      number: '3',
                      text: 'Abra o dashboard e selecione a planilha ativa',
                      icon: Icons.auto_awesome,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;
  final IconData icon;

  const _StepRow({
    required this.number,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.chartGradient),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
