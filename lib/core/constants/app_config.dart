// lib/core/constants/app_config.dart

/// Configurações globais do aplicativo.
class AppConfig {
  AppConfig._();

  // ── Backend ──
  /// URL base do FastAPI.
  /// Em desenvolvimento local, aponte para o IP da máquina (não use localhost
  /// se estiver no emulador Android — use 10.0.2.2).
  static const String backendBaseUrl = 'http://10.0.2.2:8000';

  // ── Limites do MVP ──
  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2 MB
  static const int questionsPerAdWatch = 3;
  static const int initialFreeQuestions = 3;

  // ── AdMob ──
  /// IDs de teste do Google AdMob (substituir por IDs reais em produção).
  /// Documentação: https://developers.google.com/admob/flutter/test-ads
  static const String adMobAndroidRewardedId =
      'ca-app-pub-3940256099942544/5224354917'; // teste
  static const String adMobIosRewardedId =
      'ca-app-pub-3940256099942544/1712485313'; // teste

  // ── CSV — colunas esperadas ──
  /// O CSV precisa ter pelo menos essas colunas (case-insensitive).
  static const List<String> requiredCsvColumns = [
    'produto',
    'quantidade',
    'preco_unitario',
    'data_venda',
  ];
}
