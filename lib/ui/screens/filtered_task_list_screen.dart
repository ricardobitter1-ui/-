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
import '../../data/models/task_model.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/color_utils.dart';
import '../widgets/task_appear_motion.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

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

  static final EasyDayProps _timelineDayProps = EasyDayProps(
    width: 68,
    height: 112,
    dayStructure: DayStructure.dayStrDayNum,
    activeDayDecoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.brandPrimary, AppTheme.brandSecondary],
      ),
    ),
    inactiveDayDecoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      color: Colors.white,
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

  static String _resolveGroupLabel(TaskModel t, Map<String, GroupModel> byId) {
    final id = t.groupId?.trim();
    if (id == null || id.isEmpty) return 'Pessoal';
    return byId[id]?.name ?? 'Grupo';
  }

  static Color _resolveGroupAccent(TaskModel t, Map<String, GroupModel> byId) {
    final id = t.groupId?.trim();
    if (id == null || id.isEmpty) return Colors.grey.shade500;
    final g = byId[id];
    if (g == null) return Colors.grey.shade500;
    return parseAppHexColor(g.color);
  }

  List<TaskModel> _applyFilter(List<TaskModel> all) {
    switch (widget.filter) {
      case TaskFilterType.today:
        return all
            .where((t) => taskVisibleOnDay(t, _selectedDate))
            .toList();
      case TaskFilterType.scheduled:
        final list = all.where(taskMatchesScheduledFilter).toList()
          ..sort(
            (a, b) => (a.dueDate ?? DateTime(0))
                .compareTo(b.dueDate ?? DateTime(0)),
          );
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
            'Esta série não tem ocorrência neste dia. Abra Hoje e selecione a data.',
          ),
        ),
      );
    }
  }

  void _openTaskForm({TaskModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => TaskFormModal(initialTask: task),
    );
  }

  Future<void> _confirmAndDeleteTask(TaskModel task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar tarefa?'),
        content: Text(
          'A tarefa "${task.title}" será removida.',
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
    if (ok != true || !mounted) return;

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
                              onToggle: () => _toggleTaskForList(
                                task,
                                occurrenceCalendarDay: row.day,
                              ),
                              onEdit: () => _openTaskForm(task: task),
                              onDelete: () => _confirmAndDeleteTask(task),
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
                            onToggle: () => _toggleTaskForList(
                              task,
                              occurrenceCalendarDay: isTodayFilter
                                  ? _selectedDate
                                  : null,
                            ),
                            onEdit: () => _openTaskForm(task: task),
                            onDelete: () => _confirmAndDeleteTask(task),
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
                      child: Text(
                        'Concluídas (${completed.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
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
                              onToggle: () => _toggleTaskForList(
                                task,
                                occurrenceCalendarDay: isTodayFilter
                                    ? _selectedDate
                                    : null,
                              ),
                              onEdit: () => _openTaskForm(task: task),
                              onDelete: () => _confirmAndDeleteTask(task),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(),
        tooltip: 'Nova tarefa',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildCalendar(List<TaskModel> allTasks) {
    final activeDayColor = AppTheme.brandPrimary;
    final brightness = ThemeData.estimateBrightnessForColor(activeDayColor);
    final activeDayTextColor = brightness == Brightness.light
        ? _timelineDayNumOnLight
        : Colors.white;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
          ),
          dayProps: _timelineDayProps,
          itemBuilder: (context, date, isSelected, onTap) {
            final hasActivity =
                allTasks.any((t) => taskVisibleOnDay(t, date));
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                EasyDayWidget(
                  easyDayProps: _timelineDayProps,
                  date: date,
                  locale: 'pt_BR',
                  isSelected: isSelected,
                  isDisabled: false,
                  onDayPressed: onTap,
                  activeTextColor: activeDayTextColor,
                  activeDayColor: activeDayColor,
                ),
                if (hasActivity)
                  Positioned(
                    top: 6,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.brandPrimary,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.brandPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 48,
                color: AppTheme.brandPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B2D42),
              ),
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
