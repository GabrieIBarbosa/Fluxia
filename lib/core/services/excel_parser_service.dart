// lib/core/services/excel_parser_service.dart

import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../constants/app_config.dart';

class SaleRecord {
  final String loja;
  final String marketplace;
  final String idPedido;
  final String idEnvio;
  final DateTime? dataVenda;
  final String status;
  final String sku;
  final String produto;
  final String produtosIndividuais;
  final int quantidade;
  final double precoUnitario;
  final double vendaTotal;
  final String tipoAnuncio;
  final String tipoEntrega;
  final double custoProduto;
  final double comissaoMkt;
  final double adsFacil;
  final double custoFrete;
  final double imposto;
  final double embalagem;
  final double custoTotal;
  final double lucroReais;
  final double lucroPercentual;

  const SaleRecord({
    required this.loja,
    required this.marketplace,
    required this.idPedido,
    required this.idEnvio,
    required this.dataVenda,
    required this.status,
    required this.sku,
    required this.produto,
    required this.produtosIndividuais,
    required this.quantidade,
    required this.precoUnitario,
    required this.vendaTotal,
    required this.tipoAnuncio,
    required this.tipoEntrega,
    required this.custoProduto,
    required this.comissaoMkt,
    required this.adsFacil,
    required this.custoFrete,
    required this.imposto,
    required this.embalagem,
    required this.custoTotal,
    required this.lucroReais,
    required this.lucroPercentual,
  });

  Map<String, dynamic> toMap() {
    return {
      'loja': loja,
      'marketplace': marketplace,
      'id_pedido': idPedido,
      'id_envio': idEnvio,
      'data_venda': dataVenda,
      'status': status,
      'sku': sku,
      'produto': produto,
      'produtos_individuais': produtosIndividuais,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'venda_total': vendaTotal,
      'tipo_anuncio': tipoAnuncio,
      'tipo_entrega': tipoEntrega,
      'custo_produto': custoProduto,
      'comissao_mkt': comissaoMkt,
      'ads_facil': adsFacil,
      'custo_frete': custoFrete,
      'imposto': imposto,
      'embalagem': embalagem,
      'custo_total': custoTotal,
      'lucro_reais': lucroReais,
      'lucro_percentual': lucroPercentual,
    };
  }
}

class SpreadsheetAggregatedData {
  final int pedidosCompleted;
  final int pedidosDevolucao;
  final double faturamentoTotal;
  final double lucroTotal;
  final double lucroPercentual;
  final double ticketMedio;
  final List<MapEntry<String, int>> top10Produtos;
  final List<MapEntry<String, double>> top10ProdutosReceita;
  final List<MapEntry<String, int>> top10Anuncios;
  final List<MapEntry<String, double>> top10AnunciosReceita;
  final String? mesReferencia;
  final String? mesReferenciaLabel;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final List<SaleRecord> records;

  const SpreadsheetAggregatedData({
    required this.pedidosCompleted,
    required this.pedidosDevolucao,
    required this.faturamentoTotal,
    required this.lucroTotal,
    required this.lucroPercentual,
    required this.ticketMedio,
    required this.top10Produtos,
    required this.top10ProdutosReceita,
    required this.top10Anuncios,
    required this.top10AnunciosReceita,
    this.mesReferencia,
    this.mesReferenciaLabel,
    required this.dataInicio,
    required this.dataFim,
    required this.records,
  });

  Map<String, dynamic> toFirestoreMap() {
    return {
      'pedidos_completed': pedidosCompleted,
      'pedidos_devolucao': pedidosDevolucao,
      'faturamento_total': faturamentoTotal,
      'lucro_total': lucroTotal,
      'lucro_percentual': lucroPercentual,
      'ticket_medio': ticketMedio,
      'mes_referencia': mesReferencia,
      'mes_label': mesReferenciaLabel,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'top_10_produtos': top10Produtos
          .map((e) => {'nome': e.key, 'quantidade': e.value})
          .toList(),
      'top_10_produtos_receita': top10ProdutosReceita
          .map((e) => {'nome': e.key, 'valor': e.value})
          .toList(),
      'top_10_anuncios': top10Anuncios
          .map((e) => {'nome': e.key, 'quantidade': e.value})
          .toList(),
      'top_10_anuncios_receita': top10AnunciosReceita
          .map((e) => {'nome': e.key, 'valor': e.value})
          .toList(),
    };
  }

