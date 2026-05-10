// lib/core/services/csv_parser_service.dart

import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_config.dart';

/// Resultado da agregação do CSV.
class CsvAggregatedData {
  final double faturamentoTotal;
  final int totalPedidos;
  final double ticketMedio;
  final Map<String, int> produtoQuantidade; // produto → quantidade total
  final Map<String, double> produtoFaturamento; // produto → faturamento total
  final Map<String, double> vendasPorDia; // "dd/MM" → faturamento do dia
  final List<MapEntry<String, int>> top5Produtos;

  CsvAggregatedData({
    required this.faturamentoTotal,
    required this.totalPedidos,
    required this.ticketMedio,
    required this.produtoQuantidade,
    required this.produtoFaturamento,
    required this.vendasPorDia,
    required this.top5Produtos,
  });

  /// Gera o JSON resumido para enviar ao backend (IA).
  Map<String, dynamic> toResumoJson() {
    return {
      'faturamento_total': faturamentoTotal,
      'total_pedidos': totalPedidos,
      'ticket_medio': ticketMedio,
      'top_5_produtos': top5Produtos
          .map((e) => {'produto': e.key, 'quantidade': e.value})
          .toList(),
      'vendas_por_dia': vendasPorDia,
      'total_produtos_distintos': produtoQuantidade.length,
    };
  }
}

/// Parâmetros para o isolate via compute().
class _ParseParams {
  final String csvContent;
  final List<String> requiredColumns;

  _ParseParams(this.csvContent, this.requiredColumns);
}

/// Serviço responsável por ler e agregar dados do CSV.
class CsvParserService {
  /// Recebe o conteúdo raw do arquivo CSV (String) e retorna
  /// os dados agregados. Roda em isolate via compute() para não
  /// travar a UI.
  static Future<CsvAggregatedData> parseAndAggregate(String csvContent) async {
    return compute(
      _parseInIsolate,
      _ParseParams(csvContent, AppConfig.requiredCsvColumns),
    );
  }

  /// Função pura executada no isolate.
  static CsvAggregatedData _parseInIsolate(_ParseParams params) {
    final csvContent = params.csvContent;
    final requiredColumns = params.requiredColumns;

    // Converte CSV para lista de listas
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(csvContent);

    if (rows.isEmpty) {
      throw Exception('Arquivo CSV vazio.');
    }

    // Cabeçalho — normaliza para lowercase e sem espaços
    final header =
        rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

    // Valida colunas obrigatórias
    for (final col in requiredColumns) {
      if (!header.contains(col.toLowerCase())) {
        throw Exception(
            'Coluna obrigatória "$col" não encontrada. Colunas encontradas: ${header.join(", ")}');
      }
    }

    final idxProduto = header.indexOf('produto');
    final idxQuantidade = header.indexOf('quantidade');
    final idxPreco = header.indexOf('preco_unitario');
    final idxData = header.indexOf('data_venda');

    // Estruturas de agregação
    final Map<String, int> produtoQtd = {};
    final Map<String, double> produtoFat = {};
    final Map<String, double> vendasDia = {};
    double faturamentoTotal = 0;
    int totalPedidos = 0;

    // Itera pelas linhas de dados (pula o header)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length <= idxData) continue; // linha incompleta, pula

      final produto = row[idxProduto].toString().trim();
      if (produto.isEmpty) continue;

      final quantidade =
          int.tryParse(row[idxQuantidade].toString().trim()) ?? 0;
      final precoStr = row[idxPreco]
          .toString()
          .trim()
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final preco = double.tryParse(precoStr) ?? 0.0;

      final dataVenda = row[idxData].toString().trim();
      // Extrai apenas dd/MM (ou o que houver antes do ano)
      final dataLabel = _extrairDataLabel(dataVenda);

      final subtotal = quantidade * preco;

      faturamentoTotal += subtotal;
      totalPedidos++;

      produtoQtd[produto] = (produtoQtd[produto] ?? 0) + quantidade;
      produtoFat[produto] = (produtoFat[produto] ?? 0) + subtotal;
      vendasDia[dataLabel] = (vendasDia[dataLabel] ?? 0) + subtotal;
    }

    // Top 5 por quantidade
    final sorted = produtoQtd.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    final ticketMedio =
        totalPedidos > 0 ? faturamentoTotal / totalPedidos : 0.0;

    return CsvAggregatedData(
      faturamentoTotal: faturamentoTotal,
      totalPedidos: totalPedidos,
      ticketMedio: ticketMedio,
      produtoQuantidade: produtoQtd,
      produtoFaturamento: produtoFat,
      vendasPorDia: vendasDia,
      top5Produtos: top5,
    );
  }

  /// Tenta extrair um label de data curto (dd/MM) de vários formatos.
  static String _extrairDataLabel(String raw) {
    // Formatos comuns: "01/03/2024", "2024-03-01", "01-03-2024"
    if (raw.contains('/')) {
      final parts = raw.split('/');
      if (parts.length >= 2) return '${parts[0]}/${parts[1]}';
    } else if (raw.contains('-')) {
      final parts = raw.split('-');
      if (parts.length >= 3) {
        // Se começa com 4 dígitos, é yyyy-MM-dd
        if (parts[0].length == 4) {
          return '${parts[2]}/${parts[1]}';
        }
        return '${parts[0]}/${parts[1]}';
      }
    }
    return raw.length > 5 ? raw.substring(0, 5) : raw;
  }
}
