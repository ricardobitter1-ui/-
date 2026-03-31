import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../business_logic/task_list_partition.dart';
import '../../data/local/completed_section_prefs.dart';
import '../../data/models/group_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import 'completed_section_tag_filter_bar.dart';
import 'completed_tasks_section_header.dart';
import 'task_appear_motion.dart';
import 'task_card.dart';
import 'task_form_modal.dart';

class PartitionedGroupTaskList extends ConsumerStatefulWidget {
  const PartitionedGroupTaskList({
    super.key,
    required this.group,
    required this.tasks,
    required this.tags,
  });

  final GroupModel group;
  final List<TaskModel> tasks;
  final List<TagModel> tags;

  @override
  ConsumerState<PartitionedGroupTaskList> createState() =>
      _PartitionedGroupTaskListState();
}

class _PartitionedGroupTaskListState
    extends ConsumerState<PartitionedGroupTaskList> {
  late bool _completedExpanded;
  String? _completedFilterTagId;

  @override
  void initState() {
    super.initState();
    _completedExpanded = true;
    _loadPrefs();
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFormModal(
        initialTask: task,
        forcedGroupId: widget.group.id,
        collaborationGroup: widget.group,
      ),
    );
  }

  Future<void> _confirmAndDeleteTask(
    BuildContext context,
    TaskModel task,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar tarefa?'),
        content: Text(
          'A tarefa "${task.title}" será removida. Pode tocar em Desfazer na mensagem que aparece em seguida.',
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
    await _deleteTask(context, task);
  }

  Future<void> _deleteTask(BuildContext context, TaskModel task) async {
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
              if (task.reminderType == 'datetime' && task.dueDate != null) {
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
          duration: const Duration(seconds: 5),
        ),
      );
    }

    await fs.deleteTask(task.id);
    await ns.cancelNotification(task.id.hashCode);
  }

  Widget _tagHeader(TagModel tag) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Color(tag.color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tag.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _plainSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }

  List<Widget> _buildActiveByTag(
    BuildContext context,
    List<TaskModel> active,
    Map<String, UserPublicProfile?> profileMap,
    User? me,
  ) {
    final tagById = {for (final t in widget.tags) t.id: t};
    bool hasResolvedTag(TaskModel t) =>
        t.tagIds.any((id) => tagById.containsKey(id));

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

    final semTag = active.where((t) => !hasResolvedTag(t)).toList();
    final out = <Widget>[];

    for (final tid in sortedTagIds) {
      final tag = tagById[tid]!;
      out.add(_tagHeader(tag));
      for (final task in active.where((t) => t.tagIds.contains(tid))) {
        out.add(
          TaskAppearMotion(
            key: ValueKey('g-${widget.group.id}-a-${task.id}-$tid'),
            child: TaskCard(
              task: task,
              assigneeProfiles: profileMap,
              selfUid: me?.uid,
              selfPhotoUrl: me?.photoURL,
              onToggle: () {
                ref
                    .read(firebaseServiceProvider)
                    .toggleTaskCompletion(task.id, task.isCompleted);
              },
              onEdit: () => _openEdit(context, task),
              onDelete: () => _confirmAndDeleteTask(context, task),
            ),
          ),
        );
        out.add(const SizedBox(height: 10));
      }
    }

    if (semTag.isNotEmpty) {
      out.add(_plainSectionHeader('Sem etiqueta'));
      for (final task in semTag) {
        out.add(
          TaskAppearMotion(
            key: ValueKey('g-${widget.group.id}-a-${task.id}-sem'),
            child: TaskCard(
              task: task,
              assigneeProfiles: profileMap,
              selfUid: me?.uid,
              selfPhotoUrl: me?.photoURL,
              onToggle: () {
                ref
                    .read(firebaseServiceProvider)
                    .toggleTaskCompletion(task.id, task.isCompleted);
              },
              onEdit: () => _openEdit(context, task),
              onDelete: () => _confirmAndDeleteTask(context, task),
            ),
          ),
        );
        out.add(const SizedBox(height: 10));
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

    final (:active, :completed) = partitionTasksByCompletion(widget.tasks);
    final prefsKey = CompletedSectionPrefsKeys.groupDetail(widget.group.id);
    final filterTagChoices = _tagsUsedInCompleted(completed);
    final effectiveFilter =
        _effectiveCompletedFilter(filterTagChoices, _completedFilterTagId);
    final completedVisible =
        _applyCompletedFilter(completed, effectiveFilter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        ..._buildActiveByTag(context, active, profileMap, me),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 6),
          CompletedTasksSectionHeader(
            expanded: _completedExpanded,
            count: completedVisible.length,
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              )
            else
              for (final task in completedVisible)
                TaskAppearMotion(
                  key: ValueKey('g-${widget.group.id}-c-${task.id}'),
                  child: TaskCard(
                    task: task,
                    tagChips: _tagsForTask(task),
                    assigneeProfiles: profileMap,
                    selfUid: me?.uid,
                    selfPhotoUrl: me?.photoURL,
                    onToggle: () {
                      ref
                          .read(firebaseServiceProvider)
                          .toggleTaskCompletion(task.id, task.isCompleted);
                    },
                    onEdit: () => _openEdit(context, task),
                    onDelete: () => _confirmAndDeleteTask(context, task),
                  ),
                ),
          ],
        ],
      ],
    );
  }
}
