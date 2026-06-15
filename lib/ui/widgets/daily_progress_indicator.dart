import 'package:flutter/material.dart';

import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';

class DailyProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0

  const DailyProgressIndicator({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final int percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progresso do dia', style: ExText.label(c.textSecondary)),
            Text('$percentage%', style: ExText.mono(size: 13, color: c.textAccent)),
          ],
        ),
        const SizedBox(height: ExSpace.s2),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(ExRadius.pill),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  height: 8,
                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    gradient: ExColors.gradientBrand,
                    borderRadius: BorderRadius.circular(ExRadius.pill),
                    boxShadow: progress > 0 ? ExEffects.glowSm : null,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
