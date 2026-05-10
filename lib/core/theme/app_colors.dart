// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

/// Paleta de cores inspirada no estilo Nubank — fundo limpo, destaque roxo.
class AppColors {
  AppColors._();

  // ── Fundos ──
  static const Color background = Color(0xFFF8F9FA); // cinza super claro
  static const Color surface = Color(0xFFFFFFFF);     // branco puro (cards)

  // ── Cor principal (Roxo — confiança / Nubank) ──
  static const Color primary = Color(0xFF6C3FEE);
  static const Color primaryLight = Color(0xFFEDE7FE);
  static const Color primaryDark = Color(0xFF4A1FCC);

  // ── Cor secundária (Verde — dinheiro / lucro) ──
  static const Color accent = Color(0xFF00C853);
  static const Color accentLight = Color(0xFFE8F5E9);

  // ── Texto ──
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // ── Utilitários ──
  static const Color divider = Color(0xFFE5E7EB);
  static const Color error = Color(0xFFEF4444);
  static const Color white = Color(0xFFFFFFFF);

  // ── Gradiente de destaque para gráficos ──
  static const List<Color> chartGradient = [
    Color(0xFF6C3FEE),
    Color(0xFF9F7AEA),
  ];
}
