import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/group_day_progress.dart';
import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../data/models/group_model.dart';
import '../../data/services/firebase_service.dart';
import '../../business_logic/group_type_migration.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../theme/group_icon.dart';
import '../widgets/create_group_sheet.dart';
import '../widgets/eximium/eximium.dart';
import 'group_detail_screen.dart';
import 'task_search_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(firebaseServiceProvider).ensureCollaborationBackfill();
      if (mounted) {
        await maybeSuggestContinuousGroupConversion(context, ref);
      }
    });
  }

  static String _groupCardSubtitle(GroupModel g, GroupProgress stats) {
    final cfg = g.typeConfig;
    if (!cfg.progressCard) {
      final active = stats.total - stats.completed;
      return '$active ${cfg.progressCardActiveLabel}';
    }
    return '${stats.total} tarefa${stats.total == 1 ? '' : 's'} · '
        '${stats.completed} concluída${stats.completed == 1 ? '' : 's'}';
  }

  Future<void> _openCreateGroupModal(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupSheet(),
    );

    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo criado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsStreamProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final progressByGroup = tasksAsync.whenData(
      (tasks) => computeGroupProgress(tasks),
    );

    final c = context.ex;

    return Scaffold(
      body: ExAppBackground(
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Grupos', style: ExText.h1(c.textPrimary)),
                    ),
                    _buildCircleSearchButton(),
                  ],
                ),
              ),
              Expanded(
                child: groupsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erro: $e')),
                  data: (groups) {
                    if (groups.isEmpty) {
                      return _buildEmptyState();
                    }

                    final progMap = progressByGroup.value ??
                        const <String, GroupProgress>{};

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
                      itemCount: groups.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: ExSpace.s3),
                      itemBuilder: (context, index) {
                        final g = groups[index];
                        final stats = progMap[g.id] ??
                            const GroupProgress(total: 0, completed: 0);
                        return _buildGroupCard(g, stats);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ExGlowFab.extended(
        icon: Icons.add_rounded,
        label: 'Novo grupo',
        onPressed: () => _openCreateGroupModal(context),
      ),
      floatingActionButtonLocation: const ExFabAboveBottomNavLocation(),
    );
  }

  Widget _buildCircleSearchButton() {
    final c = context.ex;
    return Tooltip(
      message: 'Buscar',
      child: Material(
        color: c.surface1,
        shape: CircleBorder(side: BorderSide(color: c.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TaskSearchScreen(),
              ),
            );
          },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.search_rounded, size: 19, color: c.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(GroupModel g, GroupProgress stats) {
    final c = context.ex;
    final Color groupColor = parseAppHexColor(g.color);
    final bool showProgress = g.typeConfig.progressCard;

    return ExCard(
      onTap: () {
        if (g.id.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível abrir este grupo. Volte e tente de novo.',
              ),
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(group: g),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  groupIconFromKey(g.icon),
                  color: groupColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: ExSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ExText.h3(c.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _groupCardSubtitle(g, stats),
                      style: ExText.body(c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ExSpace.s2),
              Icon(
                Icons.chevron_right_rounded,
                color: c.textMuted,
                size: 20,
              ),
            ],
          ),
          if (showProgress) ...[
            const SizedBox(height: 14),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = context.ex;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ExColors.brandGreen.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                boxShadow: ExEffects.glowSm,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: ExColors.brandGreen,
              ),
            ),
            const SizedBox(height: ExSpace.s4),
            Text(
              'Nenhum grupo ainda',
              style: ExText.h2(c.textPrimary),
            ),
            const SizedBox(height: ExSpace.s2),
            Text(
              'Crie seu primeiro grupo para organizar suas tarefas!',
              textAlign: TextAlign.center,
              style: ExText.body(c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
