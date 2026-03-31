import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  /// Cor de marca (lavanda profunda, alinhada aos quadrantes pastel — substitui o azul saturado).
  static const Color brandPrimary = Color(0xFF5F6FCE);

  /// Roxo suave para gradientes com [brandPrimary] (presets de grupo / avatares).
  static const Color brandSecondary = Color(0xFF9B8AD4);

  /// Success Cyan — indicadores de conclusão (style guide).
  static const Color successCyan = Color(0xFF00F5D4);

  static const Color backgroundLight = Color(0xFFF8F9FF);
  static const Color cardSurface = Colors.white;
  static const Color darkSurface = Color(0xFF121212);

  static const Color _titleColor = Color(0xFF2B2D42);
  static const Color _mutedForeground = Color(0xFF6C757D);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandPrimary,
      primary: brandPrimary,
      surface: cardSurface,
    ).copyWith(surfaceTint: Colors.transparent);

    final textTheme = GoogleFonts.nunitoTextTheme(
      const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: _titleColor,
          letterSpacing: -1.0,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: _titleColor,
        ),
        bodyMedium: TextStyle(
          color: _mutedForeground,
          fontSize: 16,
        ),
      ),
    );

    final navLabelSelected = GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: brandPrimary,
    );
    final navLabelDefault = GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _mutedForeground,
    );

    return ThemeData(
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: _titleColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          color: _titleColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          borderSide: const BorderSide(color: brandPrimary, width: 2.0),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.07),
        height: 72,
        indicatorColor: brandPrimary.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return navLabelSelected;
          }
          return navLabelDefault;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: brandPrimary, size: 24);
          }
          return IconThemeData(
            color: _mutedForeground.withValues(alpha: 0.88),
            size: 24,
          );
        }),
      ),
    );
  }
}
