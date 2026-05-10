// lib/features/dashboard/providers/csv_data_provider.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/csv_parser_service.dart';

/// Estados possíveis do fluxo de CSV.
enum CsvStatus { empty, loading, loaded, error }

class CsvDataState {
  final CsvStatus status;
  final CsvAggregatedData? data;
  final String? errorMessage;
  final String loadingMessage;

  const CsvDataState({
    this.status = CsvStatus.empty,
    this.data,
    this.errorMessage,
    this.loadingMessage = '',
  });

  CsvDataState copyWith({
    CsvStatus? status,
    CsvAggregatedData? data,
    String? errorMessage,
    String? loadingMessage,
  }) {
    return CsvDataState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}

class CsvDataNotifier extends StateNotifier<CsvDataState> {
  CsvDataNotifier() : super(const CsvDataState());

  /// Abre o file picker, valida o arquivo e processa o CSV.
  Future<void> pickAndProcessCsv() async {
    // 1. Seleciona o arquivo
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      // Usuário cancelou — não faz nada
      return;
    }

    final file = result.files.first;

    // 2. Valida tamanho (máx 2 MB)
    if ((file.size) > AppConfig.maxFileSizeBytes) {
      state = const CsvDataState(
        status: CsvStatus.error,
        errorMessage: AppStrings.errorFileTooLarge,
      );
      return;
    }

    // 3. Inicia loading com mensagens rotativas
    state = CsvDataState(
      status: CsvStatus.loading,
      loadingMessage: AppStrings.loadingMessages[0],
    );

    try {
      // Lê o conteúdo do arquivo como String
      String csvContent;
      if (file.bytes != null) {
        csvContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      } else {
        throw Exception(AppStrings.errorNoFile);
      }

      // Atualiza mensagem de loading
      state = state.copyWith(
        loadingMessage: AppStrings.loadingMessages[1],
      );

      // 4. Processa no isolate via compute()
      final aggregated = await CsvParserService.parseAndAggregate(csvContent);

      // 5. Atualiza estado com dados prontos
      state = CsvDataState(
        status: CsvStatus.loaded,
        data: aggregated,
      );
    } catch (e) {
      state = CsvDataState(
        status: CsvStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Limpa os dados e volta ao empty state.
  void reset() {
    state = const CsvDataState();
  }
}

/// Provider global dos dados do CSV.
final csvDataProvider =
    StateNotifierProvider<CsvDataNotifier, CsvDataState>((ref) {
  return CsvDataNotifier();
});
