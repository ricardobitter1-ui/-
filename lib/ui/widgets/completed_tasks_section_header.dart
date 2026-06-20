import 'package:flutter/material.dart';

import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';

class CompletedTasksSectionHeader extends StatelessWidget {
  const CompletedTasksSectionHeader({
    super.key,
    required this.expanded,
    required this.count,
    required this.onToggle,
    this.title,
  });

  final bool expanded;
  final int count;
  final VoidCallback onToggle;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final label = '${title ?? 'Concluídas'} ($count)';
    return Padding(
      padding: const EdgeInsets.only(top: ExSpace.s2, bottom: ExSpace.s3),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          expanded: expanded,
          label:
              '$label. Toque para ${expanded ? 'recolher' : 'expandir'} a lista de tarefas concluídas.',
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(ExRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ExSpace.s3,
                horizontal: ExSpace.s1,
              ),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: c.textAccent,
                  ),
                  const SizedBox(width: ExSpace.s2),
                  Text(label, style: ExText.h3(c.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
