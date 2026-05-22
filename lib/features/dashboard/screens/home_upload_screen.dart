// lib/features/dashboard/screens/home_upload_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/spreadsheet_data_provider.dart';

class HomeUploadScreen extends ConsumerStatefulWidget {
  const HomeUploadScreen({super.key});

  @override
  ConsumerState<HomeUploadScreen> createState() => _HomeUploadScreenState();
}

class _HomeUploadScreenState extends ConsumerState<HomeUploadScreen> {
  Timer? _messageTimer;
  int _loadingMessageIndex = 0;

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _syncLoadingTimer(SpreadsheetStatus status) {
    if (status == SpreadsheetStatus.loading && _messageTimer == null) {
      _messageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted) return;
        setState(() {
          _loadingMessageIndex =
              (_loadingMessageIndex + 1) % AppStrings.loadingMessages.length;
        });
      });
    }

    if (status != SpreadsheetStatus.loading && _messageTimer != null) {
      _messageTimer?.cancel();
      _messageTimer = null;
      _loadingMessageIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spreadsheetState = ref.watch(spreadsheetDataProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final userName = _userGreetingName(authState);
    _syncLoadingTimer(spreadsheetState.status);

    return SafeArea(
      top: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(26, 10, 26, 24),
        children: [
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(text: 'Olá, '),
                TextSpan(
                  text: '$userName!',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'O que vamos analisar hoje?',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 42),
          _buildUploadButton(spreadsheetState),
          const SizedBox(height: 24),
          Text(
            spreadsheetState.status == SpreadsheetStatus.loading
                ? AppStrings.loadingMessages[_loadingMessageIndex]
                : 'Toque para importar um relatório XLSX\nMercado Livre ou Shopee • Até 8MB',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildSpreadsheetPanel(theme, spreadsheetState),
        ],
      ),
    );
  }

  String _userGreetingName(AuthState authState) {
    final savedName = authState.userName?.trim();
    if (savedName != null && savedName.isNotEmpty) return savedName;

    final displayName = authState.user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final email = authState.user?.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;

    return 'Usuário';
  }

  Widget _buildUploadButton(SpreadsheetDataState spreadsheetState) {
    final isLoading = spreadsheetState.status == SpreadsheetStatus.loading;

    return Center(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () => ref
                .read(spreadsheetDataProvider.notifier)
                .pickAndProcessSpreadsheet(),
        child: Container(
          width: 126,
          height: 126,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.secundaria, Color(0xFF2B76FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secundaria.withOpacity(0.42),
                blurRadius: 54,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.upload_file_rounded,
                color: AppColors.white,
                size: 34,
              ),
              const SizedBox(height: 9),
              const Text(
                'XLSX',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpreadsheetPanel(
    ThemeData theme,
    SpreadsheetDataState spreadsheetState,
  ) {
    final items = spreadsheetState.spreadsheets;
    const double tileHeight = 82;
    const double headerHeight = 56;
    const double panelPadding = 36;
    const double maxListHeight = tileHeight * 3.5;

    return Container(
      constraints: BoxConstraints(
        minHeight: 160,
        maxHeight: items.isEmpty
            ? double.infinity
            : headerHeight + panelPadding + maxListHeight,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Minhas Planilhas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} arquivos',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            _buildEmptyList(theme)
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: items.length,
                itemBuilder: (context, index) => _SpreadsheetTile(items[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyList(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        'Nenhuma planilha importada ainda.',
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SpreadsheetTile extends ConsumerWidget {
  final ImportedSpreadsheet spreadsheet;

  const _SpreadsheetTile(this.spreadsheet);

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: spreadsheet.name.replaceAll('.xlsx', ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Renomear planilha',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Novo nome',
            hintStyle: const TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final finalName =
                    newName.endsWith('.xlsx') ? newName : '$newName.xlsx';
                ref
                    .read(spreadsheetDataProvider.notifier)
                    .renameSpreadsheet(spreadsheet.id, finalName);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => ref
          .read(spreadsheetDataProvider.notifier)
          .setSpreadsheetSelected(spreadsheet.id, !spreadsheet.selected),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: spreadsheet.selected
              ? AppColors.primaryLight
              : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: spreadsheet.selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'XLSX',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onLongPress: () => _showRenameDialog(context, ref),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spreadsheet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_formatSize(spreadsheet.size)} • ${_formatDate(spreadsheet.importedAt)}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Renomear',
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.textSecondary,
              onPressed: () => _showRenameDialog(context, ref),
            ),
            IconButton(
              tooltip: 'Reimportar',
              icon: const Icon(Icons.refresh_rounded),
              color: AppColors.primary,
              onPressed: () => ref
                  .read(spreadsheetDataProvider.notifier)
                  .updateSpreadsheet(spreadsheet.id),
            ),
            IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.error,
              onPressed: () => ref
                  .read(spreadsheetDataProvider.notifier)
                  .removeSpreadsheet(spreadsheet.id),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
