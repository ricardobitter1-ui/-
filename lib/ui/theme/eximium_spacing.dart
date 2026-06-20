/// Eximium Design System — spacing & geometry tokens.
///
/// Espelha `tokens/spacing.css`. Use estas constantes em vez de valores
/// mágicos para manter o ritmo do DS.
library;

/// Escala de espaçamento (padding, margens, gaps).
class ExSpace {
  ExSpace._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

/// Raios de borda da linguagem cápsula/arredondada do DS.
class ExRadius {
  ExRadius._();

  /// Chips compactos, badges.
  static const double sm = 6.0;

  /// Inputs, tooltips.
  static const double md = 12.0;

  /// Cards, painéis.
  static const double lg = 20.0;

  /// Modais, sheets (topo).
  static const double xl = 32.0;

  /// Botões, tags, toggles.
  static const double pill = 9999.0;
}
