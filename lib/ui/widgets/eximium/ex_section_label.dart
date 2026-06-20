import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_spacing.dart';
import '../../theme/eximium_typography.dart';

/// Rótulo de seção: UPPERCASE 11/700/0.08em em `textSecondary`, com
/// contagem opcional (ex.: "PENDENTES · 4").
class ExSectionLabel extends StatelessWidget {
  const ExSectionLabel({
    super.key,
    required this.label,
    this.count,
    this.color,
    this.trailing,
  });

  final String label;

  /// Contagem opcional renderizada como "· N".
  final int? count;

  /// Cor do texto (default `textSecondary`).
  final Color? color;

  /// Widget opcional à direita (ex.: ação "Reagendar todas").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final fg = color ?? c.textSecondary;
    final text = count != null
        ? '${label.toUpperCase()} · $count'
        : label.toUpperCase();

    return Row(
      children: [
        Expanded(
          child: Text(text, style: ExText.label(fg)),
        ),
        if (trailing != null) ...[
          const SizedBox(width: ExSpace.s2),
          trailing!,
        ],
      ],
    );
  }
}
