import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';

/// FAB: toque abre formulário; long-press inicia ditado.
class ExpandableCreateTaskFab extends StatelessWidget {
  const ExpandableCreateTaskFab({
    super.key,
    required this.onWrite,
    required this.onDictate,
  });

  final VoidCallback onWrite;
  final VoidCallback onDictate;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ExRadius.lg),
        boxShadow: [
          ...c.shadowFloat,
          ...ExEffects.glowMd,
        ],
      ),
      child: Material(
        color: ExColors.brandGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExRadius.lg),
        ),
        child: InkWell(
          onTap: onWrite,
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onDictate();
          },
          borderRadius: BorderRadius.circular(ExRadius.lg),
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              Icons.add_rounded,
              color: ExColors.onBrandGreen,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
