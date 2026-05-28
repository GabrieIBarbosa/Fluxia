import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_dashboard/core/services/excel_parser_service.dart';
import 'package:ecommerce_dashboard/features/dashboard/providers/spreadsheet_data_provider.dart';

SpreadsheetAggregatedData _summary({
  int pedidosCompleted = 0,
  int pedidosDevolucao = 0,
  double faturamentoTotal = 0,
  double lucroTotal = 0,
}) {
  final lucroPercentual =
      faturamentoTotal > 0 ? (lucroTotal / faturamentoTotal) * 100 : 0.0;
  final ticketMedio =
      pedidosCompleted > 0 ? faturamentoTotal / pedidosCompleted : 0.0;

  return SpreadsheetAggregatedData(
    pedidosCompleted: pedidosCompleted,
    pedidosDevolucao: pedidosDevolucao,
    faturamentoTotal: faturamentoTotal,
    lucroTotal: lucroTotal,
    lucroPercentual: lucroPercentual,
    ticketMedio: ticketMedio,
    top10Produtos: const <MapEntry<String, int>>[],
    top10ProdutosReceita: const <MapEntry<String, double>>[],
    top10ProdutosDevolvidos: const <MapEntry<String, int>>[],
    top10Anuncios: const <MapEntry<String, int>>[],
    top10AnunciosReceita: const <MapEntry<String, double>>[],
    mesReferencia: null,
    mesReferenciaLabel: null,
    dataInicio: null,
    dataFim: null,
    records: const <SaleRecord>[],
  );
}

void main() {
  test('setSpreadsheetSelected combines multiple selected sheets', () {
    final notifier = SpreadsheetDataNotifier(uid: null);
    final sheet1 = ImportedSpreadsheet(
      id: 's1',
      name: 'sheet1.xlsx',
      size: 100,
      importedAt: DateTime(2024, 5, 1),
      summary: _summary(
        pedidosCompleted: 2,
        pedidosDevolucao: 1,
        faturamentoTotal: 100.0,
        lucroTotal: 10.0,
      ),
      selected: false,
    );
    final sheet2 = ImportedSpreadsheet(
      id: 's2',
      name: 'sheet2.xlsx',
      size: 200,
      importedAt: DateTime(2024, 5, 2),
      summary: _summary(
        pedidosCompleted: 3,
        pedidosDevolucao: 0,
        faturamentoTotal: 200.0,
        lucroTotal: 30.0,
      ),
      selected: false,
    );

    notifier.state = SpreadsheetDataState(
      status: SpreadsheetStatus.loaded,
      spreadsheets: [sheet1, sheet2],
    );

    notifier.setSpreadsheetSelected('s1', true);
    notifier.setSpreadsheetSelected('s2', true);

    final active = notifier.state.activeData!;
    expect(active.faturamentoTotal, 300.0);
    expect(active.lucroTotal, 40.0);
    expect(active.pedidosCompleted, 5);
    expect(active.pedidosDevolucao, 1);
    expect(notifier.state.activeSpreadsheetId, 's1');
    expect(notifier.state.selectedCount, 2);
    expect(notifier.state.spreadsheets.first.selected, isTrue);
    expect(notifier.state.spreadsheets.last.selected, isTrue);
  });

  test('setAllSpreadsheetsSelected toggles every sheet', () {
    final notifier = SpreadsheetDataNotifier(uid: null);
    final sheet1 = ImportedSpreadsheet(
      id: 's1',
      name: 'sheet1.xlsx',
      size: 100,
      importedAt: DateTime(2024, 5, 1),
      summary: _summary(
        pedidosCompleted: 1,
        pedidosDevolucao: 0,
        faturamentoTotal: 50.0,
        lucroTotal: 5.0,
      ),
      selected: true,
    );
    final sheet2 = ImportedSpreadsheet(
      id: 's2',
      name: 'sheet2.xlsx',
      size: 200,
      importedAt: DateTime(2024, 5, 2),
      summary: _summary(
        pedidosCompleted: 1,
        pedidosDevolucao: 0,
        faturamentoTotal: 80.0,
        lucroTotal: 8.0,
      ),
      selected: true,
    );

    notifier.state = SpreadsheetDataState(
      status: SpreadsheetStatus.loaded,
      spreadsheets: [sheet1, sheet2],
    );

    notifier.setAllSpreadsheetsSelected(false);

    expect(notifier.state.activeData, isNull);
    expect(notifier.state.activeSpreadsheetId, isNull);
    expect(notifier.state.selectedCount, 0);
    expect(notifier.state.spreadsheets.first.selected, isFalse);
    expect(notifier.state.spreadsheets.last.selected, isFalse);

    notifier.setAllSpreadsheetsSelected(true);

    expect(notifier.state.activeData, isNotNull);
    expect(notifier.state.activeSpreadsheetId, 's1');
    expect(notifier.state.selectedCount, 2);
    expect(notifier.state.allSelected, isTrue);
  });

  test('deselecting active sheet clears active data', () {
    final notifier = SpreadsheetDataNotifier(uid: null);
    final sheet = ImportedSpreadsheet(
      id: 's1',
      name: 'sheet1.xlsx',
      size: 100,
      importedAt: DateTime(2024, 5, 1),
      summary: _summary(
        pedidosCompleted: 1,
        pedidosDevolucao: 0,
        faturamentoTotal: 50.0,
        lucroTotal: 5.0,
      ),
      selected: true,
    );

    notifier.state = SpreadsheetDataState(
      status: SpreadsheetStatus.loaded,
      spreadsheets: [sheet],
      activeSpreadsheetId: 's1',
      activeData: sheet.summary,
    );

    notifier.setSpreadsheetSelected('s1', false);

    expect(notifier.state.activeData, isNull);
    expect(notifier.state.activeSpreadsheetId, isNull);
    expect(notifier.state.selectedCount, 0);
  });

  test('renameSpreadsheet updates local state without Firestore for local user',
      () async {
    final notifier = SpreadsheetDataNotifier(uid: null);
    final sheet = ImportedSpreadsheet(
      id: 's1',
      name: 'old.xlsx',
      size: 100,
      importedAt: DateTime(2024, 5, 1),
      summary: _summary(),
      selected: true,
    );

    notifier.state = SpreadsheetDataState(
      status: SpreadsheetStatus.loaded,
      spreadsheets: [sheet],
      activeSpreadsheetId: 's1',
      activeData: sheet.summary,
    );

    await notifier.renameSpreadsheet('s1', 'new.xlsx');

    expect(notifier.state.spreadsheets.single.name, 'new.xlsx');
    expect(notifier.state.activeSpreadsheetId, 's1');
  });
}
