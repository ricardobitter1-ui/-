import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_spacing.dart';
import '../../theme/eximium_typography.dart';

/// Variantes de status do [ExBadge].
enum ExBadgeVariant { success, info, error, warning, neutral }

/// Badge (pill) com tint de fundo a 12% + texto na cor de status.
class ExBadge extends StatelessWidget {
  const ExBadge({
    super.key,
    required this.label,
    this.variant = ExBadgeVariant.neutral,
    this.emphatic = false,
    this.icon,
  });

  final String label;
  final ExBadgeVariant variant;

  /// UPPERCASE + letterSpacing (label do DS).
  final bool emphatic;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;

    late final Color bg;
    late final Color fg;
    switch (variant) {
      case ExBadgeVariant.success:
        bg = ExColors.successBg;
        fg = c.successText;
        break;
      case ExBadgeVariant.info:
        bg = ExColors.infoBg;
        fg = c.infoText;
        break;
      case ExBadgeVariant.error:
        bg = ExColors.errorBg;
        fg = c.errorText;
        break;
      case ExBadgeVariant.warning:
        bg = ExColors.warningBg;
        fg = c.warningText;
        break;
      case ExBadgeVariant.neutral:
        bg = c.surface2;
        fg = c.textSecondary;
        break;
    }

    final text = emphatic ? label.toUpperCase() : label;
    final style = emphatic
        ? ExText.label(fg)
        : ExText.body(fg).copyWith(fontWeight: FontWeight.w600, fontSize: 11);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ExSpace.s2 + 1,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ExRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: style),
        ],
      ),
    );
  }
}
