import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:ecommerce_dashboard/core/services/excel_parser_service.dart';
import 'package:ecommerce_dashboard/features/dashboard/providers/spreadsheet_data_provider.dart';
import 'package:ecommerce_dashboard/features/dashboard/screens/dashboard_screen.dart';

SpreadsheetAggregatedData _summary() {
  return SpreadsheetAggregatedData(
    pedidosCompleted: 3,
    pedidosDevolucao: 1,
    faturamentoTotal: 150.0,
    lucroTotal: 30.0,
    lucroPercentual: 20.0,
    ticketMedio: 50.0,
    top10Produtos: const <MapEntry<String, int>>[],
    top10ProdutosReceita: const <MapEntry<String, double>>[],
    top10ProdutosDevolvidos: const <MapEntry<String, int>>[],
    top10Anuncios: const <MapEntry<String, int>>[],
    top10AnunciosReceita: const <MapEntry<String, double>>[],
    mesReferencia: '2024-05',
    mesReferenciaLabel: 'Mai/2024',
    dataInicio: DateTime(2024, 5, 1),
    dataFim: DateTime(2024, 5, 30),
    records: const <SaleRecord>[],
  );
}

void main() {
  setUp(() {
    Intl.defaultLocale = 'pt_BR';
  });

  testWidgets('shows empty dashboard when no spreadsheets', (tester) async {
    final emptyState = const SpreadsheetDataState(
      status: SpreadsheetStatus.empty,
      spreadsheets: [],
    );

    final notifier = SpreadsheetDataNotifier(uid: null)..state = emptyState;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spreadsheetDataProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Seu dashboard está vazio'), findsOneWidget);
  });

  testWidgets('renders KPIs when active data exists', (tester) async {
    final sheet = ImportedSpreadsheet(
      id: 's1',
      name: 'sheet1.xlsx',
      size: 100,
      importedAt: DateTime(2024, 5, 1),
      summary: _summary(),
      selected: true,
    );

    final loadedState = SpreadsheetDataState(
      status: SpreadsheetStatus.loaded,
      spreadsheets: [sheet],
      activeSpreadsheetId: 's1',
      activeData: _summary(),
    );

    final notifier = SpreadsheetDataNotifier(uid: null)..state = loadedState;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spreadsheetDataProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Faturamento Total'), findsOneWidget);
    expect(find.text('Pedidos Concluídos'), findsWidgets);
    expect(find.text('Planilha ativa'), findsOneWidget);
  });
}
