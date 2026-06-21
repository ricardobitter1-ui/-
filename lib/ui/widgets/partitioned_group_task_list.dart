import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/complete_task_action.dart';
import '../../business_logic/completed_tasks_sort.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../business_logic/task_list_partition.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../business_logic/voice_shopping_list_context.dart';
import '../../data/models/group_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/shopping_list_cleanup_service.dart';
import '../../data/services/voice_api_config.dart';
import '../../utils/title_search_key.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'eximium/eximium.dart';
import 'shopping_list_cleanup_sheet.dart';
import 'task_appear_motion.dart';
import 'task_card.dart';
import 'task_form_modal.dart';

/// Chave da secção "Sem etiqueta" no acordeão da lista do grupo.
const _kSemEtiquetaSection = '_sem_etiqueta';

/// Aba ativa na lista do grupo: pendentes ou concluídas.
enum _GroupTaskTab { pending, completed }

/// Mensagem quando o grupo ainda não tem tarefas (lista vazia, sem pesquisa).
const kEmptyGroupTasksMessage =
    'Nenhuma tarefa neste grupo ainda.\nCrie a primeira para validar o stream!';

class PartitionedGroupTaskList extends ConsumerStatefulWidget {
  const PartitionedGroupTaskList({
    super.key,
    required this.group,
    required this.tasks,
    required this.tags,
    this.listPrefix,
  });

  final GroupModel group;
  final List<TaskModel> tasks;
  final List<TagModel> tags;

  /// Widgets no topo da lista rolável (ex.: membros), antes da pesquisa.
  final List<Widget>? listPrefix;

  @override
  ConsumerState<PartitionedGroupTaskList> createState() =>
      _PartitionedGroupTaskListState();
}

