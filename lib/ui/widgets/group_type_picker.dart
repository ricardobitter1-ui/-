import 'package:flutter/material.dart';

import '../../data/models/group_type.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';

String groupTypeLabel(GroupType type) {
  switch (type) {
    case GroupType.tasks:
      return 'Tarefas';
    case GroupType.continuous:
      return 'Lista contínua';
    case GroupType.project:
      return 'Projeto';
    case GroupType.routine:
      return 'Rotina';
  }
}

String groupTypeDescription(GroupType type) {
  switch (type) {
    case GroupType.tasks:
      return 'Tarefas com data, responsáveis e lembretes.';
    case GroupType.continuous:
      return 'Lista de compras ou itens que voltam, sem data.';
    case GroupType.project:
      return 'Em breve';
    case GroupType.routine:
      return 'Em breve';
  }
}

IconData groupTypeIcon(GroupType type) {
  switch (type) {
    case GroupType.tasks:
      return Icons.task_alt_rounded;
    case GroupType.continuous:
      return Icons.shopping_cart_outlined;
    case GroupType.project:
      return Icons.flag_outlined;
    case GroupType.routine:
      return Icons.repeat_rounded;
  }
}

class GroupTypePicker extends StatelessWidget {
  const GroupTypePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.types = kGroupTypeTemplatesV1,
  });

  final GroupType selected;
  final ValueChanged<GroupType> onSelected;
  final List<GroupType> types;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Que tipo de lista é essa?', style: ExText.h3(c.textPrimary)),
        const SizedBox(height: ExSpace.s3 - 2),
        for (final t in types) ...[
          Material(
            color: selected == t
                ? ExColors.brandGreen.withValues(alpha: 0.10)
                : c.surface2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelected(t),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == t ? c.borderAccent : c.border,
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      groupTypeIcon(t),
                      color: selected == t ? c.textAccent : c.textSecondary,
                    ),
                    const SizedBox(width: ExSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupTypeLabel(t),
                            style: ExText.h3(
                              selected == t ? c.textAccent : c.textPrimary,
                            ),
                          ),
                          Text(
                            groupTypeDescription(t),
                            style: ExText.body(c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (selected == t)
                      const Icon(
                        Icons.check_circle,
                        color: ExColors.brandGreen,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: ExSpace.s2),
        ],
      ],
    );
  }
}
