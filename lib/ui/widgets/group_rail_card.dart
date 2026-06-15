import 'package:flutter/material.dart';

import '../../business_logic/group_day_progress.dart';
import '../../data/models/group_model.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../theme/group_icon.dart';

class GroupRailCard extends StatelessWidget {
  final GroupModel group;
  final GroupProgress stats;
  final VoidCallback onTap;

  const GroupRailCard({
    super.key,
    required this.group,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final Color groupColor = parseAppHexColor(group.color);

    return Material(
      color: c.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExRadius.lg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ExRadius.lg),
        onTap: onTap,
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ExRadius.lg),
            border: Border.all(color: c.border),
            boxShadow: c.shadowCard,
          ),
          padding: const EdgeInsets.all(ExSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: groupColor.withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      groupIconFromKey(group.icon),
                      color: groupColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: ExSpace.s2 + 2),
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ExText.h3(c.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ExSpace.s4),
              Text(
                stats.total == 0
                    ? 'Nenhuma tarefa'
                    : '${stats.completed}/${stats.total} concluídas',
                style: ExText.body(c.textSecondary),
              ),
              const SizedBox(height: ExSpace.s2),
              ClipRRect(
                borderRadius: BorderRadius.circular(ExRadius.pill),
                child: LinearProgressIndicator(
                  value: stats.total == 0 ? 0 : stats.ratio,
                  minHeight: 6,
                  backgroundColor: c.surface3,
                  color: groupColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
