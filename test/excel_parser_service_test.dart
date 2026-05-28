import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_dashboard/core/constants/app_config.dart';
import 'package:ecommerce_dashboard/core/services/excel_parser_service.dart';

Uint8List _buildExcelBytes({
  required List<String> headers,
  required List<List<CellValue>> rows,
}) {
  final excel = Excel.createExcel();
  final sheet = excel[excel.getDefaultSheet()!];

  sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
  for (final row in rows) {
    sheet.appendRow(row);
  }

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to encode XLSX');
  }
  return Uint8List.fromList(bytes);
}

Map<String, dynamic> _rowWithOverrides(Map<String, dynamic> overrides) {
  final base = <String, dynamic>{
    for (final col in AppConfig.requiredSpreadsheetColumns) col: '',
  };
  base.addAll(overrides);
  return base;
}

List<CellValue> _rowFromMap(Map<String, dynamic> values) {
  return AppConfig.requiredSpreadsheetColumns.map((col) {
    final value = values[col];
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    return TextCellValue(value?.toString() ?? '');
  }).toList();
}

SaleRecord _saleRecord({
  required String status,
  required String produto,
  required String produtosIndividuais,
  required int quantidade,
  required double vendaTotal,
  required double lucroReais,
  String tipoAnuncio = 'Classico',
}) {
  return SaleRecord(
    loja: 'Loja 1',
    marketplace: 'ML',
    idPedido: 'P1',
    idEnvio: 'E1',
    dataVenda: DateTime(2024, 5, 1),
    status: status,
    sku: 'SKU1',
    produto: produto,
    produtosIndividuais: produtosIndividuais,
    quantidade: quantidade,
    precoUnitario: 10.0,
    vendaTotal: vendaTotal,
    tipoAnuncio: tipoAnuncio,
    tipoEntrega: 'Normal',
    custoProduto: 0.0,
    comissaoMkt: 0.0,
    adsFacil: 0.0,
    custoFrete: 0.0,
    imposto: 0.0,
    embalagem: 0.0,
    custoTotal: 0.0,
    lucroReais: lucroReais,
    lucroPercentual: 0.0,
  );
}

void main() {
  test('parseAndAggregate throws on missing columns', () {
    final bytes = _buildExcelBytes(
      headers: const ['Loja', 'Marketplace'],
      rows: const [],
    );

    expect(
      () => ExcelParserService.parseAndAggregate(bytes),
      throwsA(isA<Exception>()),
    );
  });

  test('parseAndAggregate computes completed and devolucao KPIs', () {
    final row1 = _rowWithOverrides({
      'Status': 'COMPLETED',
      'Produto': 'Produto A',
      'SKU': 'SKU-A',
      'Quantidade': 2,
      'Venda Total': 100.0,
      'Lucro R\$': 20.0,
      'Data Venda': '01/05/2024',
    });

    final row2 = _rowWithOverrides({
      'Status': 'DEVOLUCAO',
      'Produto': 'Produto B',
      'SKU': 'SKU-B',
      'Quantidade': 1,
      'Venda Total': 50.0,
      'Lucro R\$': 5.0,
      'Data Venda': '02/05/2024',
    });

    final bytes = _buildExcelBytes(
      headers: AppConfig.requiredSpreadsheetColumns,
      rows: [
        _rowFromMap(row1),
        _rowFromMap(row2),
      ],
    );

    final summary = ExcelParserService.parseAndAggregate(bytes);

    expect(summary.pedidosCompleted, 1);
    expect(summary.pedidosDevolucao, 1);
    expect(summary.faturamentoTotal, closeTo(100.0, 0.001));
    expect(summary.lucroTotal, closeTo(20.0, 0.001));
    expect(summary.ticketMedio, closeTo(100.0, 0.001));
    expect(summary.top10ProdutosDevolvidos.single.key, 'Produto B');
    expect(summary.top10ProdutosDevolvidos.single.value, 1);
  });

  test('parseAndAggregate accepts generic headers without AI mapping', () {
    final bytes = _buildExcelBytes(
      headers: const ['product', 'qty', 'total', 'status'],
      rows: [
        [
          TextCellValue('Produto Generico'),
          IntCellValue(2),
          DoubleCellValue(80.0),
          TextCellValue('COMPLETED'),
        ],
      ],
    );

    final summary = ExcelParserService.parseAndAggregate(bytes);

    expect(summary.pedidosCompleted, 1);
    expect(summary.faturamentoTotal, closeTo(80.0, 0.001));
    expect(summary.top10Produtos.single.key, 'Produto Generico');
  });

  test('parseAndAggregate preserves comma decimals in pt-BR numbers', () {
    final row = _rowWithOverrides({
      'Status': 'COMPLETED',
      'Produto': 'Produto A',
      'SKU': 'SKU-A',
      'Quantidade': '1',
      'Venda Total': 'R\$ 123,45',
      'Lucro R\$': '12,34',
      'Data Venda': '01/05/2024',
    });

    final bytes = _buildExcelBytes(
      headers: AppConfig.requiredSpreadsheetColumns,
      rows: [_rowFromMap(row)],
    );

    final summary = ExcelParserService.parseAndAggregate(bytes);

    expect(summary.faturamentoTotal, closeTo(123.45, 0.001));
    expect(summary.lucroTotal, closeTo(12.34, 0.001));
  });

  test('aggregateRecords splits produtos individuais in rankings', () {
    final summary = ExcelParserService.aggregateRecords([
      _saleRecord(
        status: 'COMPLETED',
        produto: 'Kit',
        produtosIndividuais: '2x Item A;1x Item B',
        quantidade: 3,
        vendaTotal: 30.0,
        lucroReais: 5.0,
      ),
    ]);

    final qty = {for (final e in summary.top10Produtos) e.key: e.value};
    final revenue = {
      for (final e in summary.top10ProdutosReceita) e.key: e.value,
    };

    expect(qty['Item A'], 2);
    expect(qty['Item B'], 1);
    expect(revenue['Item A'], closeTo(20.0, 0.01));
    expect(revenue['Item B'], closeTo(10.0, 0.01));
  });

  test('aggregateRecords ranks anuncios by tipo anuncio before produto', () {
    final summary = ExcelParserService.aggregateRecords([
      _saleRecord(
        status: 'COMPLETED',
        produto: 'Produto A',
        produtosIndividuais: '',
        quantidade: 1,
        vendaTotal: 100.0,
        lucroReais: 10.0,
        tipoAnuncio: 'Premium',
      ),
      _saleRecord(
        status: 'COMPLETED',
        produto: 'Produto A',
        produtosIndividuais: '',
        quantidade: 2,
        vendaTotal: 200.0,
        lucroReais: 20.0,
        tipoAnuncio: 'Classico',
      ),
    ]);

    final qty = {for (final e in summary.top10Anuncios) e.key: e.value};
    final revenue = {
      for (final e in summary.top10AnunciosReceita) e.key: e.value,
    };

    expect(qty['Premium'], 1);
    expect(qty['Classico'], 2);
    expect(qty.containsKey('Produto A'), isFalse);
    expect(revenue['Premium'], closeTo(100.0, 0.01));
    expect(revenue['Classico'], closeTo(200.0, 0.01));
  });
}
