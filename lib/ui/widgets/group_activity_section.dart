import 'package:flutter/material.dart';

import '../../business_logic/group_activity_feed.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_typography.dart';

/// Feed compacto de atividade recente do grupo.
class GroupActivitySection extends StatelessWidget {
  const GroupActivitySection({
    super.key,
    required this.tasks,
    required this.profiles,
  });

  final List<TaskModel> tasks;
  final Map<String, UserPublicProfile?> profiles;

  @override
  Widget build(BuildContext context) {
    final events = buildGroupActivityFeed(
      tasks: tasks,
      profiles: profiles,
      displayNameFor: memberDisplayLabel,
    );
    if (events.isEmpty) return const SizedBox.shrink();

    final c = context.ex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 4),
          child: Text(
            'Atividade recente',
            style: ExText.label(c.textSecondary),
          ),
        ),
        ...events.map(
          (e) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              e.label.contains('concluí')
                  ? Icons.check_circle_outline_rounded
                  : Icons.add_circle_outline_rounded,
              size: 20,
              color: e.label.contains('concluí')
                  ? c.successText
                  : c.textSecondary,
            ),
            title: Text(
              e.label,
              style: ExText.body(c.textPrimary),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
