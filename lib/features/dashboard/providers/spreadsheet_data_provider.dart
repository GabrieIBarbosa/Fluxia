// lib/features/dashboard/providers/spreadsheet_data_provider.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/ai_mapper_service.dart';
import '../../../core/services/excel_parser_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/providers/auth_provider.dart';

enum SpreadsheetStatus { empty, loading, loaded, error }

class ImportedSpreadsheet {
  final String id;
  final String name;
  final int size;
  final DateTime importedAt;
  final SpreadsheetAggregatedData summary;
  final bool selected;

  const ImportedSpreadsheet({
    required this.id,
    required this.name,
    required this.size,
    required this.importedAt,
    required this.summary,
    this.selected = false,
  });

  ImportedSpreadsheet copyWith({
    String? name,
    bool? selected,
    int? size,
    DateTime? importedAt,
    SpreadsheetAggregatedData? summary,
  }) {
    return ImportedSpreadsheet(
      id: id,
      name: name ?? this.name,
      size: size ?? this.size,
      importedAt: importedAt ?? this.importedAt,
      summary: summary ?? this.summary,
      selected: selected ?? this.selected,
    );
  }
}

class SpreadsheetDataState {
  final SpreadsheetStatus status;
  final SpreadsheetAggregatedData? activeData;
  final String? errorMessage;
  final String loadingMessage;
  final List<ImportedSpreadsheet> spreadsheets;
  final String? activeSpreadsheetId;

  const SpreadsheetDataState({
    this.status = SpreadsheetStatus.empty,
    this.activeData,
    this.errorMessage,
    this.loadingMessage = '',
    this.spreadsheets = const [],
    this.activeSpreadsheetId,
  });

  int get selectedCount => spreadsheets.where((sheet) => sheet.selected).length;

  bool get hasSpreadsheets => spreadsheets.isNotEmpty;
}

class SpreadsheetDataNotifier extends StateNotifier<SpreadsheetDataState> {
  final String? uid;

  SpreadsheetDataNotifier({required this.uid})
      : super(const SpreadsheetDataState()) {
    if (uid != null) {
      loadFromFirestore();
    }
  }

  Future<void> loadFromFirestore() async {
    if (uid == null) return;

    state = const SpreadsheetDataState(
      status: SpreadsheetStatus.loading,
      loadingMessage: 'Carregando planilhas da nuvem...',
    );

    try {
      final docs = await FirestoreService.getPlanilhas(uid!);

      final spreadsheets = docs.map((map) {
        final id = map['id'].toString();
        final importedAtTs = map['processada_em'] as Timestamp?;
        final dataInicioTs = map['data_inicio'] as Timestamp?;
        final dataFimTs = map['data_fim'] as Timestamp?;

        final normalizedMap = Map<String, dynamic>.from(map)
          ..['data_inicio'] = dataInicioTs?.toDate()
          ..['data_fim'] = dataFimTs?.toDate();

        return ImportedSpreadsheet(
          id: id,
          name: (map['nome'] ?? 'Planilha').toString(),
          size: ((map['tamanho'] ?? 0) as num).toInt(),
          importedAt: importedAtTs?.toDate() ?? DateTime.now(),
          selected: false,
          summary: SpreadsheetAggregatedData.fromFirestoreMap(normalizedMap),
        );
      }).toList();

      if (spreadsheets.isEmpty) {
        state = const SpreadsheetDataState(status: SpreadsheetStatus.empty);
        return;
      }

      state = _stateFromSpreadsheets(
        _selectOnly(spreadsheets, spreadsheets.first.id),
      );
    } catch (e) {
      state = SpreadsheetDataState(
        status: SpreadsheetStatus.error,
        errorMessage: 'Erro ao carregar dados: ${e.toString()}',
      );
    }
  }

  Future<void> pickAndProcessSpreadsheet() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final existingSignatures = state.spreadsheets
        .map((sheet) => '${sheet.name}_${sheet.size}')
        .toSet();

    final incomingSignatures = <String>{};

    for (final file in result.files) {
      final signature = '${file.name}_${file.size}';
      if (existingSignatures.contains(signature) ||
          incomingSignatures.contains(signature)) {
        state = SpreadsheetDataState(
          status: SpreadsheetStatus.error,
          errorMessage:
              '"${file.name}" já foi importada anteriormente. Renomeie ou exclua a existente.',
          spreadsheets: state.spreadsheets,
          activeSpreadsheetId: state.activeSpreadsheetId,
          activeData: state.activeData,
        );
        return;
      }
      incomingSignatures.add(signature);
    }

    final imported = <ImportedSpreadsheet>[];
    final oldSheets = state.spreadsheets;

