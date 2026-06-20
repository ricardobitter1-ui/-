import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_spacing.dart';
import '../../theme/eximium_typography.dart';

/// Ponto colorido (6px por padrão) — acento mínimo de grupo/tag.
class ExDot extends StatelessWidget {
  const ExDot({super.key, required this.color, this.size = 6});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Chip de grupo: pill com [ExDot] colorido + label na cor do grupo,
/// fundo tint a ~14%.
class ExGroupChip extends StatelessWidget {
  const ExGroupChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ExRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExDot(color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: ExText.body(color).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de metadado: ícone + texto, cor customizável (tint a ~12%).
class ExMetaChip extends StatelessWidget {
  const ExMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;

  /// Cor do conteúdo; default `textSecondary`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final fg = color ?? c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ExRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ExText.body(fg).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de recorrência (lavanda/info): ícone de refresh + label.
class ExRecurrenceChip extends StatelessWidget {
  const ExRecurrenceChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return ExMetaChip(
      icon: Icons.refresh_rounded,
      label: label,
      color: c.infoText,
    );
  }
}
