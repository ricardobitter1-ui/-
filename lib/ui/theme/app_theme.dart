import 'package:flutter/material.dart';

import 'eximium_colors.dart';
import 'eximium_spacing.dart';
import 'eximium_typography.dart';

/// Tema do app no Eximium Design System (Material3, dark padrão + light).
///
/// As telas devem consumir cores via `context.ex` (ExColors). Os membros
/// estáticos abaixo são **aliases de compatibilidade** mantidos para não
/// quebrar imports durante a migração (fase 2). Prefira migrar os call-sites.
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────
  // Aliases de compatibilidade (deprecados — migrar gradualmente).
  // ─────────────────────────────────────────────────────────────

  /// Acento de marca. Agora aponta para o verde do DS.
  static const Color brandPrimary = ExColors.brandGreen;

  /// Secundário (gradientes/avatares) — lavanda do DS.
  static const Color brandSecondary = ExColors.lavender;

  /// Indicadores de conclusão — verde do DS.
  static const Color successCyan = ExColors.brandGreen;

  /// Fundo de janela (aponta para tokens **dark** por compat).
  static Color get backgroundLight => ExColors.dark.surface0;

  /// Superfície de card (aponta para tokens **dark** por compat).
  static Color get cardSurface => ExColors.dark.surface1;

  /// Superfície escura legada.
  static Color get darkSurface => ExColors.dark.surface1;

  // ─────────────────────────────────────────────────────────────
  // Temas
  // ─────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => _buildTheme(ExColors.dark);

  static ThemeData get lightTheme => _buildTheme(ExColors.light);

  static ThemeData _buildTheme(ExColors ex) {
    final bool isDark = ex.brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: ex.brightness,
      primary: ExColors.brandGreen,
      onPrimary: ExColors.onBrandGreen,
      secondary: ExColors.lavender,
      onSecondary: Colors.white,
      error: ExColors.error,
      onError: Colors.white,
      surface: ex.surface1,
      onSurface: ex.textPrimary,
      surfaceContainerHighest: ex.surface2,
      outline: ex.border,
    );

    final textTheme = ExText.textThemeFor(ex.brightness).apply(
      bodyColor: ex.textPrimary,
      displayColor: ex.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: ex.brightness,
      scaffoldBackgroundColor: ex.surface0,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[ex],
      splashFactory: NoSplash.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ex.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: ExText.h1(ex.textPrimary),
        iconTheme: IconThemeData(color: ex.textPrimary),
      ),
      iconTheme: IconThemeData(color: ex.textPrimary),
      dividerTheme: DividerThemeData(
        color: ex.border,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ExColors.brandGreen,
        foregroundColor: ExColors.onBrandGreen,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ExRadius.lg)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ex.surface2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ExSpace.s4,
          vertical: ExSpace.s4,
        ),
        hintStyle: ExText.bodyLg(ex.textMuted),
        labelStyle: ExText.body(ex.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExRadius.md),
          borderSide: BorderSide(color: ex.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExRadius.md),
          borderSide: BorderSide(color: ex.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExRadius.md),
          borderSide: const BorderSide(color: ExColors.brandGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExRadius.md),
          borderSide: const BorderSide(color: ExColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ExColors.brandGreen,
          foregroundColor: ExColors.onBrandGreen,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: ExSpace.s5,
            vertical: ExSpace.s4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExRadius.pill),
          ),
          textStyle: ExText.h3(ExColors.onBrandGreen),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ex.textAccent,
          textStyle: ExText.h3(ex.textAccent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ex.textPrimary,
          side: BorderSide(color: ex.border),
          padding: const EdgeInsets.symmetric(
            horizontal: ExSpace.s5,
            vertical: ExSpace.s4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExRadius.pill),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: ex.surface1,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExRadius.lg),
          side: BorderSide(color: ex.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ex.surface1,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExRadius.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ex.surface1,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ExRadius.xl),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ExColors.onBrandGreen;
          }
          return isDark ? ex.textMuted : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return ExColors.brandGreen;
          }
          return ex.surface3;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