  Map<String, dynamic> toResumoJson() {
    return {
      'pedidos_completed': pedidosCompleted,
      'pedidos_devolucao': pedidosDevolucao,
      'faturamento_total': faturamentoTotal,
      'lucro_total': lucroTotal,
      'lucro_percentual': lucroPercentual,
      'ticket_medio': ticketMedio,
      'mes_referencia': mesReferencia,
      'mes_label': mesReferenciaLabel,
      'top_10_produtos': top10Produtos
          .map((e) => {'produto': e.key, 'quantidade': e.value})
          .toList(),
      'top_10_anuncios': top10Anuncios
          .map((e) => {'anuncio': e.key, 'quantidade': e.value})
          .toList(),
    };
  }

  factory SpreadsheetAggregatedData.fromFirestoreMap(
    Map<String, dynamic> map, {
    List<SaleRecord> records = const [],
  }) {
    List<MapEntry<String, int>> parseIntRanking(String key) {
      final raw = (map[key] as List?) ?? const [];
      return raw
          .map(
            (e) => MapEntry<String, int>(
              (e['nome'] ?? '-').toString(),
              ((e['quantidade'] ?? 0) as num).toInt(),
            ),
          )
          .toList();
    }

    List<MapEntry<String, double>> parseDoubleRanking(String key) {
      final raw = (map[key] as List?) ?? const [];
      return raw
          .map(
            (e) => MapEntry<String, double>(
              (e['nome'] ?? '-').toString(),
              ((e['valor'] ?? 0) as num).toDouble(),
            ),
          )
          .toList();
    }

    final monthKey = map['mes_referencia']?.toString();
    final monthLabel = map['mes_label']?.toString() ??
        ExcelParserService._monthLabelFromKey(monthKey);

    return SpreadsheetAggregatedData(
      pedidosCompleted: ((map['pedidos_completed'] ?? 0) as num).toInt(),
      pedidosDevolucao: ((map['pedidos_devolucao'] ?? 0) as num).toInt(),
      faturamentoTotal: ((map['faturamento_total'] ?? 0) as num).toDouble(),
      lucroTotal: ((map['lucro_total'] ?? 0) as num).toDouble(),
      lucroPercentual: ((map['lucro_percentual'] ?? 0) as num).toDouble(),
      ticketMedio: ((map['ticket_medio'] ?? 0) as num).toDouble(),
      top10Produtos: parseIntRanking('top_10_produtos'),
      top10ProdutosReceita: parseDoubleRanking('top_10_produtos_receita'),
      top10Anuncios: parseIntRanking('top_10_anuncios'),
      top10AnunciosReceita: parseDoubleRanking('top_10_anuncios_receita'),
      mesReferencia: monthKey,
      mesReferenciaLabel: monthLabel,
      dataInicio: map['data_inicio'],
      dataFim: map['data_fim'],
      records: records,
    );
  }
}

class ExcelParserService {
  static const List<String> _monthNames = [
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

  static String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static String _monthLabel(DateTime date) {
    final name = _monthNames[date.month - 1];
    return '$name/${date.year}';
  }

  static String? _monthLabelFromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final parts = key.split('-');
    if (parts.length != 2) return null;
    final year = parts[0];
    final monthIndex = int.tryParse(parts[1]) ?? 0;
    if (monthIndex < 1 || monthIndex > 12) return null;
    final name = _monthNames[monthIndex - 1];
    return '$name/$year';
  }

