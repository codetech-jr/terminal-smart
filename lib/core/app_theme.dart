// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // === PALETA INSTITUCIONAL VENEZUELA ===

  // Azul "Gobierno": Un azul profundo, sobrio y tecnológico (Pantone 282 C aproximado)
  static const Color primaryBlue = Color(0xFF003875);

  // Amarillo "Riqueza": Menos chillón que el de la bandera, más dorado para que se lea el texto encima
  static const Color accentYellow = Color(0xFFFFC107); // Amber 500

  // Rojo "Fuerza": Para alertas y errores
  static const Color alertRed = Color(0xFFD32F2F);

  // Colores Neutros
  static const Color background =
      Color(0xFFF4F6F8); // Un gris azulado muy suave
  static const Color cardBackground = Colors.white;
  static const Color textDark = Color(0xFF1A233A); // Azul casi negro para texto
  static const Color textGrey = Color(0xFF6C757D);
}

class AppTheme {
  static ThemeData get governmentTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto', // La fuente estándar y legible por excelencia
      scaffoldBackgroundColor: AppColors.background,

      // Esquema de colores generado semánticamente
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentYellow,
        error: AppColors.alertRed,
        background: AppColors.background,
      ),

      // Estilo de tarjetas profesional
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                12)), // Bordes menos redondos = más serios
      ),

      // AppBar institucional
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
