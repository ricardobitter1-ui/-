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
import '../theme/color_utils.dart';
import '../theme/group_icon.dart';
import '../widgets/edit_group_sheet.dart';
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

  Future<void> _showInviteByEmail(
    BuildContext context,
    WidgetRef ref,
    GroupModel g,
  ) async {
    final ctrl = TextEditingController();
    void disposeCtrlNextFrame() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ctrl.dispose();
      });
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convidar por e-mail'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            hintText: 'email@exemplo.com',
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
      disposeCtrlNextFrame();
      return;
    }
    if (!context.mounted) {
      disposeCtrlNextFrame();
      return;
    }
    final email = ctrl.text.trim();
    disposeCtrlNextFrame();
    if (email.isEmpty) return;
    try {
      await ref.read(firebaseServiceProvider).createInviteByEmail(
            groupId: g.id,
            email: email,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Convite criado. O convidado verá ao abrir a app com este e-mail.',
            ),
          ),
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

  Future<void> _copyInviteLink(
    BuildContext context,
    WidgetRef ref,
    GroupModel g,
  ) async {
    try {
      final uri = await ref
          .read(firebaseServiceProvider)
          .getLatestPendingInviteShareUriForGroup(g.id);
      if (!context.mounted) return;
      if (uri == null || uri.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Crie um convite por e-mail primeiro para gerar o link.',
            ),
          ),
        );
        return;
      }
      await Clipboard.setData(ClipboardData(text: uri));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link de convite copiado.')),
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

  void _openEditGroupSheet(BuildContext context, GroupModel g) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => EditGroupSheet(group: g),
    ).then((saved) {
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo atualizado.')),
        );
      }
    });
  }

  Future<void> _confirmDeleteGroup(
    BuildContext context,
    WidgetRef ref,
    GroupModel g,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar grupo?'),
        content: const Text(
          'O grupo será removido para todos os membros. '
          'As tarefas associadas deixam de ser acessíveis neste contexto. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(firebaseServiceProvider).deleteGroup(g.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grupo removido.')),
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'copyLink':
                  _copyInviteLink(context, ref, g);
                case 'invite':
                  _showInviteByEmail(context, ref, g);
                case 'edit':
                  _openEditGroupSheet(context, g);
                case 'delete':
                  _confirmDeleteGroup(context, ref, g);
              }
            },
            itemBuilder: (ctx) => [
              if (!g.isPersonal && _isAdmin(ref, g))
                const PopupMenuItem(
                  value: 'copyLink',
                  child: ListTile(
                    leading: Icon(Icons.link_rounded),
                    title: Text('Copiar link de convite'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (!g.isPersonal && _isAdmin(ref, g))
                const PopupMenuItem(
                  value: 'invite',
                  child: ListTile(
                    leading: Icon(Icons.person_add_rounded),
                    title: Text('Convidar por e-mail'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (_isAdmin(ref, g))
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_rounded),
                    title: Text('Editar grupo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (!g.isPersonal && _isAdmin(ref, g))
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent.shade200),
                    title: Text(
                      'Apagar grupo',
                      style: TextStyle(color: Colors.redAccent.shade200),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: parseAppHexColor(g.color).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: parseAppHexColor(
                    g.color,
                  ).withValues(alpha: 0.16),
                  child: Icon(
                    groupIconFromKey(g.icon),
                    color: parseAppHexColor(g.color),
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
                  title: const Text('Convidar por e-mail'),
                  onTap: () => _showInviteByEmail(context, ref, g),
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
