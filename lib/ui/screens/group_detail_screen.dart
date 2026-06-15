import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../theme/group_icon.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/edit_group_sheet.dart';
import '../widgets/eximium/eximium.dart';
import '../widgets/group_tag_name_color_dialog.dart';
import '../widgets/expandable_create_task_fab.dart';
import '../widgets/group_activity_section.dart';
import '../widgets/partitioned_group_task_list.dart';
import '../widgets/task_form_modal.dart';
import '../widgets/voice_task_recording_sheet.dart';

void _openManageGroupTags(
  BuildContext context,
  WidgetRef ref,
  GroupModel g,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.ex.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ExRadius.xl)),
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
                    padding: const EdgeInsets.fromLTRB(8, 12, 4, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'Etiquetas do grupo',
                            style: ExText.h2(context.ex.textPrimary),
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
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormModal(
        forcedGroupId: g.id,
        collaborationGroup: g,
      ),
    );
  }

  void _openVoiceForGroup(BuildContext context, WidgetRef ref, GroupModel g) {
    final groups = ref.read(groupsStreamProvider).value ?? const [];
    showVoiceTaskRecordingSheet(
      context: context,
      groups: groups,
      forcedGroupId: g.id,
      contextGroup: g,
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
          .ensureShareInviteUriForGroup(g.id);
      if (!context.mounted) return;
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
      backgroundColor: Colors.transparent,
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

  /// Cabeçalho rolável: aviso de grupo pessoal + acordeão de membros.
  List<Widget> _groupDetailScrollPrefix(
    BuildContext context,
    WidgetRef ref,
    GroupModel g,
    AsyncValue<Map<String, UserPublicProfile?>> profilesAsync,
    User? me,
    List<TaskModel> tasks,
  ) {
    final profileMap = profilesAsync.value ?? {};
    return [
      _GroupProgressCard(
        group: g,
        tasks: tasks,
        profiles: profileMap,
        selfUid: me?.uid,
        selfPhotoUrl: me?.photoURL,
      ),
      const SizedBox(height: ExSpace.s4),
      if (g.isPersonal)
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            'Grupo pessoal — não pode ser compartilhado.',
            style: ExText.body(context.ex.textSecondary),
          ),
        ),
      if (!g.isPersonal)
        GroupActivitySection(tasks: tasks, profiles: profileMap),
      ExpansionTile(
        title: Text('Membros (${g.members.length})'),
        children: [
          profilesAsync.when(
            loading: () => const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Carregando membros…'),
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
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = _resolvedGroup(ref);
    final tasksAsync = ref.watch(groupTasksStreamProvider(g.id));
    final profilesAsync = ref.watch(
      groupMemberProfilesProvider(memberUidsCacheKey(g.members)),
    );
    final me = ref.watch(authStateProvider).value;
    final groupColor = parseAppHexColor(g.color);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: groupColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(ExRadius.md),
              ),
              child: Icon(
                groupIconFromKey(g.icon),
                size: 20,
                color: groupColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                g.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: ExText.h2(context.ex.textPrimary),
              ),
            ),
          ],
        ),
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
                  title: Text('Gerenciar etiquetas'),
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
      body: ExAppBackground(
        child: ref.watch(groupTagsStreamProvider(g.id)).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Etiquetas: $e')),
              data: (tags) => tasksAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erro: $e')),
                    data: (tasks) => PartitionedGroupTaskList(
                      group: g,
                      tasks: tasks,
                      tags: tags,
                      listPrefix: _groupDetailScrollPrefix(
                        context,
                        ref,
                        g,
                        profilesAsync,
                        me,
                        tasks,
                      ),
                    ),
                  ),
            ),
      ),
      floatingActionButton: ExpandableCreateTaskFab(
        onWrite: () => _openCreateTaskForGroup(context, g),
        onDictate: () => _openVoiceForGroup(context, ref, g),
      ),
    );
  }
}

/// Card de progresso do grupo: anel circular com %, contagens e avatares.
class _GroupProgressCard extends StatelessWidget {
  const _GroupProgressCard({
    required this.group,
    required this.tasks,
    required this.profiles,
    this.selfUid,
    this.selfPhotoUrl,
  });

  final GroupModel group;
  final List<TaskModel> tasks;
  final Map<String, UserPublicProfile?> profiles;
  final String? selfUid;
  final String? selfPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final total = tasks.length;
    final completed =
        tasks.where((t) => isOccurrenceCompletedOnCalendarDay(t, today)).length;
    final pending = total - completed;
    final double progress = total == 0 ? 0 : completed / total;
    final int percent = (progress * 100).round();

    final members = group.members;
    const maxAvatars = 3;
    final shown = members.take(maxAvatars).toList();
    final extra = members.length - shown.length;

    return ExCard(
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                trackColor: c.surface3,
                progressColor: ExColors.brandGreen,
              ),
              child: Center(
                child: Text(
                  '$percent%',
                  style: ExText.mono(
                    size: 18,
                    color: c.textPrimary,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: ExSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed de $total concluídas',
                  style: ExText.h3(c.textPrimary),
                ),
                const SizedBox(height: ExSpace.s1),
                Text(
                  pending == 0
                      ? 'Tudo em dia'
                      : '$pending pendentes hoje',
                  style: ExText.body(c.textSecondary),
                ),
                if (!group.isPersonal && members.isNotEmpty) ...[
                  const SizedBox(height: ExSpace.s3),
                  Row(
                    children: [
                      for (var i = 0; i < shown.length; i++)
                        Align(
                          widthFactor: i == 0 ? 1.0 : 0.7,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.surface1, width: 2),
                            ),
                            child: CustomAvatar(
                              photoUrl: memberPhotoUrl(
                                shown[i],
                                profiles,
                                selfUid: selfUid,
                                selfPhotoUrl: selfPhotoUrl,
                              ),
                              displayName: memberDisplayLabel(shown[i], profiles),
                              radius: 13,
                            ),
                          ),
                        ),
                      if (extra > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: ExSpace.s2),
                          child: Text(
                            '+$extra',
                            style: ExText.body(c.textSecondary)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Anel de progresso circular (CustomPaint).
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = ExColors.gradientBrand.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
