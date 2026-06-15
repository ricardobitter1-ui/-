// EasyDayWidget não é exportado pelo pacote público.
// ignore: implementation_imports
import 'package:easy_date_timeline/src/widgets/easy_day_widget/easy_day_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../../business_logic/complete_task_action.dart';
import '../../business_logic/overdue_occurrences.dart';
import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/task_day_visibility.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../utils/calendar_day_key.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../data/models/group_model.dart';
import '../../data/services/auth_service.dart';
import '../../business_logic/task_list_partition.dart';
import '../../business_logic/task_schedule_sort.dart';
import '../../data/models/task_model.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../widgets/eximium/eximium.dart';
import '../widgets/expandable_create_task_fab.dart';
import '../widgets/task_appear_motion.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';
import '../widgets/voice_task_recording_sheet.dart';

enum TaskFilterType { today, scheduled, all, overdue }

class FilteredTaskListScreen extends ConsumerStatefulWidget {
  final TaskFilterType filter;

  const FilteredTaskListScreen({super.key, required this.filter});

  @override
  ConsumerState<FilteredTaskListScreen> createState() =>
      _FilteredTaskListScreenState();
}

class _FilteredTaskListScreenState
    extends ConsumerState<FilteredTaskListScreen> {
  /// Cor do número do dia no timeline quando o fundo ativo é claro (EasyDateTimeLine).
  static const Color _timelineDayNumOnLight = Color(0xff0D0C0D);

  DateTime _selectedDate = DateTime.now();

  EasyDayProps _buildDayProps(ExColors c) => EasyDayProps(
        width: 68,
        height: 112,
        dayStructure: DayStructure.dayStrDayNum,
        activeDayStyle: DayStyle(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(ExRadius.md)),
            color: ExColors.brandGreen,
            boxShadow: [
              BoxShadow(
                color: ExColors.brandGreen.withValues(alpha: 0.35),
                blurRadius: 16,
              ),
            ],
          ),
          dayNumStyle: ExText.h3(_timelineDayNumOnLight),
          dayStrStyle: ExText.label(_timelineDayNumOnLight),
        ),
        inactiveDayStyle: DayStyle(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(ExRadius.md)),
            color: c.surface2,
            border: Border.all(color: c.border),
          ),
          dayNumStyle: ExText.h3(c.textSecondary),
          dayStrStyle: ExText.label(c.textMuted),
        ),
      );

  String get _title {
    switch (widget.filter) {
      case TaskFilterType.today:
        return 'Hoje';
      case TaskFilterType.scheduled:
        return 'Agendadas';
      case TaskFilterType.all:
        return 'Todas';
      case TaskFilterType.overdue:
        return 'Atrasadas';
    }
  }

  static String _assigneeKeyForFiltered(List<TaskModel> tasks) {
    final ids = <String>{};
    for (final t in tasks) {
      ids.addAll(t.assigneeIds);
    }
    return memberUidsCacheKey(ids);
  }

  static String? _resolveGroupLabel(TaskModel t, Map<String, GroupModel> byId) {
    final id = t.groupId?.trim();
    if (id == null || id.isEmpty) return null;
    return byId[id]?.name ?? 'Grupo';
  }

  static Color? _resolveGroupAccent(TaskModel t, Map<String, GroupModel> byId) {
    final id = t.groupId?.trim();
    if (id == null || id.isEmpty) return null;
    final g = byId[id];
    if (g == null) return null;
    return parseAppHexColor(g.color);
  }

  static String? _resolveGroupIconKey(TaskModel t, Map<String, GroupModel> byId) {
    final id = t.groupId?.trim();
    if (id == null || id.isEmpty) return null;
    return byId[id]?.icon;
  }

  List<TaskModel> _applyFilter(List<TaskModel> all) {
    switch (widget.filter) {
      case TaskFilterType.today:
        return all
            .where((t) => taskVisibleOnDay(t, _selectedDate))
            .toList();
      case TaskFilterType.scheduled:
        final list = all.where(taskMatchesScheduledFilter).toList();
        sortTasksByScheduleOrder(list);
        return list;
      case TaskFilterType.all:
        return all;
      case TaskFilterType.overdue:
        // Lista real vem de [collectOverdueOccurrenceRows] no build.
        return [];
    }
  }

  List<TaskModel> _tasksForAssigneeKey(List<TaskModel> all) {
    final now = DateTime.now();
    switch (widget.filter) {
      case TaskFilterType.overdue:
        return collectOverdueOccurrenceRows(all, now).map((r) => r.task).toList();
      case TaskFilterType.today:
        final f = all.where((t) => taskVisibleOnDay(t, _selectedDate)).toList();
        final p = partitionTasksByCompletionForCalendarDay(f, _selectedDate);
        return [...p.active, ...p.completed];
      default:
        return _applyFilter(all);
    }
  }

  Future<void> _toggleTaskForList(
    TaskModel task, {
    DateTime? occurrenceCalendarDay,
  }) async {
    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);
    final ok = await completeTaskToggle(
      fs: fs,
      ns: ns,
      task: task,
      occurrenceCalendarDay: occurrenceCalendarDay,
    );
    if (!ok && occurrenceCalendarDay == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Essa tarefa não se repete neste dia. Toque no dia certo no calendário para concluí-la.',
          ),
        ),
      );
    }
  }

  void _openTaskForm({TaskModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormModal(initialTask: task),
    );
  }

  void _openVoiceTaskRecording() {
    final groups = ref.read(groupsStreamProvider).value ?? const [];
    showVoiceTaskRecordingSheet(
      context: context,
      groups: groups,
    );
  }

  Future<void> _deleteTask(TaskModel task) async {
    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);

    if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final me = ref.watch(authStateProvider).value;

    final assigneeKey = tasksAsync.maybeWhen(
      data: (all) => _assigneeKeyForFiltered(_tasksForAssigneeKey(all)),
      orElse: () => '',
    );
    final assigneeProfileMap =
        ref.watch(groupMemberProfilesProvider(assigneeKey)).value ?? {};
    final groupsList =
        ref.watch(groupsStreamProvider).value ?? const <GroupModel>[];
    final groupById = {for (final g in groupsList) g.id: g};

    final showCalendar = widget.filter == TaskFilterType.today;

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (allTasks) {
          if (widget.filter == TaskFilterType.overdue) {
            final rows = collectOverdueOccurrenceRows(allTasks, DateTime.now());
            return CustomScrollView(
              slivers: [
                if (rows.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final row = rows[index];
                          final task = row.task;
                          return TaskAppearMotion(
                            key: ValueKey(
                              'fl-o-${task.id}-${localCalendarDayKey(row.day)}',
                            ),
                            child: TaskCard(
                              task: task,
                              displayDueOverride:
                                  displayDueForTaskOnCalendarDay(task, row.day),
                              assigneeProfiles: assigneeProfileMap,
                              selfUid: me?.uid,
                              selfPhotoUrl: me?.photoURL,
                              groupLabel:
                                  _resolveGroupLabel(task, groupById),
                              groupAccentColor:
                                  _resolveGroupAccent(task, groupById),
                              groupIconKey:
                                  _resolveGroupIconKey(task, groupById),
                              onToggle: () => _toggleTaskForList(
                                task,
                                occurrenceCalendarDay: row.day,
                              ),
                              onEdit: () => _openTaskForm(task: task),
                              onDelete: () => _deleteTask(task),
                            ),
                          );
                        },
                        childCount: rows.length,
                      ),
                    ),
                  ),
              ],
            );
          }

          final filtered = _applyFilter(allTasks);
          final (:active, :completed) = widget.filter == TaskFilterType.today
              ? partitionTasksByCompletionForCalendarDay(
                  filtered, _selectedDate)
              : partitionTasksByCompletion(filtered);
          final isTodayFilter = widget.filter == TaskFilterType.today;

          return CustomScrollView(
            slivers: [
              if (showCalendar) _buildCalendar(allTasks),
              if (active.isEmpty && completed.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = active[index];
                        return TaskAppearMotion(
                          key: ValueKey('fl-a-${task.id}'),
                          child: TaskCard(
                            task: task,
                            displayDueOverride: isTodayFilter
                                ? displayDueForTaskOnCalendarDay(
                                    task, _selectedDate)
                                : null,
                            isCompletedOverride: isTodayFilter
                                ? isOccurrenceCompletedOnCalendarDay(
                                    task, _selectedDate)
                                : null,
                            assigneeProfiles: assigneeProfileMap,
                            selfUid: me?.uid,
                            selfPhotoUrl: me?.photoURL,
                            groupLabel: _resolveGroupLabel(task, groupById),
                            groupAccentColor:
                                _resolveGroupAccent(task, groupById),
                            groupIconKey:
                                _resolveGroupIconKey(task, groupById),
                            onToggle: () => _toggleTaskForList(
                              task,
                              occurrenceCalendarDay: isTodayFilter
                                  ? _selectedDate
                                  : null,
                            ),
                            onEdit: () => _openTaskForm(task: task),
                            onDelete: () => _deleteTask(task),
                          ),
                        );
                      },
                      childCount: active.length,
                    ),
                  ),
                ),
                if (completed.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: ExSectionLabel(
                        label: 'Concluídas',
                        count: completed.length,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = completed[index];
                          return TaskAppearMotion(
                            key: ValueKey('fl-c-${task.id}'),
                            child: TaskCard(
                              task: task,
                              displayDueOverride: isTodayFilter
                                  ? displayDueForTaskOnCalendarDay(
                                      task, _selectedDate)
                                  : null,
                              isCompletedOverride: isTodayFilter
                                  ? isOccurrenceCompletedOnCalendarDay(
                                      task, _selectedDate)
                                  : null,
                              assigneeProfiles: assigneeProfileMap,
                              selfUid: me?.uid,
                              selfPhotoUrl: me?.photoURL,
                              groupLabel: _resolveGroupLabel(task, groupById),
                              groupAccentColor:
                                  _resolveGroupAccent(task, groupById),
                              groupIconKey:
                                  _resolveGroupIconKey(task, groupById),
                              onToggle: () => _toggleTaskForList(
                                task,
                                occurrenceCalendarDay: isTodayFilter
                                    ? _selectedDate
                                    : null,
                              ),
                              onEdit: () => _openTaskForm(task: task),
                              onDelete: () => _deleteTask(task),
                            ),
                          );
                        },
                        childCount: completed.length,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
      floatingActionButton: ExpandableCreateTaskFab(
        onWrite: () => _openTaskForm(),
        onDictate: _openVoiceTaskRecording,
      ),
    );
  }

  Widget _buildCalendar(List<TaskModel> allTasks) {
    final c = context.ex;
    final dayProps = _buildDayProps(c);
    const activeDayColor = ExColors.brandGreen;
    const activeDayTextColor = _timelineDayNumOnLight;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: ExSpace.s2),
        child: EasyDateTimeLine(
          initialDate: _selectedDate,
          activeColor: activeDayColor,
          onDateChange: (selectedDate) {
            setState(() => _selectedDate = selectedDate);
          },
          locale: 'pt_BR',
          headerProps: EasyHeaderProps(
            monthPickerType: MonthPickerType.switcher,
            selectedDateFormat: SelectedDateFormat.monthOnly,
            monthStyle: ExText.h2(c.textPrimary),
            selectedDateStyle: ExText.h2(c.textPrimary),
          ),
          dayProps: dayProps,
          itemBuilder: (context, date, isSelected, onTap) {
            final hasActivity =
                allTasks.any((t) => taskVisibleOnDay(t, date));
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                EasyDayWidget(
                  easyDayProps: dayProps,
                  date: date,
                  locale: 'pt_BR',
                  isSelected: isSelected,
                  isDisabled: false,
                  onDayPressed: onTap,
                  activeTextColor: activeDayTextColor,
                  activeDayColor: activeDayColor,
                ),
                if (hasActivity && !isSelected)
                  Positioned(
                    top: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: ExColors.lavender,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final c = context.ex;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ExSpace.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(ExSpace.s6),
              decoration: BoxDecoration(
                color: ExColors.brandGreen.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: ExColors.brandGreen,
              ),
            ),
            const SizedBox(height: ExSpace.s4),
            Text(
              _emptyMessage,
              textAlign: TextAlign.center,
              style: ExText.h3(c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String get _emptyMessage {
    switch (widget.filter) {
      case TaskFilterType.today:
        return 'Nenhuma tarefa para este dia.';
      case TaskFilterType.scheduled:
        return 'Nenhuma tarefa agendada.';
      case TaskFilterType.all:
        return 'Nenhuma tarefa encontrada.';
      case TaskFilterType.overdue:
        return 'Nenhuma tarefa atrasada!';
    }
  }
}
