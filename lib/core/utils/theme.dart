import 'package:escomevents_app/core/utils/paleta.dart';
import 'package:flutter/material.dart';

class AppTheme{
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.lightPrimary,
      secondary: AppColors.lightSecondary,
      tertiary: AppColors.lightAccent, // Útil para botones de "Me gusta" o alertas
      surface: AppColors.lightSurface,
    ),
    
    // Ejemplo de personalización de AppBar para el tema claro
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkPrimary,
      secondary: AppColors.darkSecondary, // El verde menta resaltará mucho aquí
      surface: AppColors.darkSurface,
      error: const Color(0xFFCF6679), // Color de error estándar para dark mode
    ),

    // Personalización de AppBar para modo oscuro (más sobrio)
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface, // O darkBackground para que se funda
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    
    // Personalización de Tarjetas en modo oscuro
    cardTheme: const CardThemeData(
      color: AppColors.darkSurface,
      elevation: 2,
    ),
  );
}
