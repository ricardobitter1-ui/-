import 'package:flutter/material.dart';

import '../../theme/eximium_colors.dart';
import '../../theme/eximium_spacing.dart';

/// Card base do DS: superfície `surface1`, borda 1px, radius `lg` (20),
/// `shadowCard`. Quando [onTap] é fornecido, a borda vira `borderAccent`
/// no hover/press.
///
/// [accentBorderLeft] aplica o tratamento B (barra lateral colorida) — usar
/// na agenda/timeline.
class ExCard extends StatefulWidget {
  const ExCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ExSpace.s4),
    this.onTap,
    this.accentBorderLeft,
    this.margin,
    this.borderColor,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Tratamento B: barra/borda esquerda colorida (cor do grupo).
  final Color? accentBorderLeft;

  final EdgeInsetsGeometry? margin;

  /// Sobrepõe a cor da borda (default `border`/`borderAccent`).
  final Color? borderColor;

  /// Sobrepõe o radius (default `lg`).
  final double? borderRadius;

  @override
  State<ExCard> createState() => _ExCardState();
}

class _ExCardState extends State<ExCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final radius = widget.borderRadius ?? ExRadius.lg;
    final bool active = (_hovered || _pressed) && widget.onTap != null;

    final Color resolvedBorder = widget.borderColor ??
        (active ? c.borderAccent : c.border);

    final borderRadius = BorderRadius.circular(radius);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: borderRadius,
        border: widget.accentBorderLeft != null
            ? Border(
                left: BorderSide(color: widget.accentBorderLeft!, width: 3),
                top: BorderSide(color: resolvedBorder),
                right: BorderSide(color: resolvedBorder),
                bottom: BorderSide(color: resolvedBorder),
              )
            : Border.all(color: resolvedBorder),
        boxShadow: c.shadowCard,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) {
      return Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: content,
      );
    }

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: content,
        ),
      ),
    );
  }
}
