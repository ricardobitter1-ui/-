import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Eximium Design System — typography tokens.
///
/// Família UI: Red Hat Display. Mono (horários/contagens/timestamps):
/// Red Hat Mono. Espelha `tokens/typography.css`.
///
/// Todas as cores são recebidas por parâmetro; quando omitidas, herdam do
/// contexto via [TextStyle] sem cor explícita.
class ExText {
  ExText._();

  static const double _trackingTight = -0.02 * 28; // ~ -0.02em base display
  static const double _trackingLabel = 0.08 * 11; // 0.08em em label 11px

  /// Nome do app, splash, títulos hero — 28/700, tracking -0.02em.
  static TextStyle display([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: _trackingTight,
        height: 1.1,
        color: color,
      );

  /// Títulos de seção — 22/700, tracking -0.02em.
  static TextStyle h1([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 22,
        height: 1.15,
        color: color,
      );

  /// Subtítulos de painel — 18/700.
  static TextStyle h2([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: color,
      );

  /// Rótulos de card — 15/700.
  static TextStyle h3([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color,
      );

  /// Corpo principal — 15/400.
  static TextStyle bodyLg([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  /// Metadados, descrições — 13/400.
  static TextStyle body([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: color,
      );

  /// Timestamps, footnotes — 11/300.
  static TextStyle small([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 11,
        fontWeight: FontWeight.w300,
        height: 1.3,
        color: color,
      );

  /// Rótulo UPPERCASE — 11/700, letterSpacing 0.08em.
  static TextStyle label([Color? color]) => GoogleFonts.redHatDisplay(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: _trackingLabel,
        height: 1.2,
        color: color,
      );

  /// Texto monoespaçado (horários, contagens) — Red Hat Mono.
  /// [size] default 14, [weight] default 500.
  static TextStyle mono({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.redHatMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  /// textTheme base (Red Hat Display) para registrar nos dois ThemeData.
  static TextTheme textThemeFor(Brightness brightness) {
    final base = ThemeData(brightness: brightness).textTheme;
    return GoogleFonts.redHatDisplayTextTheme(base);
  }
}