class _PartitionedGroupTaskListState
    extends ConsumerState<PartitionedGroupTaskList> {
  String? _completedFilterTagId;
  String? _activeFilterTagId;
  _GroupTaskTab _tab = _GroupTaskTab.pending;

  final TextEditingController _searchController = TextEditingController();
  String _lastNormSearchQuery = '';
  Set<String> _collapsedSectionKeys = {};
  Set<String>? _collapsedSnapshotBeforeSearch;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = normalizeTitleSearchKey(_searchController.text);
    if (q == _lastNormSearchQuery) return;
    setState(() {
      if (_lastNormSearchQuery.isEmpty && q.isNotEmpty) {
        _collapsedSnapshotBeforeSearch =
            Set<String>.from(_collapsedSectionKeys);
        _collapsedSectionKeys = {};
      } else if (_lastNormSearchQuery.isNotEmpty && q.isEmpty) {
        final snap = _collapsedSnapshotBeforeSearch;
        if (snap != null) {
          _collapsedSectionKeys = Set<String>.from(snap);
          _collapsedSnapshotBeforeSearch = null;
        }
      }
      _lastNormSearchQuery = q;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PartitionedGroupTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _completedFilterTagId = null;
      _activeFilterTagId = null;
      _tab = _GroupTaskTab.pending;
      _collapsedSectionKeys = {};
      _collapsedSnapshotBeforeSearch = null;
      _searchController.removeListener(_onSearchChanged);
      _lastNormSearchQuery = '';
      _searchController.clear();
      _searchController.addListener(_onSearchChanged);
    }
  }

  List<TagModel> _tagsForTask(TaskModel task) {
    final byId = {for (final t in widget.tags) t.id: t};
    return task.tagIds.map((id) => byId[id]).whereType<TagModel>().toList();
  }

  List<TagModel> _tagsUsedInCompleted(List<TaskModel> completed) {
    final byId = {for (final t in widget.tags) t.id: t};
    final seen = <String>{};
    final out = <TagModel>[];
    for (final task in completed) {
      for (final id in task.tagIds) {
        final tag = byId[id];
        if (tag != null && seen.add(id)) {
          out.add(tag);
        }
      }
    }
    return out;
  }

  List<TaskModel> _applyCompletedFilter(
    List<TaskModel> completed,
    String? tagId,
  ) {
    if (tagId == null) return completed;
    return completed.where((t) => t.tagIds.contains(tagId)).toList();
  }

  /// Etiquetas (resolvidas) presentes em [tasks], na ordem de descoberta.
  List<TagModel> _tagsUsedIn(List<TaskModel> tasks) {
    final byId = {for (final t in widget.tags) t.id: t};
    final seen = <String>{};
    final out = <TagModel>[];
    for (final task in tasks) {
      for (final id in task.tagIds) {
        final tag = byId[id];
        if (tag != null && seen.add(id)) out.add(tag);
      }
    }
    return out;
  }

  String? _effectiveTagFilter(List<TagModel> choices, String? stored) {
    if (stored == null) return null;
    return choices.any((t) => t.id == stored) ? stored : null;
  }

  List<TaskModel> _applyTagFilter(List<TaskModel> tasks, String? tagId) {
    if (tagId == null) return tasks;
    return tasks.where((t) => t.tagIds.contains(tagId)).toList();
  }

  /// Abre a folha de filtro por etiqueta para a aba atual.
  Future<void> _openFilterSheet(
    BuildContext context,
    List<TagModel> choices,
    String? selected,
  ) async {
    final c = context.ex;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ExRadius.xl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: c.surface3,
                        borderRadius: BorderRadius.circular(ExRadius.pill),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: ExSpace.s3, left: 2),
                    child: Text(
                      'Filtrar por etiqueta',
                      style: ExText.h2(c.textPrimary),
                    ),
                  ),
                  Wrap(
                    spacing: ExSpace.s2,
                    runSpacing: ExSpace.s2,
                    children: [
                      _FilterChoiceChip(
                        label: 'Todas',
                        selected: selected == null,
                        onTap: () => Navigator.pop(ctx, null),
                      ),
                      for (final t in choices)
                        _FilterChoiceChip(
                          label: t.name,
                          dotColor: Color(t.color),
                          selected: selected == t.id,
                          onTap: () => Navigator.pop(
                            ctx,
                            selected == t.id ? null : t.id,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    // `picked == null` é ambíguo (cancelou ou escolheu "Todas"); o chip "Todas"
    // fecha com null e o utilizador raramente cancela, então tratamos null como
    // "limpar filtro".
    setState(() {
      if (_tab == _GroupTaskTab.pending) {
        _activeFilterTagId = picked;
      } else {
        _completedFilterTagId = picked;
      }
    });
  }

  void _openEdit(BuildContext context, TaskModel task) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormModal(
        initialTask: task,
        forcedGroupId: widget.group.id,
        collaborationGroup: widget.group,
      ),
    );
  }

  Future<void> _deleteTask(BuildContext context, TaskModel task) async {
    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          content: Text('Tarefa "${task.title}" removida.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              final newId = await fs.addTask(task);
              await ns.syncTaskDatetimeReminders(task.copyWith(id: newId));
            },
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2B2D42),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await fs.deleteTask(task.id);
    await ns.cancelAllTaskReminderSlots(task.id);
  }

  bool _hasResolvedTag(TaskModel t, Map<String, TagModel> tagById) =>
      t.tagIds.any((id) => tagById.containsKey(id));

  Set<String> _allActiveSectionKeys(
    List<TaskModel> active,
    Map<String, TagModel> tagById,
  ) {
    final tagIdsInUse = <String>{};
    for (final t in active) {
      for (final id in t.tagIds) {
        if (tagById.containsKey(id)) tagIdsInUse.add(id);
      }
    }
    final keys = tagIdsInUse;
    if (active.any((t) => !_hasResolvedTag(t, tagById))) {
      keys.add(_kSemEtiquetaSection);
    }
    return keys;
  }

  void _toggleSection(String key) {
    setState(() {
      if (_collapsedSectionKeys.contains(key)) {
        _collapsedSectionKeys.remove(key);
      } else {
        _collapsedSectionKeys = {..._collapsedSectionKeys, key};
      }
    });
  }

  Widget _collapsibleSectionHeader({
    required String sectionKey,
    required bool expanded,
    required Widget titleRow,
  }) {
    return InkWell(
      onTap: () => _toggleSection(sectionKey),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Row(
          children: [
            AnimatedRotation(
              turns: expanded ? 0 : -0.25,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more_rounded,
                size: 22,
                color: context.ex.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: titleRow),
          ],
        ),
      ),
    );
  }

  Widget _tagTitleRow(TagModel tag, int count) {
    final c = context.ex;
    return Row(
      children: [
        ExDot(color: Color(tag.color), size: 10),
        const SizedBox(width: 8),
        Expanded(
          child: Text(tag.name, style: ExText.h3(c.textPrimary)),
        ),
        Text(
          '$count',
          style: ExText.mono(size: 13, color: c.textSecondary),
        ),
      ],
    );
  }

  Widget _semEtiquetaTitleRow(BuildContext context, int count) {
    final c = context.ex;
    return Row(
      children: [
        Expanded(
          child: Text('Sem etiqueta', style: ExText.h3(c.textPrimary)),
        ),
        Text(
          '$count',
          style: ExText.mono(size: 13, color: c.textSecondary),
        ),
      ],
    );
  }

  Future<void> _toggleGroupTask(
    BuildContext context,
    TaskModel task,
    DateTime calendarDay,
  ) async {
    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);
    final ok = await completeTaskToggle(
      fs: fs,
      ns: ns,
      task: task,
      occurrenceCalendarDay: calendarDay,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Essa tarefa não se repete neste dia.',
          ),
        ),
      );
    }
  }

  List<Widget> _buildCompletedByTag(
    BuildContext context,
    List<TaskModel> completed,
    Map<String, UserPublicProfile?> profileMap,
    User? me,
    DateTime calendarDay,
  ) {
    final tagById = {for (final t in widget.tags) t.id: t};

    final tagIdsInUse = <String>{};
    for (final t in completed) {
      for (final id in t.tagIds) {
        if (tagById.containsKey(id)) tagIdsInUse.add(id);
      }
    }
    final sortedTagIds = tagIdsInUse.toList()
      ..sort(
        (a, b) => tagById[a]!
            .name
            .toLowerCase()
            .compareTo(tagById[b]!.name.toLowerCase()),
      );

    final semTag =
        completed.where((t) => !_hasResolvedTag(t, tagById)).toList();
    final out = <Widget>[];

    for (final tid in sortedTagIds) {
      final tag = tagById[tid]!;
      final expanded = !_collapsedSectionKeys.contains('c-$tid');
      final countInTag = completed.where((t) => t.tagIds.contains(tid)).length;
      out.add(
        _collapsibleSectionHeader(
          sectionKey: 'c-$tid',
          expanded: expanded,
          titleRow: _tagTitleRow(tag, countInTag),
        ),
      );
      if (expanded) {
        for (final task in completed.where((t) => t.tagIds.contains(tid))) {
          out.add(_completedTaskCard(
            context,
            task,
            profileMap,
            me,
            calendarDay,
          ));
          out.add(const SizedBox(height: 10));
        }
      }
    }

    if (semTag.isNotEmpty) {
      final expanded =
          !_collapsedSectionKeys.contains('c-$_kSemEtiquetaSection');
      out.add(
        _collapsibleSectionHeader(
          sectionKey: 'c-$_kSemEtiquetaSection',
          expanded: expanded,
          titleRow: _semEtiquetaTitleRow(context, semTag.length),
        ),
      );
      if (expanded) {
        for (final task in semTag) {
          out.add(_completedTaskCard(
            context,
            task,
            profileMap,
            me,
            calendarDay,
          ));
          out.add(const SizedBox(height: 10));
        }
      }
    }

    return out;
  }

  Widget _completedTaskCard(
    BuildContext context,
    TaskModel task,
    Map<String, UserPublicProfile?> profileMap,
    User? me,
    DateTime calendarDay,
  ) {
    return TaskAppearMotion(
      key: ValueKey('g-${widget.group.id}-c-${task.id}'),
      child: TaskCard(
        task: task,
        groupAccentColor: parseAppHexColor(widget.group.color),
        groupIconKey: widget.group.icon,
        tagChips: _tagsForTask(task),
        displayDueOverride: displayDueForTaskOnCalendarDay(task, calendarDay),
        isCompletedOverride:
            isOccurrenceCompletedOnCalendarDay(task, calendarDay),
        assigneeProfiles: profileMap,
        selfUid: me?.uid,
        selfPhotoUrl: me?.photoURL,
        onToggle: () => _toggleGroupTask(context, task, calendarDay),
        onEdit: () => _openEdit(context, task),
        onDelete: () => _deleteTask(context, task),
      ),
    );
  }

  Future<void> _runAutoCleanup(BuildContext context) async {
    if (!VoiceApiConfig.hasGroqKey && !VoiceApiConfig.hasOpenRouterKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Limpeza automática precisa de GROQ_API_KEY ou OPENROUTER_API_KEY em secrets.json.',
          ),
        ),
      );
      return;
    }

    final service = ShoppingListCleanupService();
    try {
      await runShoppingListCleanupFlow(
        context: context,
        tasks: widget.tasks,
        tags: widget.tags,
        buildPlan: () => service.buildPlan(
          tasks: widget.tasks,
          tags: widget.tags,
        ),
        applyPlan: (plan) => applyShoppingListCleanupPlan(
          plan: plan,
          firebase: ref.read(firebaseServiceProvider),
          notification: ref.read(notificationServiceProvider),
        ),
      );
    } finally {
      service.dispose();
    }
  }

  List<Widget> _buildActiveByTag(
    BuildContext context,
    List<TaskModel> active,
    Map<String, UserPublicProfile?> profileMap,
    User? me,
    DateTime calendarDay,
  ) {
    final tagById = {for (final t in widget.tags) t.id: t};

    final tagIdsInUse = <String>{};
    for (final t in active) {
      for (final id in t.tagIds) {
        if (tagById.containsKey(id)) tagIdsInUse.add(id);
      }
    }
    final sortedTagIds = tagIdsInUse.toList()
      ..sort(
        (a, b) => tagById[a]!
            .name
            .toLowerCase()
            .compareTo(tagById[b]!.name.toLowerCase()),
      );

    final semTag =
        active.where((t) => !_hasResolvedTag(t, tagById)).toList();
    final out = <Widget>[];

    for (final tid in sortedTagIds) {
      final tag = tagById[tid]!;
      final expanded = !_collapsedSectionKeys.contains(tid);
      final countInTag = active.where((t) => t.tagIds.contains(tid)).length;
      out.add(
        _collapsibleSectionHeader(
          sectionKey: tid,
          expanded: expanded,
          titleRow: _tagTitleRow(tag, countInTag),
        ),
      );
      if (expanded) {
        for (final task in active.where((t) => t.tagIds.contains(tid))) {
          out.add(
            TaskAppearMotion(
              key: ValueKey('g-${widget.group.id}-a-${task.id}-$tid'),
              child: TaskCard(
                task: task,
                groupAccentColor: parseAppHexColor(widget.group.color),
                groupIconKey: widget.group.icon,
                displayDueOverride:
                    displayDueForTaskOnCalendarDay(task, calendarDay),
                isCompletedOverride:
                    isOccurrenceCompletedOnCalendarDay(task, calendarDay),
                assigneeProfiles: profileMap,
                selfUid: me?.uid,
                selfPhotoUrl: me?.photoURL,
                onToggle: () => _toggleGroupTask(context, task, calendarDay),
                onEdit: () => _openEdit(context, task),
                onDelete: () => _deleteTask(context, task),
              ),
            ),
          );
          out.add(const SizedBox(height: 10));
        }
      }
    }

    if (semTag.isNotEmpty) {
      final expanded = !_collapsedSectionKeys.contains(_kSemEtiquetaSection);
      out.add(
        _collapsibleSectionHeader(
          sectionKey: _kSemEtiquetaSection,
          expanded: expanded,
          titleRow: _semEtiquetaTitleRow(context, semTag.length),
        ),
      );
      if (expanded) {
        for (final task in semTag) {
          out.add(
            TaskAppearMotion(
              key: ValueKey('g-${widget.group.id}-a-${task.id}-sem'),
              child: TaskCard(
                task: task,
                groupAccentColor: parseAppHexColor(widget.group.color),
                groupIconKey: widget.group.icon,
                displayDueOverride:
                    displayDueForTaskOnCalendarDay(task, calendarDay),
                isCompletedOverride:
                    isOccurrenceCompletedOnCalendarDay(task, calendarDay),
                assigneeProfiles: profileMap,
                selfUid: me?.uid,
                selfPhotoUrl: me?.photoURL,
                onToggle: () => _toggleGroupTask(context, task, calendarDay),
                onEdit: () => _openEdit(context, task),
                onDelete: () => _deleteTask(context, task),
              ),
            ),
          );
          out.add(const SizedBox(height: 10));
        }
      }
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final memberKey = memberUidsCacheKey(widget.group.members);
    final profileMap =
        ref.watch(groupMemberProfilesProvider(memberKey)).value ?? {};
    final me = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final (:active, :completed) =
        partitionTasksByCompletionForCalendarDay(widget.tasks, today);
    final completedSorted = List<TaskModel>.from(completed);
    if (widget.group.typeConfig.reAdd) {
      sortCompletedByRecency(completedSorted);
    }
    final q = normalizeTitleSearchKey(_searchController.text);
    final activeFiltered = q.isEmpty
        ? active
        : active.where((t) => t.titleSearchKey.contains(q)).toList();
    final completedFiltered = q.isEmpty
        ? completedSorted
        : completedSorted.where((t) => t.titleSearchKey.contains(q)).toList();

    final tagById = {for (final t in widget.tags) t.id: t};

    final activeTagChoices = _tagsUsedIn(activeFiltered);
    final completedTagChoices = _tagsUsedInCompleted(completedFiltered);
    final activeFilter = _effectiveTagFilter(activeTagChoices, _activeFilterTagId);
    final completedFilter =
        _effectiveTagFilter(completedTagChoices, _completedFilterTagId);
    final activeVisible = _applyTagFilter(activeFiltered, activeFilter);
    final completedVisible =
        _applyCompletedFilter(completedFiltered, completedFilter);

    final sectionKeys = _allActiveSectionKeys(activeVisible, tagById);
    final showBulk = sectionKeys.length >= 2;

    final showEmptyGroup = q.isEmpty && active.isEmpty && completed.isEmpty;
    final showAutoCleanup =
        VoiceShoppingListContext.isShoppingListGroupName(widget.group.name);

    final isPending = _tab == _GroupTaskTab.pending;
    final currentFilter = isPending ? activeFilter : completedFilter;
    final currentChoices = isPending ? activeTagChoices : completedTagChoices;
    final searchHint = widget.group.typeConfig.continuous || showAutoCleanup
        ? 'Buscar item…'
        : 'Pesquisar tarefas…';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (widget.listPrefix != null) ...widget.listPrefix!,
        // ── Barra de ferramentas: busca + IA + filtro ──
        Row(
          children: [
            Expanded(child: _buildSearchPill(context, searchHint)),
            if (showAutoCleanup) ...[
              const SizedBox(width: ExSpace.s2 + 1),
              _ToolbarIconButton(
                icon: Icons.auto_awesome_rounded,
                tooltip: 'Limpeza automática',
                color: context.ex.infoText,
                background: ExColors.lavender.withValues(alpha: 0.10),
                borderColor: ExColors.lavender.withValues(alpha: 0.40),
                onTap: () => _runAutoCleanup(context),
              ),
            ],
            const SizedBox(width: ExSpace.s2 + 1),
            _ToolbarIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Filtrar e ordenar',
              color: currentFilter != null
                  ? context.ex.textAccent
                  : context.ex.textSecondary,
              background: currentFilter != null
                  ? ExColors.brandGreen.withValues(alpha: 0.12)
                  : context.ex.surface2,
              borderColor: currentFilter != null
                  ? context.ex.borderAccent
                  : null,
              onTap: () =>
                  _openFilterSheet(context, currentChoices, currentFilter),
            ),
          ],
        ),
        const SizedBox(height: ExSpace.s3),
        // ── Abas Pendentes / Concluídas ──
        Row(
          children: [
            _TabPill(
              label: 'Pendentes',
              count: activeFiltered.length,
              selected: isPending,
              onTap: () => setState(() => _tab = _GroupTaskTab.pending),
            ),
            const SizedBox(width: ExSpace.s2),
            _TabPill(
              label: 'Concluídas',
              count: completedFiltered.length,
              selected: !isPending,
              onTap: () => setState(() => _tab = _GroupTaskTab.completed),
            ),
          ],
        ),
        if (currentFilter != null) ...[
          const SizedBox(height: ExSpace.s3),
          _activeFilterRow(context, tagById[currentFilter]),
        ],
        if (isPending && showBulk)
          Padding(
            padding: const EdgeInsets.only(top: ExSpace.s1),
            child: Wrap(
              spacing: ExSpace.s1,
              children: [
                TextButton(
                  onPressed: () => setState(() => _collapsedSectionKeys = {}),
                  child: const Text('Abrir todas'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _collapsedSectionKeys = Set<String>.from(sectionKeys);
                  }),
                  child: const Text('Fechar todas'),
                ),
              ],
            ),
          ),
        const SizedBox(height: ExSpace.s3),
        // ── Conteúdo da aba ──
        if (showEmptyGroup)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
            child: Text(
              kEmptyGroupTasksMessage,
              textAlign: TextAlign.center,
              style: ExText.bodyLg(context.ex.textSecondary),
            ),
          )
        else if (isPending) ...[
          if (q.isNotEmpty && activeFiltered.isEmpty && active.isNotEmpty)
            _tabEmptyMessage(
              context,
              'Nenhuma tarefa pendente corresponde à pesquisa.',
            )
          else if (activeVisible.isEmpty && currentFilter != null)
            _tabEmptyMessage(
              context,
              'Nenhuma tarefa pendente com esta etiqueta.',
            )
          else if (activeVisible.isEmpty)
            _tabEmptyMessage(context, 'Tudo concluído por aqui! 🎉')
          else
            ..._buildActiveByTag(context, activeVisible, profileMap, me, today),
        ] else ...[
          if (completedFiltered.isEmpty)
            _tabEmptyMessage(context, 'Nenhuma tarefa concluída ainda.')
          else if (completedVisible.isEmpty)
            _tabEmptyMessage(
              context,
              'Nenhuma tarefa concluída com esta etiqueta.',
            )
          else if (widget.group.typeConfig.continuous)
            ..._buildCompletedByTag(
              context,
              completedVisible,
              profileMap,
              me,
              today,
            )
          else
            for (final task in completedVisible)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _completedTaskCard(context, task, profileMap, me, today),
              ),
        ],
      ],
    );
  }

  /// Campo de busca em cápsula (surface2), alinhado ao mock.
  Widget _buildSearchPill(BuildContext context, String hint) {
    final c = context.ex;
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 15, right: 6),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(ExRadius.pill),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: c.textMuted),
          const SizedBox(width: ExSpace.s2),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: ExText.bodyLg(c.textPrimary),
              cursorColor: c.textAccent,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: ExText.bodyLg(c.textMuted),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              icon: Icon(Icons.clear_rounded, color: c.textMuted),
              onPressed: () => _searchController.clear(),
            ),
        ],
      ),
    );
  }

  Widget _activeFilterRow(BuildContext context, TagModel? tag) {
    final c = context.ex;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(11, 6, 8, 6),
          decoration: BoxDecoration(
            color: ExColors.brandGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(ExRadius.pill),
            border: Border.all(color: c.borderAccent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tag != null) ...[
                ExDot(color: Color(tag.color), size: 8),
                const SizedBox(width: 6),
              ],
              Text(
                tag?.name ?? 'Etiqueta',
                style: ExText.body(c.textAccent)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(width: 2),
              InkWell(
                onTap: () => setState(() {
                  if (_tab == _GroupTaskTab.pending) {
                    _activeFilterTagId = null;
                  } else {
                    _completedFilterTagId = null;
                  }
                }),
                customBorder: const CircleBorder(),
                child: Icon(Icons.close_rounded, size: 15, color: c.textAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabEmptyMessage(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: ExText.bodyLg(context.ex.textSecondary),
      ),
    );
  }
}

/// Botão de ação da barra de ferramentas (44×44, cápsula).
class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.background,
    required this.onTap,
    this.borderColor,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color background;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExRadius.pill),
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

/// Pílula de aba (Pendentes / Concluídas) com contagem.
class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final Color bg = selected ? c.textPrimary : c.surface2;
    final Color fg = selected ? c.surface0 : c.textSecondary;
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
          child: Text(
            '$label · $count',
            style: ExText.body(fg).copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip de escolha de etiqueta na folha de filtro.
class _FilterChoiceChip extends StatelessWidget {
  const _FilterChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final Color fg = selected ? c.textAccent : c.textSecondary;
    return Material(
      color: selected
          ? ExColors.brandGreen.withValues(alpha: 0.14)
          : c.surface2,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? c.borderAccent : c.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                ExDot(color: dotColor!, size: 8),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: ExText.body(fg)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
