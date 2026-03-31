import 'package:flutter/material.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  /// Etiquetas a mostrar no cartão (ex.: concluídas com tags do grupo).
  final List<TagModel>? tagChips;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.tagChips,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = task.latitude != null || task.locationTrigger != null;
    final bool hasDate = task.dueDate != null;

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
                      if (hasLocation || hasDate) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (hasLocation) _buildBadge(
                              icon: Icons.location_on_rounded, 
                              label: task.locationTrigger == 'departure' ? 'Ao Sair' : 'Localização',
                              color: Colors.blue,
                            ),
                            if (hasDate) _buildBadge(
                              icon: Icons.alarm_rounded, 
                              label: "Agendado",
                              color: AppTheme.primaryBlue,
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
            color: task.isCompleted ? AppTheme.primaryBlue : Colors.grey.shade300, 
            width: 2,
          ),
          color: task.isCompleted ? AppTheme.primaryBlue : Colors.white,
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