    try {
      for (final file in result.files) {
        if (file.size > AppConfig.maxFileSizeBytes) {
          throw Exception('${file.name}: ${AppStrings.errorFileTooLarge}');
        }

        state = SpreadsheetDataState(
          status: SpreadsheetStatus.loading,
          loadingMessage: 'Processando ${file.name}...',
          spreadsheets: [...imported, ...oldSheets],
          activeSpreadsheetId: state.activeSpreadsheetId,
          activeData: state.activeData,
        );

        final bytes = await _readFileBytes(file);

        state = SpreadsheetDataState(
          status: SpreadsheetStatus.loading,
          loadingMessage: 'Identificando colunas com IA...',
          spreadsheets: [...imported, ...oldSheets],
          activeSpreadsheetId: state.activeSpreadsheetId,
          activeData: state.activeData,
        );

        final sample = ExcelParserService.extractSampleRows(bytes);
        final rawHeaders = sample['headers'] as List<String>? ?? [];
        final rawRows = sample['rows'] as List<List<String>>? ?? [];

        Map<String, String>? aiMap;
        if (rawHeaders.isNotEmpty) {
          aiMap = await AiMapperService.suggestColumnMapping(rawHeaders, rawRows);
        }

        state = SpreadsheetDataState(
          status: SpreadsheetStatus.loading,
          loadingMessage: 'Processando ${file.name}...',
          spreadsheets: [...imported, ...oldSheets],
          activeSpreadsheetId: state.activeSpreadsheetId,
          activeData: state.activeData,
        );

        final summary = ExcelParserService.parseAndAggregate(bytes, aiMap);

        if (uid == null) {
          final localId =
              '${DateTime.now().microsecondsSinceEpoch}_${file.name}';
          imported.add(
            ImportedSpreadsheet(
              id: localId,
              name: file.name,
              size: file.size,
              importedAt: DateTime.now(),
              summary: summary,
              selected: imported.isEmpty,
            ),
          );
        } else {
          final planilhaId = await FirestoreService.saveExcelSummary(
            uid!,
            nome: file.name,
            tamanho: file.size,
            summary: summary,
          );

          await FirestoreService.saveSalesRecords(
              uid!, planilhaId, summary.records);

          imported.add(
            ImportedSpreadsheet(
              id: planilhaId,
              name: file.name,
              size: file.size,
              importedAt: DateTime.now(),
              summary: summary,
              selected: imported.isEmpty,
            ),
          );
        }
      }

      final combined = [...imported, ...oldSheets];
      state = _stateFromSpreadsheets(combined);
    } catch (e) {
      state = SpreadsheetDataState(
        status: SpreadsheetStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        spreadsheets: state.spreadsheets,
        activeSpreadsheetId: state.activeSpreadsheetId,
        activeData: state.activeData,
      );
    }
  }

  void setSpreadsheetSelected(String id, bool selected) {
    final spreadsheets = state.spreadsheets.map((sheet) {
      if (sheet.id != id) return sheet;
      return sheet.copyWith(selected: selected);
    }).toList();

    state = _stateFromSpreadsheets(spreadsheets);
  }

  Future<void> updateSpreadsheet(String id) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.size > AppConfig.maxFileSizeBytes) {
      state = SpreadsheetDataState(
        status: SpreadsheetStatus.error,
        errorMessage: '${file.name}: ${AppStrings.errorFileTooLarge}',
        spreadsheets: state.spreadsheets,
        activeSpreadsheetId: state.activeSpreadsheetId,
        activeData: state.activeData,
      );
      return;
    }

    try {
      state = SpreadsheetDataState(
        status: SpreadsheetStatus.loading,
        loadingMessage: 'Atualizando ${file.name}...',
        spreadsheets: state.spreadsheets,
        activeSpreadsheetId: state.activeSpreadsheetId,
        activeData: state.activeData,
      );

      final bytes = await _readFileBytes(file);

      state = SpreadsheetDataState(
        status: SpreadsheetStatus.loading,
        loadingMessage: 'Identificando colunas com IA...',
        spreadsheets: state.spreadsheets,
        activeSpreadsheetId: state.activeSpreadsheetId,
        activeData: state.activeData,
      );

      final sample = ExcelParserService.extractSampleRows(bytes);
      final rawHeaders = sample['headers'] as List<String>? ?? [];
      final rawRows = sample['rows'] as List<List<String>>? ?? [];

      Map<String, String>? aiMap;
      if (rawHeaders.isNotEmpty) {
        aiMap = await AiMapperService.suggestColumnMapping(rawHeaders, rawRows);
      }

      state = SpreadsheetDataState(
        status: SpreadsheetStatus.loading,
        loadingMessage: 'Processando ${file.name}...',
        spreadsheets: state.spreadsheets,
        activeSpreadsheetId: state.activeSpreadsheetId,
        activeData: state.activeData,
      );

      final summary = ExcelParserService.parseAndAggregate(bytes, aiMap);

      if (uid != null) {
        await FirestoreService.updateExcelSummary(
          uid!,
          id,
          nome: file.name,
          tamanho: file.size,
          summary: summary,
        );

        await FirestoreService.replaceSalesRecords(uid!, id, summary.records);
      }

      final spreadsheets = state.spreadsheets.map((sheet) {
        if (sheet.id != id) return sheet;
        return sheet.copyWith(
          name: file.name,
          size: file.size,
          importedAt: DateTime.now(),
          summary: summary,
        );
      }).toList();

      state = _stateFromSpreadsheets(spreadsheets);
    } catch (e) {
      state = SpreadsheetDataState(
        status: SpreadsheetStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        spreadsheets: state.spreadsheets,
        activeSpreadsheetId: state.activeSpreadsheetId,
        activeData: state.activeData,
      );
    }
  }

  Future<void> removeSpreadsheet(String id) async {
    final target = state.spreadsheets.where((e) => e.id == id).toList();
    if (target.isEmpty) return;

    final remaining = state.spreadsheets.where((e) => e.id != id).toList();

    if (remaining.isEmpty) {
      state = const SpreadsheetDataState(status: SpreadsheetStatus.empty);
    } else {
      state = _stateFromSpreadsheets(remaining);
    }

    if (uid != null) {
      try {
        await FirestoreService.deletePlanilha(uid!, id);
      } catch (e) {
        // Ignorar erro no UI, mas manter fallback se precisar
      }
    }
  }

  Future<void> renameSpreadsheet(String id, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) return;

    final spreadsheets = state.spreadsheets.map((sheet) {
      if (sheet.id != id) return sheet;
      return sheet.copyWith(name: trimmedName);
    }).toList();

    state = _stateFromSpreadsheets(spreadsheets);

    if (uid != null) {
      try {
        await FirestoreService.renamePlanilha(uid!, id, trimmedName);
      } catch (e) {
        state = SpreadsheetDataState(
          status: SpreadsheetStatus.error,
          errorMessage:
              'Erro ao renomear planilha: ${e.toString().replaceFirst('Exception: ', '')}',
          spreadsheets: state.spreadsheets,
          activeSpreadsheetId: state.activeSpreadsheetId,
          activeData: state.activeData,
        );
      }
    }
  }

  void reset() {
    state = const SpreadsheetDataState();
  }

  SpreadsheetDataState _stateFromSpreadsheets(
    List<ImportedSpreadsheet> spreadsheets,
  ) {
    final selected = spreadsheets.where((sheet) => sheet.selected).toList();

    final activeData = selected.isEmpty ? null : _combineSummaries(selected);

    return SpreadsheetDataState(
      status: spreadsheets.isEmpty
          ? SpreadsheetStatus.empty
          : SpreadsheetStatus.loaded,
      spreadsheets: spreadsheets,
      activeSpreadsheetId: selected.isEmpty ? null : selected.first.id,
      activeData: activeData,
    );
  }



  SpreadsheetAggregatedData _combineSummaries(
    List<ImportedSpreadsheet> selected,
  ) {
    int pedidosCompleted = 0;
    int pedidosDevolucao = 0;
    double faturamentoTotal = 0;
    double lucroTotal = 0;

    DateTime? dataInicio;
    DateTime? dataFim;

    final produtoQtd = <String, int>{};
    final produtoFat = <String, double>{};
    final anuncioQtd = <String, int>{};
    final anuncioFat = <String, double>{};

    for (final sheet in selected) {
      final summary = sheet.summary;
      pedidosCompleted += summary.pedidosCompleted;
      pedidosDevolucao += summary.pedidosDevolucao;
      faturamentoTotal += summary.faturamentoTotal;
      lucroTotal += summary.lucroTotal;

      if (summary.dataInicio != null) {
        dataInicio =
            dataInicio == null || summary.dataInicio!.isBefore(dataInicio)
                ? summary.dataInicio
                : dataInicio;
      }
      if (summary.dataFim != null) {
        dataFim = dataFim == null || summary.dataFim!.isAfter(dataFim)
            ? summary.dataFim
            : dataFim;
      }

      for (final entry in summary.top10Produtos) {
        produtoQtd[entry.key] = (produtoQtd[entry.key] ?? 0) + entry.value;
      }
      for (final entry in summary.top10ProdutosReceita) {
        produtoFat[entry.key] = (produtoFat[entry.key] ?? 0) + entry.value;
      }
      for (final entry in summary.top10Anuncios) {
        anuncioQtd[entry.key] = (anuncioQtd[entry.key] ?? 0) + entry.value;
      }
      for (final entry in summary.top10AnunciosReceita) {
        anuncioFat[entry.key] = (anuncioFat[entry.key] ?? 0) + entry.value;
      }
    }

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
      dataInicio: dataInicio,
      dataFim: dataFim,
      records: const [],
    );
  }

  Future<Uint8List> _readFileBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    if (file.path != null) {
      return File(file.path!).readAsBytes();
    }
    throw Exception(AppStrings.errorNoFile);
  }
}

final spreadsheetDataProvider =
    StateNotifierProvider<SpreadsheetDataNotifier, SpreadsheetDataState>((ref) {
  final authState = ref.watch(authProvider);
  return SpreadsheetDataNotifier(uid: authState.user?.uid);
});