  static SpreadsheetAggregatedData parseAndAggregate(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw Exception('Arquivo XLSX vazio ou inválido.');
    }

    final sheet = excel.tables.values.first;
    if (sheet.rows.isEmpty) {
      throw Exception('A planilha não possui linhas.');
    }

    final header = sheet.rows.first
        .map((e) => (e?.value ?? '').toString().trim())
        .toList();

    final missing = AppConfig.requiredSpreadsheetColumns
        .where((col) => !header.contains(col))
        .toList();

    if (missing.isNotEmpty) {
      throw Exception(
        'Colunas obrigatórias não encontradas: ${missing.join(', ')}.\n'
        'A planilha precisa conter exatamente a estrutura esperada.',
      );
    }

    int indexOf(String name) => header.indexOf(name);

    final idxLoja = indexOf('Loja');
    final idxMarketplace = indexOf('Marketplace');
    final idxIdPedido = indexOf('ID Pedido');
    final idxIdEnvio = indexOf('ID Envio');
    final idxDataVenda = indexOf('Data Venda');
    final idxStatus = indexOf('Status');
    final idxSku = indexOf('SKU');
    final idxProduto = indexOf('Produto');
    final idxProdutosIndividuais = indexOf('Produtos Individuais');
    final idxQuantidade = indexOf('Quantidade');
    final idxPrecoUnit = indexOf('Preço Unit.');
    final idxVendaTotal = indexOf('Venda Total');
    final idxTipoAnuncio = indexOf('Tipo Anúncio');
    final idxTipoEntrega = indexOf('Tipo Entrega');
    final idxCustoProduto = indexOf('Custo Produto');
    final idxComissaoMkt = indexOf('Comissão MKT');
    final idxAdsFacil = indexOf('Ads Fácil');
    final idxCustoFrete = indexOf('Custo Frete');
    final idxImposto = indexOf('Imposto');
    final idxEmbalagem = indexOf('Embalagem');
    final idxCustoTotal = indexOf('Custo Total');
    final idxLucroRs = indexOf('Lucro R\$');
    final idxLucroPct = indexOf('Lucro %');

    final records = <SaleRecord>[];

    for (int i = 1; i < sheet.rows.length; i++) {
      final row = sheet.rows[i];
      if (row.isEmpty) continue;

      String textAt(int index) {
        if (index < 0 || index >= row.length) return '';
        return (row[index]?.value ?? '').toString().trim();
      }

      final produto = textAt(idxProduto);
      final sku = textAt(idxSku);
      final status = textAt(idxStatus);

      if (produto.isEmpty && sku.isEmpty && status.isEmpty) {
        continue;
      }

      final record = SaleRecord(
        loja: textAt(idxLoja),
        marketplace: textAt(idxMarketplace),
        idPedido: textAt(idxIdPedido),
        idEnvio: textAt(idxIdEnvio),
        dataVenda: _parseDateCell(indexValue(row, idxDataVenda)),
        status: status,
        sku: sku,
        produto: produto,
        produtosIndividuais: textAt(idxProdutosIndividuais),
        quantidade: _toInt(indexValue(row, idxQuantidade)),
        precoUnitario: _toDouble(indexValue(row, idxPrecoUnit)),
        vendaTotal: _toDouble(indexValue(row, idxVendaTotal)),
        tipoAnuncio: textAt(idxTipoAnuncio),
        tipoEntrega: textAt(idxTipoEntrega),
        custoProduto: _toDouble(indexValue(row, idxCustoProduto)),
        comissaoMkt: _toDouble(indexValue(row, idxComissaoMkt)),
        adsFacil: _toDouble(indexValue(row, idxAdsFacil)),
        custoFrete: _toDouble(indexValue(row, idxCustoFrete)),
        imposto: _toDouble(indexValue(row, idxImposto)),
        embalagem: _toDouble(indexValue(row, idxEmbalagem)),
        custoTotal: _toDouble(indexValue(row, idxCustoTotal)),
        lucroReais: _toDouble(indexValue(row, idxLucroRs)),
        lucroPercentual: _toDouble(indexValue(row, idxLucroPct)),
      );

      records.add(record);
    }

