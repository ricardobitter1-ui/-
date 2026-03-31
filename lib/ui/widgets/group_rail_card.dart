import 'package:flutter/material.dart';

import '../../business_logic/group_day_progress.dart';
import '../../data/models/group_model.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
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
    final userTint = parseAppHexColor(group.color);
    final surface = railCardSurfaceForWhiteText(userTint);
    final gradientTop = Color.lerp(surface, Colors.white, 0.14) ?? surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientTop, surface],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
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
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    child: Icon(
                      groupIconFromKey(group.icon),
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                stats.total == 0
                    ? 'Nenhuma tarefa'
                    : '${stats.completed}/${stats.total} concluídas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: stats.total == 0 ? 0 : stats.ratio,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  color: AppTheme.successCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
