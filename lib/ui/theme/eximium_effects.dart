import 'package:flutter/material.dart';

import 'eximium_colors.dart';

/// Eximium Design System — effects tokens (glows, focus ring, background).
///
/// Glows são invariantes (sempre o halo verde) e devem aparecer apenas em
/// elementos interativos **ativos** — nunca decorativos.
class ExEffects {
  ExEffects._();

  static const Color _green = ExColors.brandGreen;

  /// 0 0 12px rgba(green,.20)
  static List<BoxShadow> get glowSm => [
        BoxShadow(
          color: _green.withValues(alpha: 0.20),
          blurRadius: 12,
        ),
      ];

  /// 0 0 20px rgba(green,.30)
  static List<BoxShadow> get glowMd => [
        BoxShadow(
          color: _green.withValues(alpha: 0.30),
          blurRadius: 20,
        ),
      ];

  /// 0 0 40px rgba(green,.45)
  static List<BoxShadow> get glowLg => [
        BoxShadow(
          color: _green.withValues(alpha: 0.45),
          blurRadius: 40,
        ),
      ];

  /// Anel de foco verde (0 0 0 3px rgba(green,.12)).
  /// Use como [BoxShadow] (spread) em containers de inputs focados.
  static List<BoxShadow> get focusRing => [
        BoxShadow(
          color: _green.withValues(alpha: 0.12),
          blurRadius: 0,
          spreadRadius: 3,
        ),
      ];

  /// Borda de foco verde para inputs (1.5px). Combine com [focusRing].
  static Border focusBorder({double width = 1.5}) =>
      Border.all(color: _green, width: width);
}

/// Fundo do app com radial glow duplo (verde top-right ~6%, lavanda
/// bottom-left ~5%) sobre `surface0`. Use nos Scaffolds principais e no login.
///
/// Coloque como widget de fundo (ex.: dentro de um `Stack` ou como `body`
/// envolvendo o conteúdo).
class ExAppBackground extends StatelessWidget {
  const ExAppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface0),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.85, -1.05),
                  radius: 1.1,
                  colors: [
                    ExColors.brandGreen.withValues(alpha: 0.06),
                    ExColors.brandGreen.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, 1.1),
                  radius: 1.0,
                  colors: [
                    ExColors.lavender.withValues(alpha: 0.05),
                    ExColors.lavender.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
