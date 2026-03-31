import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../data/models/group_model.dart';
import '../../data/services/auth_service.dart';
import '../../business_logic/task_list_partition.dart';
import '../../data/models/task_model.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../utils/scheduled_badge_label.dart';
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
  DateTime _selectedDate = DateTime.now();

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

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
            .where((t) =>
                t.dueDate != null && _isSameDay(t.dueDate!, _selectedDate))
            .toList();
      case TaskFilterType.scheduled:
        return all
            .where((t) => t.dueDate != null && !_isToday(t.dueDate!))
            .toList();
      case TaskFilterType.all:
        return all;
      case TaskFilterType.overdue:
        final now = DateTime.now();
        return all
            .where((t) =>
                t.dueDate != null &&
                isDueDateTimePast(t.dueDate!, now) &&
                !t.isCompleted)
            .toList();
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
            onPressed: () {
              fs.addTask(task);
              if (task.reminderType == 'datetime' && task.dueDate != null) {
                ns.scheduleTaskReminder(
                  task.id.hashCode,
                  task.title,
                  task.description,
                  task.dueDate!,
                );
              }
            },
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2B2D42),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await fs.deleteTask(task.id);
    await ns.cancelNotification(task.id.hashCode);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final me = ref.watch(authStateProvider).value;

    final assigneeKey = tasksAsync.maybeWhen(
      data: (all) {
        final filtered = _applyFilter(all);
        final (:active, :completed) = partitionTasksByCompletion(filtered);
        return _assigneeKeyForFiltered([...active, ...completed]);
      },
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
          final filtered = _applyFilter(allTasks);
          final (:active, :completed) = partitionTasksByCompletion(filtered);

          return CustomScrollView(
            slivers: [
              if (showCalendar) _buildCalendar(),
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
                            assigneeProfiles: assigneeProfileMap,
                            selfUid: me?.uid,
                            selfPhotoUrl: me?.photoURL,
                            groupLabel: _resolveGroupLabel(task, groupById),
                            groupAccentColor:
                                _resolveGroupAccent(task, groupById),
                            onToggle: () {
                              ref
                                  .read(firebaseServiceProvider)
                                  .toggleTaskCompletion(
                                      task.id, task.isCompleted);
                            },
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
                              assigneeProfiles: assigneeProfileMap,
                              selfUid: me?.uid,
                              selfPhotoUrl: me?.photoURL,
                              groupLabel: _resolveGroupLabel(task, groupById),
                              groupAccentColor:
                                  _resolveGroupAccent(task, groupById),
                              onToggle: () {
                                ref
                                    .read(firebaseServiceProvider)
                                    .toggleTaskCompletion(
                                        task.id, task.isCompleted);
                              },
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

  Widget _buildCalendar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: EasyDateTimeLine(
          initialDate: _selectedDate,
          onDateChange: (selectedDate) {
            setState(() => _selectedDate = selectedDate);
          },
          locale: 'pt_BR',
          headerProps: EasyHeaderProps(
            monthPickerType: MonthPickerType.switcher,
            selectedDateFormat: SelectedDateFormat.monthOnly,
          ),
          dayProps: const EasyDayProps(
            dayStructure: DayStructure.dayStrDayNum,
            activeDayDecoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.brandPrimary, AppTheme.brandSecondary],
              ),
            ),
            inactiveDayDecoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              color: Colors.white,
            ),
          ),
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
