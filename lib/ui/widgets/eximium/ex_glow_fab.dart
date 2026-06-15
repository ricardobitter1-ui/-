import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_effects.dart';
import '../../theme/eximium_spacing.dart';
import '../../theme/eximium_typography.dart';

/// FAB do DS: quadrado arredondado (~58px, radius 20), fill verde, ícone
/// `onBrandGreen`, sombra + glowMd.
///
/// Use [ExGlowFab.extended] para a variante pill com label (ex.: "Novo grupo").
class ExGlowFab extends StatelessWidget {
  const ExGlowFab({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 58,
    this.tooltip,
  })  : label = null,
        _extended = false;

  const ExGlowFab.extended({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
  })  : size = 58,
        _extended = true;

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final double size;
  final String? tooltip;
  final bool _extended;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;

    final borderRadius = BorderRadius.circular(
      _extended ? ExRadius.pill : ExRadius.lg,
    );
    final decoration = BoxDecoration(
      color: ExColors.brandGreen,
      borderRadius: borderRadius,
      boxShadow: [
        ...c.shadowFloat,
        ...ExEffects.glowMd,
      ],
    );

    final Widget button;
    if (_extended) {
      button = DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ExSpace.s5,
                vertical: 14,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: ExColors.onBrandGreen, size: 20),
                  const SizedBox(width: 9),
                  Text(
                    label!,
                    style: ExText.body(ExColors.onBrandGreen).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      button = DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(icon, color: ExColors.onBrandGreen, size: 26),
              ),
            ),
          ),
        ),
      );
    }

    Widget wrapped = button;

    if (tooltip != null) {
      wrapped = Tooltip(message: tooltip!, child: wrapped);
    }
    return wrapped;
  }
}
