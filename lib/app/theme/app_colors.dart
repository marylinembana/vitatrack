import 'package:flutter/material.dart';

/// Couleurs de VitaTrack.
class AppColors {
  AppColors._();

  // Marque
  static const Color primary = Color(0xFF2E7D5B); // vert nutrition
  static const Color primaryDark = Color(0xFF1B5E41);
  static const Color primaryLight = Color(0xFF6FBF9A);
  static const Color accent = Color(0xFFF2A03D); // orange énergie

  // Fond & surfaces
  static const Color background = Color(0xFFF6F8F6);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Texte
  static const Color textPrimary = Color(0xFF1D2C24);
  static const Color textSecondary = Color(0xFF62705F);
  static const Color textHint = Color(0xFF9AA79B);

  // Semi-opaque
  static const Color primarySoft = Color(0xFFE3F2EA);
  static const Color accentSoft = Color(0xFFFDF0DE);

  // Séparateurs / contours
  static const Color divider = Color(0xFFE3E8E3);
  static const Color outline = Color(0xFFCBD5CB);

  // Macros
  static const Color calories = Color(0xFFF2A03D);
  static const Color proteins = Color(0xFF3F7FBF);
  static const Color carbs = Color(0xFFC9A227);
  static const Color fats = Color(0xFFB85C79);

  // Sémantique
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE9A23B);
  static const Color error = Color(0xFFCF4A4A);
  static const Color info = Color(0xFF3F7FBF);

  // Graphiques
  static const Color chartLine = primary;
  static const Color chartFill = Color(0x332E7D5B);
}
