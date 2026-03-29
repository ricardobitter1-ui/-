import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {

  // Cores Premium - Azul Royal e Superfícies Suaves
  static const Color primaryBlue = Color(0xFF0052FF);
  static const Color backgroundLight = Color(0xFFF8F9FF);
  static const Color cardSurface = Colors.white;
  static const Color darkSurface = Color(0xFF121212);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: cardSurface,
      ),
      useMaterial3: true,
      
      // Aplicando Inter como a tipografia global
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2B2D42), letterSpacing: -1.0),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2B2D42)),
        bodyMedium: TextStyle(color: Color(0xFF6C757D), fontSize: 16),
      )),

      // App Bar limpa, fundo invisível e icones escuros
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: Color(0xFF2B2D42),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF2B2D42),
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),

      // Botão flutuante super estilizado conforme Style Guide
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Campos de texto do tipo TextField padronizados e macios
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primaryBlue, width: 2.0),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

