import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/task_provider.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

class GroupDetailScreen extends ConsumerWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  void _openCreateTaskForGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFormModal(forcedGroupId: group.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(groupTasksStreamProvider(group.id));

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hexToColor(group.color).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _hexToColor(
                    group.color,
                  ).withValues(alpha: 0.16),
                  child: Icon(
                    Icons.groups_rounded,
                    color: _hexToColor(group.color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${group.id}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${group.members.length} membro(s)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhuma tarefa neste grupo ainda.\nCrie a primeira para validar o stream!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onToggle: () {
                        ref
                            .read(firebaseServiceProvider)
                            .toggleTaskCompletion(task.id, task.isCompleted);
                      },
                      onEdit: () => _openEdit(context, task),
                      onDelete: () async {
                        final fs = ref.read(firebaseServiceProvider);
                        final ns = ref.read(notificationServiceProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tarefa "${task.title}" removida.'),
                              action: SnackBarAction(
                                label: 'Desfazer',
                                onPressed: () {
                                  fs.addTask(task);
                                  if (task.reminderType == 'datetime' &&
                                      task.dueDate != null) {
                                    ns.scheduleTaskReminder(
                                      task.id.hashCode,
                                      task.title,
                                      task.description.isEmpty
                                          ? 'Hora de completar sua tarefa!'
                                          : task.description,
                                      task.dueDate!,
                                    );
                                  }
                                },
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF2B2D42),
                            ),
                          );
                        }

                        await fs.deleteTask(task.id);
                        await ns.cancelNotification(task.id.hashCode);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateTaskForGroup(context),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEdit(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          TaskFormModal(initialTask: task, forcedGroupId: group.id),
    );
  }
}

Color _hexToColor(String hex) {
  final raw = hex.trim();
  final sanitized = raw.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
  if (sanitized.isEmpty) return const Color(0xFF0052FF);

  final normalized = sanitized.length > 8
      ? sanitized.substring(sanitized.length - 8)
      : sanitized;

  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return const Color(0xFF0052FF);

  if (normalized.length <= 6) {
    return Color(0xFF000000 | value);
  }
  return Color(value & 0xFFFFFFFF);
}