    return aggregateRecords(records);
  }

  static dynamic indexValue(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return null;
    return row[index]?.value;
  }

  static SpreadsheetAggregatedData aggregateRecords(List<SaleRecord> records) {
    final completedRecords = <SaleRecord>[];
    int pedidosDevolucao = 0;

    final produtoQtd = <String, int>{};
    final produtoFat = <String, double>{};
    final anuncioQtd = <String, int>{};
    final anuncioFat = <String, double>{};

    final monthCounts = <String, int>{};
    final monthLabels = <String, String>{};

    double faturamentoTotal = 0;
    double lucroTotal = 0;
    DateTime? dataInicio;
    DateTime? dataFim;

    for (final record in records) {
      if (record.dataVenda != null) {
        final key = _monthKey(record.dataVenda!);
        monthCounts[key] = (monthCounts[key] ?? 0) + 1;
        monthLabels[key] = _monthLabel(record.dataVenda!);
      }

      final status = _normalize(record.status);

      if (status == 'COMPLETED') {
        completedRecords.add(record);
        faturamentoTotal += record.vendaTotal;
        lucroTotal += record.lucroReais;

        final individualItems =
            _parseProdutosIndividuais(record.produtosIndividuais);
        if (individualItems.isNotEmpty) {
          final totalQty = individualItems.values.fold<int>(0, (a, b) => a + b);
          for (final entry in individualItems.entries) {
            final name = entry.key;
            final qty = entry.value;
            if (name.isEmpty || qty <= 0) continue;
            produtoQtd[name] = (produtoQtd[name] ?? 0) + qty;
            if (totalQty > 0) {
              final share = record.vendaTotal * (qty / totalQty);
              produtoFat[name] = (produtoFat[name] ?? 0) + share;
            }
          }
        } else {
          final produtoKey = record.produto.isNotEmpty ? record.produto : '-';
          produtoQtd[produtoKey] =
              (produtoQtd[produtoKey] ?? 0) + record.quantidade;
          produtoFat[produtoKey] =
              (produtoFat[produtoKey] ?? 0) + record.vendaTotal;
        }

        final anuncioKey = record.tipoAnuncio.isNotEmpty
            ? record.tipoAnuncio
            : (record.produto.isNotEmpty
                ? record.produto
                : (record.sku.isNotEmpty ? record.sku : '-'));
        anuncioQtd[anuncioKey] =
            (anuncioQtd[anuncioKey] ?? 0) + record.quantidade;
        anuncioFat[anuncioKey] =
            (anuncioFat[anuncioKey] ?? 0) + record.vendaTotal;

        if (record.dataVenda != null) {
          if (dataInicio == null || record.dataVenda!.isBefore(dataInicio)) {
            dataInicio = record.dataVenda;
          }
          if (dataFim == null || record.dataVenda!.isAfter(dataFim)) {
            dataFim = record.dataVenda;
          }
        }
      }

      if (status.contains('DEVOLUCAO')) {
        pedidosDevolucao++;
      }
    }

    final pedidosCompleted = completedRecords.length;
    final lucroPercentual =
        faturamentoTotal > 0 ? (lucroTotal / faturamentoTotal) * 100 : 0.0;
    final ticketMedio =
        pedidosCompleted > 0 ? faturamentoTotal / pedidosCompleted : 0.0;

    final top10Produtos = produtoQtd.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top10ProdutosReceita = produtoFat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top10Anuncios = anuncioQtd.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top10AnunciosReceita = anuncioFat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String? mesReferencia;
    String? mesReferenciaLabel;
    if (monthCounts.isNotEmpty) {
      final sortedMonths = monthCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      mesReferencia = sortedMonths.first.key;
      mesReferenciaLabel =
          monthLabels[mesReferencia] ?? _monthLabelFromKey(mesReferencia);
    }

    return SpreadsheetAggregatedData(
      pedidosCompleted: pedidosCompleted,
      pedidosDevolucao: pedidosDevolucao,
      faturamentoTotal: faturamentoTotal,
      lucroTotal: lucroTotal,
      lucroPercentual: lucroPercentual,
      ticketMedio: ticketMedio,
      top10Produtos: top10Produtos.take(10).toList(),
      top10ProdutosReceita: top10ProdutosReceita.take(10).toList(),
      top10Anuncios: top10Anuncios.take(10).toList(),
      top10AnunciosReceita: top10AnunciosReceita.take(10).toList(),
      mesReferencia: mesReferencia,
      mesReferenciaLabel: mesReferenciaLabel,
      dataInicio: dataInicio,
      dataFim: dataFim,
      records: records,
    );
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('Ç', 'C')
        .replaceAll('Ã', 'A')
        .replaceAll('Á', 'A')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ô', 'O')
        .replaceAll('Õ', 'O')
        .replaceAll('Ú', 'U');
  }

  static Map<String, int> _parseProdutosIndividuais(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return {};

    final result = <String, int>{};
    final parts = text.split(';');
    final pattern = RegExp(r'^\s*(\d+)\s*[xX]\s*(.+)$');

    for (final part in parts) {
      final item = part.trim();
      if (item.isEmpty) continue;

      final match = pattern.firstMatch(item);
      if (match != null) {
        final qty = int.tryParse(match.group(1) ?? '') ?? 0;
        final name = (match.group(2) ?? '').trim();
        if (name.isEmpty || qty <= 0) continue;
        result[name] = (result[name] ?? 0) + qty;
      } else {
        result[item] = (result[item] ?? 0) + 1;
      }
    }

    return result;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    final parsed = _toDouble(value);
    return parsed.toInt();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    final raw = value.toString().trim();
    if (raw.isEmpty) return 0.0;

    var normalized =
        raw.replaceAll('R\$', '').replaceAll('%', '').replaceAll(' ', '');

    var isNegative = false;
    if (normalized.startsWith('(') && normalized.endsWith(')')) {
      isNegative = true;
      normalized = normalized.substring(1, normalized.length - 1);
    }
    if (normalized.startsWith('-')) {
      isNegative = true;
      normalized = normalized.substring(1);
    }

    final hasComma = normalized.contains(',');
    final hasDot = normalized.contains('.');
    var numberText = normalized;

    if (hasComma && hasDot) {
      final lastComma = normalized.lastIndexOf(',');
      final lastDot = normalized.lastIndexOf('.');
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final thousandSep = decimalSep == ',' ? '.' : ',';
      numberText = normalized.replaceAll(thousandSep, '');
      if (decimalSep == ',') {
        numberText = numberText.replaceAll(',', '.');
      }
    } else if (hasComma) {
      final parts = normalized.split(',');
      final looksLikeThousands = parts.length == 2 && parts[1].length == 3;
      numberText = looksLikeThousands
          ? normalized.replaceAll(',', '')
          : normalized.replaceAll(',', '.');
    } else if (hasDot) {
      final parts = normalized.split('.');
      final looksLikeThousands = parts.length == 2 && parts[1].length == 3;
      numberText = looksLikeThousands
          ? normalized.replaceAll('.', '')
          : normalized.replaceAll(',', '');
    }

    final parsed = double.tryParse(numberText) ?? 0.0;
    return isNegative ? -parsed : parsed;
  }

  static DateTime? _parseDateCell(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    if (value is int || value is double) {
      try {
        final serial = value is int ? value.toDouble() : value;
        final epoch = DateTime(1899, 12, 30);
        return epoch.add(Duration(days: serial.floor()));
      } catch (_) {
        return null;
      }
    }

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2].substring(0, 4));
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    if (raw.contains('-')) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) return dt;
    }

    return DateTime.tryParse(raw);
  }
}
