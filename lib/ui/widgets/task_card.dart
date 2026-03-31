import 'package:flutter/material.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../utils/scheduled_badge_label.dart';
import '../theme/app_theme.dart';
import 'custom_avatar.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  /// Etiquetas a mostrar no cartão (ex.: concluídas com tags do grupo).
  final List<TagModel>? tagChips;
  /// Perfis públicos dos membros (uid → perfil); pode ser vazio — usa-se fallback de rótulo/inicial.
  final Map<String, UserPublicProfile?>? assigneeProfiles;
  final String? selfUid;
  final String? selfPhotoUrl;
  /// Quando preenchido (ex.: lista "Todas"), mostra a qual grupo a tarefa pertence ou "Pessoal".
  final String? groupLabel;
  /// Cor do indicador do grupo; opcional (cinza se nula).
  final Color? groupAccentColor;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.tagChips,
    this.assigneeProfiles,
    this.selfUid,
    this.selfPhotoUrl,
    this.groupLabel,
    this.groupAccentColor,
  });

  static const double _assigneeRadius = 12;
  static const double _assigneeOverlapStep = 14;
  static const int _maxAssigneeAvatars = 3;

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = task.latitude != null || task.locationTrigger != null;
    final bool hasDate = task.dueDate != null;
    final bool hasAssignees = task.assigneeIds.isNotEmpty;
    final bool showMetaRow = hasLocation || hasDate || hasAssignees;

    final int firstDayIndex =
        MaterialLocalizations.of(context).firstDayOfWeekIndex;

    ScheduledBadgeData? scheduleData;
    if (hasDate && task.dueDate != null) {
      scheduleData = formatScheduledBadge(
        due: task.dueDate!,
        now: DateTime.now(),
        firstDayOfWeekIndex: firstDayIndex,
      );
    }

    final Color scheduleColor = scheduleData != null && scheduleData.isOverdue
        ? Theme.of(context).colorScheme.error
        : AppTheme.brandPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckbox(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                    color: task.isCompleted ? Colors.grey : const Color(0xFF2B2D42),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (onDelete != null)
                            IconButton(
                              onPressed: onDelete,
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      if (groupLabel != null && groupLabel!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: groupAccentColor ?? Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                groupLabel!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (tagChips != null && tagChips!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tag in tagChips!)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(tag.color).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(tag.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tag.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(tag.color),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (showMetaRow) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (hasAssignees) _buildAssigneeStack(context),
                            if (hasLocation)
                              _buildBadge(
                                icon: Icons.location_on_rounded,
                                label: task.locationTrigger == 'departure' ? 'Ao Sair' : 'Localização',
                                color: Colors.blue,
                              ),
                            if (hasDate && scheduleData != null)
                              _buildBadge(
                                icon: Icons.alarm_rounded,
                                label: scheduleData.label,
                                color: scheduleColor,
                              ),
                          ],
                        )
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeStack(BuildContext context) {
    final ids = task.assigneeIds;
    if (ids.isEmpty) return const SizedBox.shrink();

    final map = assigneeProfiles ?? const <String, UserPublicProfile?>{};
    final names = ids.map((id) => memberDisplayLabel(id, map)).join(', ');
    final visible = ids.take(_maxAssigneeAvatars).toList();
    final overflow = ids.length - visible.length;
    final stackWidth = visible.isEmpty
        ? 0.0
        : 2 * _assigneeRadius + (visible.length - 1) * _assigneeOverlapStep;

    return Tooltip(
      message: names,
      child: Semantics(
        label: 'Responsáveis: $names',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: stackWidth,
              height: 2 * _assigneeRadius,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < visible.length; i++)
                    Positioned(
                      left: i * _assigneeOverlapStep,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cardSurface, width: 2),
                        ),
                        child: CustomAvatar(
                          radius: _assigneeRadius,
                          photoUrl: memberPhotoUrl(
                            visible[i],
                            map,
                            selfUid: selfUid,
                            selfPhotoUrl: selfPhotoUrl,
                          ),
                          displayName: memberDisplayLabel(visible[i], map),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  '+$overflow',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: task.isCompleted
          ? 'Marcar tarefa como pendente'
          : 'Marcar tarefa como concluída',
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 300),
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: task.isCompleted ? AppTheme.brandPrimary : Colors.grey.shade300,
            width: 2,
          ),
          color: task.isCompleted ? AppTheme.brandPrimary : Colors.white,
        ),
        child: task.isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
        ),
      ),
    );
  }

  Widget _buildBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
