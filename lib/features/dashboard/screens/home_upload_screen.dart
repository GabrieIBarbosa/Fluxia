// lib/features/dashboard/screens/home_upload_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/csv_data_provider.dart';
import 'dashboard_screen.dart';

/// Tela inicial — Empty State com botão "Importar Planilha" e Loading State.
class HomeUploadScreen extends ConsumerStatefulWidget {
  const HomeUploadScreen({super.key});

  @override
  ConsumerState<HomeUploadScreen> createState() => _HomeUploadScreenState();
}

class _HomeUploadScreenState extends ConsumerState<HomeUploadScreen> {
  int _loadingMessageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final csvState = ref.watch(csvDataProvider);
    final theme = Theme.of(context);

    // Navega ao dashboard quando os dados estão prontos
    ref.listen<CsvDataState>(csvDataProvider, (prev, next) {
      if (next.status == CsvStatus.loaded) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
      if (next.status == CsvStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appName, style: theme.appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: csvState.status == CsvStatus.loading
              ? _buildLoadingState(theme, csvState)
              : _buildEmptyState(theme),
        ),
      ),
    );
  }

  // ── Empty State ──
  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustração simples — ícone grande
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.insert_chart_outlined_rounded,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            AppStrings.emptyStateTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            AppStrings.emptyStateSubtitle,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Botão CTA — "Importar Planilha"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(csvDataProvider.notifier).pickAndProcessCsv();
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text(AppStrings.importButton),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading State com mensagens rotativas ──
  Widget _buildLoadingState(ThemeData theme, CsvDataState csvState) {
    // Roda as mensagens a cada 2s
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && csvState.status == CsvStatus.loading) {
        setState(() {
          _loadingMessageIndex =
              (_loadingMessageIndex + 1) % AppStrings.loadingMessages.length;
        });
      }
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            AppStrings.loadingMessages[_loadingMessageIndex],
            key: ValueKey(_loadingMessageIndex),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
