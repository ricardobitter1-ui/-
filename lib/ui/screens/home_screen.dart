import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business_logic/complete_task_action.dart';
import '../../business_logic/home_counts.dart';
import '../../business_logic/overdue_occurrences.dart';
import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../business_logic/reschedule_overdue_batch.dart';
import '../../business_logic/task_list_partition.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../widgets/eximium/ex_bottom_nav.dart';
import '../widgets/expandable_create_task_fab.dart';
import '../widgets/task_appear_motion.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';
import '../widgets/voice_task_recording_sheet.dart';
import 'calendar_agenda_screen.dart';
import 'filtered_task_list_screen.dart';
import 'task_search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _todayCompletedExpanded = false;

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
    final deletedTask = task;

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          content: Text('Tarefa "${task.title}" removida.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () async {
              final newId = await fs.addTask(deletedTask);
              await ns.syncTaskDatetimeReminders(
                deletedTask.copyWith(id: newId),
              );
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

  Future<void> _rescheduleAllOverdue(
    List<OverdueOccurrenceRow> rows,
    DateTime targetDay,
  ) async {
    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);
    final reschedulable =
        rows.where((r) => !isDatetimeRecurringTask(r.task)).toList();
    if (reschedulable.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Nenhuma tarefa pontual atrasada para reagendar. '
              'Tarefas recorrentes precisam ser ajustadas uma a uma.',
            ),
          ),
        );
      }
      return;
    }

    for (final row in reschedulable) {
      final updated = taskRescheduledToDay(row.task, targetDay);
      await fs.updateTask(updated);
      if (updated.reminderType == 'datetime') {
        await ns.syncTaskDatetimeReminders(updated);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${reschedulable.length} tarefa${reschedulable.length == 1 ? '' : 's'} '
            'reagendada${reschedulable.length == 1 ? '' : 's'}.',
          ),
        ),
      );
    }
  }

  Future<void> _showRescheduleOverduePicker(
    List<OverdueOccurrenceRow> rows,
  ) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Reagendar todas as atrasadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Para amanhã'),
              onTap: () => Navigator.pop(ctx, 'tomorrow'),
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: const Text('Escolher data'),
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice == 'tomorrow') {
      await _rescheduleAllOverdue(rows, tomorrow);
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && mounted) {
      await _rescheduleAllOverdue(rows, picked);
    }
  }

  static String _homeAssigneeCacheKey(List<TaskModel> visibleActive) {
    final n = visibleActive.length > 5 ? 5 : visibleActive.length;
    final ids = <String>{};
    for (var i = 0; i < n; i++) {
      ids.addAll(visibleActive[i].assigneeIds);
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

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final user = ref.watch(authStateProvider).value;

    final groupsList =
        ref.watch(groupsStreamProvider).value ?? const <GroupModel>[];
    final groupById = {for (final g in groupsList) g.id: g};

    final homeAssigneeKey = tasksAsync.maybeWhen(
      data: (allTasks) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final todayActive = activeTasksForDay(
          allTasks,
          today,
          now: now,
          groupById: groupById,
        );
        final tomorrowActive = activeTasksForDay(
          allTasks,
          tomorrow,
          now: now,
          groupById: groupById,
        );
        return _homeAssigneeCacheKey([
          ...todayActive.take(5),
          ...tomorrowActive.take(5),
        ]);
      },
      orElse: () => '',
    );
    final assigneeProfileMap =
        ref.watch(groupMemberProfilesProvider(homeAssigneeKey)).value ?? {};

    return Scaffold(
      body: ExAppBackground(
        child: SafeArea(
          top: false,
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
          data: (allTasks) {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final overdueRows = collectOverdueOccurrenceRows(allTasks, now);

            final todayVisible = tasksVisibleOnHomeDay(
              allTasks,
              today,
              now: now,
              groupById: groupById,
            );
            final todayPartition =
                partitionTasksByCompletionForCalendarDay(todayVisible, today);
            final todayActive = todayPartition.active;
            final todayCompleted = todayPartition.completed;
            final tomorrow = today.add(const Duration(days: 1));
            final tomorrowActive = activeTasksForDay(
              allTasks,
              tomorrow,
              now: now,
              groupById: groupById,
            );
            final hasTomorrow = tomorrowActive.isNotEmpty;
            final hasToday =
                todayActive.isNotEmpty || todayCompleted.isNotEmpty;
            final hasUpcoming = hasToday || hasTomorrow;
            final hasOverdue = overdueRows.isNotEmpty;

            return CustomScrollView(
              slivers: [
                _buildHeader(user),
                _buildQuickNavRow(
                  scheduledCount: pendingScheduledCount(
                    allTasks,
                    now: now,
                    groupById: groupById,
                  ),
                ),
                if (hasOverdue) ...[
                  _buildOverdueSectionHeader(overdueRows),
                  ..._buildOverdueTaskSlivers(
                    rows: overdueRows,
                    assigneeProfileMap: assigneeProfileMap,
                    groupById: groupById,
                    user: user,
                  ),
                ],
                _buildSectionTitle('Hoje'),
                if (todayActive.isNotEmpty)
                  ..._buildHomeTaskSlivers(
                    tasks: todayActive,
                    calendarDay: today,
                    listKeyPrefix: 'home-today',
                    assigneeProfileMap: assigneeProfileMap,
                    groupById: groupById,
                    user: user,
                    padBottomForFab:
                        !hasTomorrow &&
                        todayCompleted.isEmpty &&
                        todayActive.length <= 5,
                  ),
                if (todayCompleted.isNotEmpty)
                  ..._buildTodayCompletedSlivers(
                    tasks: todayCompleted,
                    calendarDay: today,
                    assigneeProfileMap: assigneeProfileMap,
                    groupById: groupById,
                    user: user,
                    padBottomForFab: !hasTomorrow,
                  ),
                if (hasTomorrow) ...[
                  _buildDaySectionDivider('Amanhã'),
                  ..._buildHomeTaskSlivers(
                    tasks: tomorrowActive,
                    calendarDay: tomorrow,
                    listKeyPrefix: 'home-tomorrow',
                    assigneeProfileMap: assigneeProfileMap,
                    groupById: groupById,
                    user: user,
                    padBottomForFab: tomorrowActive.length <= 5,
                    maxPreview: 5,
                  ),
                ],
                if (!hasUpcoming && !hasOverdue)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _buildEmptyUpcomingState(),
                    ),
                  ),
                if (hasTomorrow && tomorrowActive.length > 5)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                      child: TextButton(
                        onPressed: () =>
                            _navigateToFilter(TaskFilterType.scheduled),
                        child: Text(
                          'Ver todas as ${tomorrowActive.length} tarefas de amanhã',
                          style: ExText.body(context.ex.textAccent)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            },
          ),
        ),
      ),
      floatingActionButton: ExpandableCreateTaskFab(
        onWrite: () => _openTaskForm(),
        onDictate: _openVoiceTaskRecording,
      ),
      floatingActionButtonLocation: const ExFabAboveBottomNavLocation(),
    );
  }

  Widget _buildHeader(dynamic user) {
    final c = context.ex;
    final String greeting =
        "Olá, ${user?.displayName?.split(' ')[0] ?? 'Usuário'}";

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: ExText.display(c.textPrimary)),
                  const SizedBox(height: 5),
                  Text(
                    'Veja o resumo das suas tarefas.',
                    style: ExText.body(c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: ExSpace.s3),
            _buildCircleIconButton(
              icon: Icons.calendar_month_rounded,
              tooltip: 'Calendário',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CalendarAgendaScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final c = context.ex;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface1,
        shape: CircleBorder(side: BorderSide(color: c.border)),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: c.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildOverdueSectionHeader(List<OverdueOccurrenceRow> rows) {
    final c = context.ex;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: c.errorText, size: 18),
            const SizedBox(width: ExSpace.s2),
            Expanded(
              child: Text(
                'Atrasadas · ${rows.length}',
                style: ExText.h3(c.errorText).copyWith(fontSize: 14),
              ),
            ),
            InkWell(
              onTap: () => _showRescheduleOverduePicker(rows),
              borderRadius: BorderRadius.circular(ExRadius.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ExSpace.s2,
                  vertical: ExSpace.s1,
                ),
                child: Text(
                  'Reagendar todas',
                  style: ExText.body(c.errorText)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOverdueTaskSlivers({
    required List<OverdueOccurrenceRow> rows,
    required Map<String, UserPublicProfile?> assigneeProfileMap,
    required Map<String, GroupModel> groupById,
    required dynamic user,
  }) {
    final preview = rows.length > 5 ? 5 : rows.length;
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final row = rows[index];
              final task = row.task;
              return TaskAppearMotion(
                key: ValueKey('home-overdue-${task.id}-${row.day}'),
                child: TaskCard(
                  task: task,
                  displayDueOverride:
                      displayDueForTaskOnCalendarDay(task, row.day),
                  assigneeProfiles: assigneeProfileMap,
                  selfUid: user?.uid,
                  selfPhotoUrl: user?.photoURL,
                  groupLabel: _resolveGroupLabel(task, groupById),
                  groupAccentColor: _resolveGroupAccent(task, groupById),
                  groupIconKey: _resolveGroupIconKey(task, groupById),
                  onToggle: () async {
                    final fs = ref.read(firebaseServiceProvider);
                    final ns = ref.read(notificationServiceProvider);
                    await completeTaskToggle(
                      fs: fs,
                      ns: ns,
                      task: task,
                      occurrenceCalendarDay: row.day,
                    );
                  },
                  onEdit: () => _openTaskForm(task: task),
                  onDelete: () => _deleteTask(task),
                ),
              );
            },
            childCount: preview,
          ),
        ),
      ),
      if (rows.length > 5)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: TextButton(
              onPressed: () => _navigateToFilter(TaskFilterType.overdue),
              child: Text(
                'Ver todas as ${rows.length} atrasadas',
                style: ExText.body(context.ex.errorText)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildQuickNavRow({required int scheduledCount}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
        child: Wrap(
          spacing: ExSpace.s2,
          runSpacing: ExSpace.s2,
          children: [
            _buildQuickNavChip(
              icon: Icons.schedule_rounded,
              label: 'Agendadas · $scheduledCount',
              onTap: () => _navigateToFilter(TaskFilterType.scheduled),
            ),
            _buildQuickNavChip(
              icon: Icons.calendar_month_rounded,
              label: 'Calendário',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CalendarAgendaScreen(),
                  ),
                );
              },
            ),
            _buildQuickNavChip(
              icon: Icons.search_rounded,
              label: 'Buscar',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TaskSearchScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNavChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final c = context.ex;
    return Material(
      color: c.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ExRadius.pill),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: c.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: ExText.body(c.textSecondary)
                    .copyWith(fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToFilter(TaskFilterType filter) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FilteredTaskListScreen(filter: filter),
      ),
    );
  }

  List<Widget> _buildTodayCompletedSlivers({
    required List<TaskModel> tasks,
    required DateTime calendarDay,
    required Map<String, UserPublicProfile?> assigneeProfileMap,
    required Map<String, GroupModel> groupById,
    required dynamic user,
    required bool padBottomForFab,
  }) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(ExRadius.md),
            onTap: () => setState(
              () => _todayCompletedExpanded = !_todayCompletedExpanded,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _todayCompletedExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: context.ex.textSecondary,
                  ),
                  const SizedBox(width: ExSpace.s1),
                  Text(
                    'Concluídas hoje · ${tasks.length}',
                    style: ExText.label(context.ex.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      if (_todayCompletedExpanded)
        ..._buildHomeTaskSlivers(
          tasks: tasks,
          calendarDay: calendarDay,
          listKeyPrefix: 'home-today-done',
          assigneeProfileMap: assigneeProfileMap,
          groupById: groupById,
          user: user,
          padBottomForFab: padBottomForFab,
          showAsCompleted: true,
        ),
    ];
  }

  List<Widget> _buildHomeTaskSlivers({
    required List<TaskModel> tasks,
    required DateTime calendarDay,
    required String listKeyPrefix,
    required Map<String, UserPublicProfile?> assigneeProfileMap,
    required Map<String, GroupModel> groupById,
    required dynamic user,
    required bool padBottomForFab,
    bool showAsCompleted = false,
    int? maxPreview,
  }) {
    final limit = maxPreview ?? tasks.length;
    final previewCount = tasks.length > limit ? limit : tasks.length;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          padBottomForFab ? 80 : 0,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = tasks[index];
              return TaskAppearMotion(
                key: ValueKey('$listKeyPrefix-${task.id}'),
                child: TaskCard(
                  task: task,
                  displayDueOverride:
                      displayDueForTaskOnCalendarDay(task, calendarDay),
                  isCompletedOverride: showAsCompleted ||
                      isOccurrenceCompletedOnCalendarDay(task, calendarDay),
                  assigneeProfiles: assigneeProfileMap,
                  selfUid: user?.uid,
                  selfPhotoUrl: user?.photoURL,
                  groupLabel: _resolveGroupLabel(task, groupById),
                  groupAccentColor: _resolveGroupAccent(task, groupById),
                  groupIconKey: _resolveGroupIconKey(task, groupById),
                  onToggle: () async {
                    final fs = ref.read(firebaseServiceProvider);
                    final ns = ref.read(notificationServiceProvider);
                    await completeTaskToggle(
                      fs: fs,
                      ns: ns,
                      task: task,
                      occurrenceCalendarDay: calendarDay,
                    );
                  },
                  onEdit: () => _openTaskForm(task: task),
                  onDelete: () => _deleteTask(task),
                ),
              );
            },
            childCount: previewCount,
          ),
        ),
      ),
    ];
  }

  Widget _buildDaySectionDivider(String label) {
    final c = context.ex;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
        child: Row(
          children: [
            Expanded(child: Divider(color: c.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ExSpace.s3),
              child: Text(
                label,
                style: ExText.body(c.textMuted)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: c.border)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
        child: Text(title, style: ExText.h2(context.ex.textPrimary)),
      ),
    );
  }

  Widget _buildEmptyUpcomingState() {
    final c = context.ex;
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ExColors.brandGreen.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            boxShadow: ExEffects.glowSm,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: ExColors.brandGreen,
          ),
        ),
        const SizedBox(height: ExSpace.s4),
        Text(
          'Nenhuma tarefa pendente para hoje ou amanhã',
          textAlign: TextAlign.center,
          style: ExText.h3(c.textPrimary).copyWith(fontSize: 16),
        ),
        const SizedBox(height: ExSpace.s2),
        TextButton(
          onPressed: () => _navigateToFilter(TaskFilterType.scheduled),
          child: Text(
            'Ver tarefas agendadas',
            style:
                ExText.body(c.textAccent).copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
