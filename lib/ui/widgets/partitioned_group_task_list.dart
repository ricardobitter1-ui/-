import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/complete_task_action.dart';
import '../../business_logic/completed_tasks_sort.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../business_logic/task_list_partition.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../data/local/completed_section_prefs.dart';
import '../../data/models/group_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../utils/title_search_key.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'completed_section_tag_filter_bar.dart';
import 'completed_tasks_section_header.dart';
import 'eximium/eximium.dart';
import 'task_appear_motion.dart';
import 'task_card.dart';
import 'task_form_modal.dart';

/// Chave da secção "Sem etiqueta" no acordeão da lista do grupo.
const _kSemEtiquetaSection = '_sem_etiqueta';

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
  late bool _completedExpanded;
  String? _completedFilterTagId;

  final TextEditingController _searchController = TextEditingController();
  String _lastNormSearchQuery = '';
  Set<String> _collapsedSectionKeys = {};
  Set<String>? _collapsedSnapshotBeforeSearch;

  @override
  void initState() {
    super.initState();
    _completedExpanded = true;
    _searchController.addListener(_onSearchChanged);
    _loadPrefs();
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

  Future<void> _loadPrefs() async {
    final key = CompletedSectionPrefsKeys.groupDetail(widget.group.id);
    final v = await loadCompletedSectionExpanded(key);
    if (mounted) setState(() => _completedExpanded = v);
  }

  @override
  void didUpdateWidget(PartitionedGroupTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.id != widget.group.id) {
      _completedExpanded = true;
      _completedFilterTagId = null;
      _collapsedSectionKeys = {};
      _collapsedSnapshotBeforeSearch = null;
      _searchController.removeListener(_onSearchChanged);
      _lastNormSearchQuery = '';
      _searchController.clear();
      _searchController.addListener(_onSearchChanged);
      _loadPrefs();
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

  String? _effectiveCompletedFilter(
    List<TagModel> filterTags,
    String? stored,
  ) {
    if (stored == null) return null;
    return filterTags.any((t) => t.id == stored) ? stored : null;
  }

  List<TaskModel> _applyCompletedFilter(
    List<TaskModel> completed,
    String? tagId,
  ) {
    if (tagId == null) return completed;
    return completed.where((t) => t.tagIds.contains(tagId)).toList();
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
    final sectionKeys = _allActiveSectionKeys(activeFiltered, tagById);
    final showBulk = sectionKeys.length >= 2;

    final prefsKey = CompletedSectionPrefsKeys.groupDetail(widget.group.id);
    final filterTagChoices = _tagsUsedInCompleted(completedFiltered);
    final effectiveFilter =
        _effectiveCompletedFilter(filterTagChoices, _completedFilterTagId);
    final completedVisible =
        _applyCompletedFilter(completedFiltered, effectiveFilter);

    final showEmptyGroup =
        q.isEmpty && active.isEmpty && completed.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (widget.listPrefix != null) ...widget.listPrefix!,
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Pesquisar tarefas…',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            isDense: true,
          ),
          textInputAction: TextInputAction.search,
        ),
        if (showBulk)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 4,
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
        if (q.isNotEmpty && activeFiltered.isEmpty && active.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: Text(
              'Nenhuma tarefa ativa corresponde à pesquisa.',
              style: ExText.bodyLg(context.ex.textSecondary),
            ),
          ),
        if (showEmptyGroup)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 24),
            child: Text(
              kEmptyGroupTasksMessage,
              textAlign: TextAlign.center,
              style: ExText.bodyLg(context.ex.textSecondary),
            ),
          ),
        if (activeFiltered.isNotEmpty) ...[
          const SizedBox(height: ExSpace.s4),
          ExSectionLabel(label: 'Pendentes', count: activeFiltered.length),
          const SizedBox(height: ExSpace.s2),
        ],
        ..._buildActiveByTag(context, activeFiltered, profileMap, me, today),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 6),
          CompletedTasksSectionHeader(
            expanded: _completedExpanded,
            count: completedVisible.length,
            title: widget.group.typeConfig.completionLabel,
            onToggle: () async {
              final next = !_completedExpanded;
              setState(() => _completedExpanded = next);
              await saveCompletedSectionExpanded(prefsKey, next);
            },
          ),
          if (_completedExpanded) ...[
            if (filterTagChoices.isNotEmpty)
              CompletedSectionTagFilterBar(
                tags: filterTagChoices,
                selectedTagId: effectiveFilter,
                onSelect: (id) {
                  setState(() => _completedFilterTagId = id);
                },
              ),
            if (completedVisible.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Text(
                  'Nenhuma tarefa concluída com esta etiqueta.',
                  style: ExText.bodyLg(context.ex.textSecondary),
                ),
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
                _completedTaskCard(context, task, profileMap, me, today),
          ],
        ],
      ],
    );
  }
}
