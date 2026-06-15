import 'package:flutter/material.dart';

/// Eximium Design System — color tokens.
///
/// Espelha `tokens/colors.css`.
///
/// - Campos de **instância** (superfícies/texto/borda/sombras) variam entre
///   dark (padrão) e light. Acesse via `context.ex`.
/// - Constantes **estáticas de marca** são invariantes entre temas e podem
///   ser usadas diretamente (verde, lavanda, status).
@immutable
class ExColors extends ThemeExtension<ExColors> {
  const ExColors({
    required this.brightness,
    required this.surface0,
    required this.surface1,
    required this.surface2,
    required this.surface3,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textAccent,
    required this.border,
    required this.borderAccent,
    required this.shadowCard,
    required this.shadowFloat,
    required this.successText,
    required this.infoText,
    required this.errorText,
    required this.warningText,
  });

  final Brightness brightness;

  // ── Superfícies ──
  final Color surface0;
  final Color surface1;
  final Color surface2;
  final Color surface3;

  // ── Texto ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textAccent;

  // ── Bordas ──
  final Color border;
  final Color borderAccent;

  // ── Sombras (variam por tema) ──
  final List<BoxShadow> shadowCard;
  final List<BoxShadow> shadowFloat;

  // ── Texto de status (varia por tema, p/ legibilidade) ──
  final Color successText;
  final Color infoText;
  final Color errorText;
  final Color warningText;

  // ─────────────────────────────────────────────────────────────
  // Constantes de marca — INVARIANTES entre temas.
  // ─────────────────────────────────────────────────────────────

  /// Acento primário — CTAs, bordas ativas, ícones, waveforms.
  static const Color brandGreen = Color(0xFF6DE2C0);

  /// Hover / glow suave.
  static const Color brandGreenLt = Color(0xFFAEF7E4);

  /// Gradiente profundo / áreas de acento escuro.
  static const Color brandGreenDk = Color(0xFF014751);

  /// Texto verde sobre fundo claro (WCAG AA).
  static const Color brandGreenTxt = Color(0xFF1A9E85);

  /// Secundário / informativo (uso comedido).
  static const Color lavender = Color(0xFF7C82D6);

  /// Texto/ícone sobre preenchimento verde.
  static const Color onBrandGreen = Color(0xFF04201A);

  // ── Cores de status (fundo invariante) ──
  static const Color success = Color(0xFF6DE2C0);
  static const Color info = Color(0xFF7C82D6);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFC457);

  static const Color successBg = Color(0x1F6DE2C0); // 12%
  static const Color infoBg = Color(0x1F7C82D6); // 12%
  static const Color errorBg = Color(0x1FFF6B6B); // 12%
  static const Color warningBg = Color(0x1FFFC457); // 12%

  /// Gradiente de marca (135deg).
  static const LinearGradient gradientBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGreenDk, brandGreen],
  );

  // ─────────────────────────────────────────────────────────────
  // Temas
  // ─────────────────────────────────────────────────────────────

  static const ExColors dark = ExColors(
    brightness: Brightness.dark,
    surface0: Color(0xFF0A0A0A),
    surface1: Color(0xFF141414),
    surface2: Color(0xFF1E1E1E),
    surface3: Color(0xFF2A2A2A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF999999),
    textMuted: Color(0xFF666666),
    textAccent: Color(0xFF6DE2C0),
    border: Color(0xFF2A2A2A),
    borderAccent: Color(0x406DE2C0), // rgba(109,226,192,.25)
    shadowCard: [
      BoxShadow(
        color: Color(0x66000000), // rgba(0,0,0,.40)
        blurRadius: 12,
        offset: Offset(0, 2),
      ),
    ],
    shadowFloat: [
      BoxShadow(
        color: Color(0x99000000), // rgba(0,0,0,.60)
        blurRadius: 32,
        offset: Offset(0, 8),
      ),
    ],
    successText: Color(0xFF6DE2C0),
    infoText: Color(0xFF7C82D6),
    errorText: Color(0xFFFF6B6B),
    warningText: Color(0xFFFFC457),
  );

  static const ExColors light = ExColors(
    brightness: Brightness.light,
    surface0: Color(0xFFF9F9F9),
    surface1: Color(0xFFFFFFFF),
    surface2: Color(0xFFF3F3F3),
    surface3: Color(0xFFE8E8E8),
    textPrimary: Color(0xFF111111),
    textSecondary: Color(0xFF555555),
    textMuted: Color(0xFF999999),
    textAccent: Color(0xFF1A9E85),
    border: Color(0xFFE5E5E5),
    borderAccent: Color(0x996DE2C0), // rgba(109,226,192,.60)
    shadowCard: [
      BoxShadow(
        color: Color(0x14000000), // rgba(0,0,0,.08)
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x0F000000), // rgba(0,0,0,.06)
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
    shadowFloat: [
      BoxShadow(
        color: Color(0x26000000), // rgba(0,0,0,.15)
        blurRadius: 32,
        offset: Offset(0, 8),
      ),
    ],
    successText: Color(0xFF1A9E85),
    infoText: Color(0xFF5C63B8),
    errorText: Color(0xFFCC4444),
    warningText: Color(0xFFA06010),
  );

  @override
  ExColors copyWith({
    Brightness? brightness,
    Color? surface0,
    Color? surface1,
    Color? surface2,
    Color? surface3,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textAccent,
    Color? border,
    Color? borderAccent,
    List<BoxShadow>? shadowCard,
    List<BoxShadow>? shadowFloat,
    Color? successText,
    Color? infoText,
    Color? errorText,
    Color? warningText,
  }) {
    return ExColors(
      brightness: brightness ?? this.brightness,
      surface0: surface0 ?? this.surface0,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textAccent: textAccent ?? this.textAccent,
      border: border ?? this.border,
      borderAccent: borderAccent ?? this.borderAccent,
      shadowCard: shadowCard ?? this.shadowCard,
      shadowFloat: shadowFloat ?? this.shadowFloat,
      successText: successText ?? this.successText,
      infoText: infoText ?? this.infoText,
      errorText: errorText ?? this.errorText,
      warningText: warningText ?? this.warningText,
    );
  }

  @override
  ExColors lerp(covariant ThemeExtension<ExColors>? other, double t) {
    if (other is! ExColors) return this;
    return ExColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      surface0: Color.lerp(surface0, other.surface0, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textAccent: Color.lerp(textAccent, other.textAccent, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderAccent: Color.lerp(borderAccent, other.borderAccent, t)!,
      shadowCard: BoxShadow.lerpList(shadowCard, other.shadowCard, t) ??
          shadowCard,
      shadowFloat: BoxShadow.lerpList(shadowFloat, other.shadowFloat, t) ??
          shadowFloat,
      successText: Color.lerp(successText, other.successText, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
    );
  }
}

/// Helper de acesso aos tokens de cor do tema atual.
///
/// ```dart
/// final c = context.ex;
/// color: c.textPrimary,
/// ```
extension ExColorsX on BuildContext {
  ExColors get ex => Theme.of(this).extension<ExColors>() ?? ExColors.dark;
}
