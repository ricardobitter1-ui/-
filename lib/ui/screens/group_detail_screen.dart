import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

class GroupDetailScreen extends ConsumerWidget {
  final GroupModel group;
  const GroupDetailScreen({super.key, required this.group});

  GroupModel _resolvedGroup(WidgetRef ref) {
    return ref.watch(groupsStreamProvider).maybeWhen(
          data: (list) {
            for (final g in list) {
              if (g.id == group.id) return g;
            }
            return group;
          },
          orElse: () => group,
        );
  }

  bool _isAdmin(WidgetRef ref, GroupModel g) {
    final u = ref.watch(authStateProvider);
    return u.maybeWhen(
      data: (user) => user != null && g.isAdmin(user.uid),
      orElse: () => false,
    );
  }

  void _openCreateTaskForGroup(BuildContext context, GroupModel g) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFormModal(
        forcedGroupId: g.id,
        collaborationGroup: g,
      ),
    );
  }

  Future<void> _showInviteByUid(
    BuildContext context,
    WidgetRef ref,
    GroupModel g,
  ) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convidar por UID'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Firebase Auth UID do utilizador',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (ok != true) {
      ctrl.dispose();
      return;
    }
    if (!context.mounted) {
      ctrl.dispose();
      return;
    }
    final uid = ctrl.text.trim();
    ctrl.dispose();
    if (uid.isEmpty) return;
    try {
      await ref.read(firebaseServiceProvider).createInvite(
            groupId: g.id,
            inviteeUid: uid,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Convite enviado.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = _resolvedGroup(ref);
    final tasksAsync = ref.watch(groupTasksStreamProvider(g.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(g.name),
        actions: [
          IconButton(
            tooltip: 'Copiar ID do grupo',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: g.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID do grupo copiado.')),
              );
            },
            icon: const Icon(Icons.link_rounded),
          ),
          if (!g.isPersonal && _isAdmin(ref, g))
            IconButton(
              tooltip: 'Convidar',
              onPressed: () => _showInviteByUid(context, ref, g),
              icon: const Icon(Icons.person_add_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _hexToColor(g.color).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _hexToColor(
                    g.color,
                  ).withValues(alpha: 0.16),
                  child: Icon(
                    Icons.groups_rounded,
                    color: _hexToColor(g.color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${g.id}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (g.isPersonal)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Grupo pessoal — não pode ser partilhado.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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
                    '${g.members.length} membro(s)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          ExpansionTile(
            title: const Text('Membros'),
            children: [
              for (final m in g.members)
                ListTile(
                  title: Text(
                    m.length <= 10 ? m : '…${m.substring(m.length - 8)}',
                  ),
                  subtitle: m == g.ownerId
                      ? const Text('Dono')
                      : (g.effectiveAdmins.contains(m)
                          ? const Text('Admin')
                          : null),
                  trailing: _isAdmin(ref, g) &&
                          m != g.ownerId &&
                          !g.isPersonal
                      ? IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(firebaseServiceProvider)
                                  .removeMemberFromGroup(
                                    groupId: g.id,
                                    memberUid: m,
                                  );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro: $e'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        )
                      : null,
                ),
              if (!g.isPersonal && _isAdmin(ref, g))
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_rounded),
                  title: const Text('Convidar por UID'),
                  onTap: () => _showInviteByUid(context, ref, g),
                ),
            ],
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
                      onEdit: () => _openEdit(context, g, task),
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
        onPressed: () => _openCreateTaskForGroup(context, g),
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openEdit(
    BuildContext context,
    GroupModel g,
    TaskModel task,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFormModal(
        initialTask: task,
        forcedGroupId: g.id,
        collaborationGroup: g,
      ),
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
