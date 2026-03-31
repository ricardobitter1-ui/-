import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../data/models/group_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../theme/group_icon.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/edit_group_sheet.dart';
import '../widgets/group_tag_name_color_dialog.dart';
import '../widgets/partitioned_group_task_list.dart';
import '../widgets/task_form_modal.dart';

void _openManageGroupTags(
  BuildContext context,
  WidgetRef ref,
  GroupModel g,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (ctx) {
      final h = MediaQuery.sizeOf(ctx).height * 0.45;
      return SafeArea(
        child: SizedBox(
          height: h,
          child: Consumer(
            builder: (context, ref2, _) {
              final async = ref2.watch(groupTagsStreamProvider(g.id));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text(
                            'Etiquetas do grupo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: async.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Center(child: Text('Erro: $e')),
                      data: (tags) {
                        if (tags.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Ainda não há etiquetas. Crie-as ao adicionar uma tarefa.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: tags.length,
                          itemBuilder: (context, i) {
                            final t = tags[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(t.color),
                                radius: 14,
                              ),
                              title: Text(t.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      final result = await showDialog<
                                          ({String name, int color})>(
                                        context: context,
                                        builder: (dctx) =>
                                            GroupTagNameColorDialog(
                                          initialTag: t,
                                        ),
                                      );
                                      if (result == null || !context.mounted) {
                                        return;
                                      }
                                      try {
                                        await ref2
                                            .read(firebaseServiceProvider)
                                            .updateGroupTag(
                                              groupId: g.id,
                                              tagId: t.id,
                                              name: result.name,
                                              color: result.color,
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Etiqueta atualizada.'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text('$e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    onPressed: () async {
                                      try {
                                        await ref2
                                            .read(firebaseServiceProvider)
                                            .deleteGroupTag(g.id, t.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Etiqueta removida.',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(content: Text('$e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

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
        content: AutofillGroup(
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'email@exemplo.com',
            ),
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

  Future<void> _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref,
    GroupModel g,
    String memberUid,
    String memberDisplayLabel,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover membro?'),
        content: Text(
          'Remover "$memberDisplayLabel" deste grupo? '
          'Esta pessoa deixa de ver as tarefas e convites deste grupo. '
          'Só volta a entrar com um novo convite.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(firebaseServiceProvider).removeMemberFromGroup(
            groupId: g.id,
            memberUid: memberUid,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membro removido.')),
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
    final profilesAsync = ref.watch(
      groupMemberProfilesProvider(memberUidsCacheKey(g.members)),
    );
    final me = ref.watch(authStateProvider).value;

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
                  break;
                case 'invite':
                  _showInviteByEmail(context, ref, g);
                  break;
                case 'edit':
                  _openEditGroupSheet(context, g);
                  break;
                case 'manageTags':
                  _openManageGroupTags(context, ref, g);
                  break;
                case 'delete':
                  _confirmDeleteGroup(context, ref, g);
                  break;
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
              const PopupMenuItem(
                value: 'manageTags',
                child: ListTile(
                  leading: Icon(Icons.label_outline_rounded),
                  title: Text('Gerir etiquetas'),
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
              profilesAsync.when(
                loading: () => const ListTile(
                  leading: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  title: Text('A carregar membros…'),
                ),
                error: (e, _) => ListTile(title: Text('Erro: $e')),
                data: (profileMap) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final m in g.members)
                      ListTile(
                        leading: CustomAvatar(
                          photoUrl: memberPhotoUrl(
                            m,
                            profileMap,
                            selfUid: me?.uid,
                            selfPhotoUrl: me?.photoURL,
                          ),
                          displayName: memberDisplayLabel(m, profileMap),
                          radius: 20,
                        ),
                        title: Text(memberDisplayLabel(m, profileMap)),
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
                                onPressed: () => _confirmRemoveMember(
                                  context,
                                  ref,
                                  g,
                                  m,
                                  memberDisplayLabel(m, profileMap),
                                ),
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
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ref.watch(groupTagsStreamProvider(g.id)).when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Etiquetas: $e')),
                  data: (tags) => tasksAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erro: $e')),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Nenhuma tarefa neste grupo ainda.\nCrie a primeira para validar o stream!',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        );
                      }
                      return PartitionedGroupTaskList(
                        group: g,
                        tasks: tasks,
                        tags: tags,
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateTaskForGroup(context, g),
        backgroundColor: AppTheme.brandPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
