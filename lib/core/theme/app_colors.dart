import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color principal = Color(0xFF070A13);
  static const Color secundaria = Color(0xFF2F6BFF);
  static const Color terciaria = Color(0xFF121625);
  static const Color quaternaria = Color(0xFF1A2033);
  static const Color ciano = Color(0xFF11C6D9);
  static const Color amarelo = Color(0xFFF5AA18);
  static const Color textoPrimaria = Color(0xFFF7FAFF);
  static const Color textoSecundaria = Color(0xFF8A94AD);
  static const Color brilho = Color(0xFF1237D8);

  static const Color background = principal;
  static const Color surface = terciaria;
  static const Color primary = secundaria;
  static const Color primaryLight = Color(0xFF202C55);
  static const Color accent = ciano;

  static const Color textPrimary = textoPrimaria;
  static const Color textSecondary = textoSecundaria;
  static const Color textHint = Color(0xFF5E6880);

  static const Color divider = Color(0xFF252B3D);
  static const Color error = Color(0xFFFF4D6D);
  static const Color white = Color(0xFFFFFFFF);

  static const List<Color> chartGradient = [
    secundaria,
    ciano,
  ];
}
