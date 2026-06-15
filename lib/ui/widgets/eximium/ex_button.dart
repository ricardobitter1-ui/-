import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_effects.dart';
import '../../theme/eximium_spacing.dart';
import '../../theme/eximium_typography.dart';

/// Variantes de [ExButton].
enum ExButtonVariant {
  /// Fill verde, texto `onBrandGreen`, glowSm.
  primary,

  /// surface2 + border, texto primary.
  secondary,

  /// Transparente, texto/borda verde.
  ghost,

  /// Texto/borda error.
  danger,
}

/// Tamanhos de [ExButton].
enum ExButtonSize { sm, md, lg }

/// Botão do DS em linguagem cápsula (radius pill).
class ExButton extends StatelessWidget {
  const ExButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ExButtonVariant.primary,
    this.expand = false,
    this.size = ExButtonSize.md,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ExButtonVariant variant;

  /// Ocupa toda a largura disponível.
  final bool expand;
  final ExButtonSize size;

  EdgeInsets get _padding {
    switch (size) {
      case ExButtonSize.sm:
        return const EdgeInsets.symmetric(
            horizontal: ExSpace.s3, vertical: ExSpace.s2);
      case ExButtonSize.md:
        return const EdgeInsets.symmetric(
            horizontal: ExSpace.s5, vertical: ExSpace.s3 + 2);
      case ExButtonSize.lg:
        return const EdgeInsets.symmetric(
            horizontal: ExSpace.s6, vertical: ExSpace.s4);
    }
  }

  double get _fontSize {
    switch (size) {
      case ExButtonSize.sm:
        return 13;
      case ExButtonSize.md:
        return 14;
      case ExButtonSize.lg:
        return 15;
    }
  }

  double get _iconSize {
    switch (size) {
      case ExButtonSize.sm:
        return 16;
      case ExButtonSize.md:
        return 18;
      case ExButtonSize.lg:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final bool disabled = onPressed == null;

    late final Color bg;
    late final Color fg;
    late final Color? borderColor;
    List<BoxShadow>? glow;

    switch (variant) {
      case ExButtonVariant.primary:
        bg = ExColors.brandGreen;
        fg = ExColors.onBrandGreen;
        borderColor = null;
        glow = ExEffects.glowSm;
        break;
      case ExButtonVariant.secondary:
        bg = c.surface2;
        fg = c.textPrimary;
        borderColor = c.border;
        break;
      case ExButtonVariant.ghost:
        bg = Colors.transparent;
        fg = c.textAccent;
        borderColor = c.borderAccent;
        break;
      case ExButtonVariant.danger:
        bg = Colors.transparent;
        fg = c.errorText;
        borderColor = c.errorText.withValues(alpha: 0.45);
        break;
    }

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _iconSize, color: fg),
          const SizedBox(width: ExSpace.s2),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: ExText.h3(fg).copyWith(fontSize: _fontSize),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ExRadius.pill),
          boxShadow: disabled ? null : glow,
        ),
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExRadius.pill),
            side: borderColor != null
                ? BorderSide(color: borderColor)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(ExRadius.pill),
            child: Padding(
              padding: _padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
