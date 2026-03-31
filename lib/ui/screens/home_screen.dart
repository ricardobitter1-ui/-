import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../../business_logic/group_day_progress.dart';
import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/task_list_partition.dart';
import '../../data/local/completed_section_prefs.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/tag_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/completed_tasks_section_header.dart';
import '../widgets/daily_progress_indicator.dart';
import '../widgets/group_rail_card.dart';
import '../widgets/home_completed_tag_filter_bar.dart';
import '../widgets/home_task_card_with_tags.dart';
import '../widgets/task_appear_motion.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';
import 'group_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _inboxCompletedExpanded = true;
  bool _dayCompletedExpanded = true;
  String? _inboxCompletedTagFilter;
  String? _dayCompletedTagFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
      _loadCompletedSectionExpansionPrefs();
    });
  }

  Future<void> _loadCompletedSectionExpansionPrefs() async {
    final inbox = await loadCompletedSectionExpanded(
      CompletedSectionPrefsKeys.hojeInboxSemData,
    );
    final day = await loadCompletedSectionExpanded(
      CompletedSectionPrefsKeys.hojeDiaSelecionado,
    );
    if (!mounted) return;
    setState(() {
      _inboxCompletedExpanded = inbox;
      _dayCompletedExpanded = day;
    });
  }

  List<HomeTagFilterOption> _homeCompletedFilterOptions(
    List<TaskModel> completed,
  ) {
    final groupIds =
        completed.map((t) => t.groupId).whereType<String>().toSet();
    final seen = <String>{};
    final out = <HomeTagFilterOption>[];
    for (final gid in groupIds) {
      final tags =
          ref.watch(groupTagsStreamProvider(gid)).value ?? const <TagModel>[];
      final byId = {for (final t in tags) t.id: t};
      for (final task in completed) {
        if (task.groupId != gid) continue;
        for (final tid in task.tagIds) {
          final tag = byId[tid];
          if (tag == null) continue;
          final key = HomeTaskCardWithTags.compositeTagKey(gid, tid);
          if (seen.add(key)) {
            out.add(HomeTagFilterOption(compositeKey: key, tag: tag));
          }
        }
      }
    }
    return out;
  }

  String? _effectiveHomeTagFilter(
    List<HomeTagFilterOption> options,
    String? stored,
  ) {
    if (stored == null) return null;
    return options.any((o) => o.compositeKey == stored) ? stored : null;
  }

  List<TaskModel> _filterHomeCompletedByTag(
    List<TaskModel> completed,
    String? compositeKey,
  ) {
    if (compositeKey == null) return completed;
    return completed.where((t) {
      final gid = t.groupId;
      if (gid == null) return false;
      for (final tid in t.tagIds) {
        if (HomeTaskCardWithTags.compositeTagKey(gid, tid) == compositeKey) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  Future<void> _checkPermissions() async {
    final ns = ref.read(notificationServiceProvider);
    await ns.initialize();
    final hasNotifPerm = await ns.hasPermission();
    final hasAlarmPerm = await ns.hasAlarmPermission();
    if ((!hasNotifPerm || !hasAlarmPerm) && mounted) {
      _showPermissionSheet(ns, !hasNotifPerm, !hasAlarmPerm);
    }
  }

  void _showPermissionSheet(
    NotificationService ns,
    bool needsNotif,
    bool needsAlarm,
  ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                "Não perca suas tarefas!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                needsAlarm
                    ? "Para que os lembretes toquem na hora exata, precisamos que você ative as notificações e a permissão de 'Alarmes e Lembretes' nas configurações."
                    : "Precisamos que você libere as notificações para que o app consiga despertar e te avisar na hora exata do lembrete.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await ns.requestPermission();
                    if (context.mounted) Navigator.pop(context);
                    _checkPermissions();
                  },
                  child: const Text("Configurar Permissões"),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Agora não",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    if (ok != true || !mounted) return;
    await _deleteTask(task);
  }

  Future<void> _deleteTask(TaskModel task) async {
    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);
    final deletedTask = task;

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tarefa "${task.title}" removida.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              fs.addTask(deletedTask);
              if (deletedTask.reminderType == 'datetime' &&
                  deletedTask.dueDate != null) {
                ns.scheduleTaskReminder(
                  deletedTask.id.hashCode,
                  deletedTask.title,
                  deletedTask.description,
                  deletedTask.dueDate!,
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

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final groupsAsync = ref.watch(groupsStreamProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      body: SafeArea(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro: $err')),
          data: (allTasks) {
            final groups = groupsAsync.value ?? const <GroupModel>[];
            final inboxTasks =
                allTasks.where((t) => t.dueDate == null).toList();

            final filteredDayTasks = allTasks.where((task) {
              if (task.dueDate == null) return false;
              return task.dueDate!.year == _selectedDate.year &&
                  task.dueDate!.month == _selectedDate.month &&
                  task.dueDate!.day == _selectedDate.day;
            }).toList();

            final total = filteredDayTasks.length;
            final completed =
                filteredDayTasks.where((t) => t.isCompleted).length;
            final progress = total > 0 ? completed / total : 0.0;

            final progressByGroup =
                computeGroupProgressForDay(allTasks, _selectedDate);

            return CustomScrollView(
              slivers: [
                _buildHeader(user, progress),
                _buildCalendar(),
                _buildSectionTitle('Grupos neste dia'),
                SliverToBoxAdapter(
                  child: groupsAsync.hasError
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Não foi possível carregar grupos.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : groupsAsync.isLoading && !groupsAsync.hasValue
                          ? const SizedBox(
                              height: 120,
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : _buildGroupProgressRail(
                              context,
                              groups,
                              progressByGroup,
                            ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                _buildSectionTitle('Sem data'),
                ..._buildInboxSlivers(inboxTasks),
                _buildSectionTitle('Neste dia'),
                ..._buildDayTaskSlivers(filteredDayTasks),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(),
        tooltip: 'Nova tarefa',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B2D42),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user, double progress) {
    final String greeting =
        "Olá, ${user?.displayName?.split(' ')[0] ?? 'Usuário'}";

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2B2D42),
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seu dia, grupos e tarefas sem data em um só lugar.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sair',
                  onPressed: () => ref.read(authServiceProvider).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
            const SizedBox(height: 32),
            DailyProgressIndicator(progress: progress),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupProgressRail(
    BuildContext context,
    List<GroupModel> groups,
    Map<String, GroupDayProgress> progressByGroup,
  ) {
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Crie grupos na aba Grupos para acompanhar o progresso por grupo aqui.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final g = groups[index];
          final stats =
              progressByGroup[g.id] ?? const GroupDayProgress(total: 0, completed: 0);

          return GroupRailCard(
            group: g,
            stats: stats,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GroupDetailScreen(group: g),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildInboxSlivers(List<TaskModel> inboxTasks) {
    if (inboxTasks.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 80, 0),
            child: Text(
              'Nenhuma tarefa sem data.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              softWrap: true,
            ),
          ),
        ),
      ];
    }

    final (:active, :completed) = partitionTasksByCompletion(inboxTasks);
    final prefsKey = CompletedSectionPrefsKeys.hojeInboxSemData;
    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          completed.isNotEmpty ? 0 : 80,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = active[index];
              return TaskAppearMotion(
                key: ValueKey('inbox-a-${task.id}'),
                child: TaskCard(
                  task: task,
                  onToggle: () {
                    ref
                        .read(firebaseServiceProvider)
                        .toggleTaskCompletion(task.id, task.isCompleted);
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
    ];

    if (completed.isNotEmpty) {
      final inboxFilterOpts = _homeCompletedFilterOptions(completed);
      final inboxEff =
          _effectiveHomeTagFilter(inboxFilterOpts, _inboxCompletedTagFilter);
      final inboxCompletedVisible =
          _filterHomeCompletedByTag(completed, inboxEff);

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: CompletedTasksSectionHeader(
              expanded: _inboxCompletedExpanded,
              count: inboxCompletedVisible.length,
              onToggle: () async {
                final next = !_inboxCompletedExpanded;
                setState(() => _inboxCompletedExpanded = next);
                await saveCompletedSectionExpanded(prefsKey, next);
              },
            ),
          ),
        ),
      );
      if (_inboxCompletedExpanded) {
        if (inboxFilterOpts.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: HomeCompletedSectionTagFilterBar(
                  options: inboxFilterOpts,
                  selectedCompositeKey: inboxEff,
                  onSelect: (k) {
                    setState(() => _inboxCompletedTagFilter = k);
                  },
                ),
              ),
            ),
          );
        }
        if (inboxCompletedVisible.isEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 80, 0),
                child: Text(
                  'Nenhuma tarefa concluída com esta etiqueta.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ),
          );
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 80, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = inboxCompletedVisible[index];
                    return TaskAppearMotion(
                      key: ValueKey('inbox-c-${task.id}'),
                      child: HomeTaskCardWithTags(
                        task: task,
                        showTagChips: true,
                        onToggle: () {
                          ref
                              .read(firebaseServiceProvider)
                              .toggleTaskCompletion(
                                task.id,
                                task.isCompleted,
                              );
                        },
                        onEdit: () => _openTaskForm(task: task),
                        onDelete: () => _confirmAndDeleteTask(task),
                      ),
                    );
                  },
                  childCount: inboxCompletedVisible.length,
                ),
              ),
            ),
          );
        }
      } else {
        slivers.add(
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        );
      }
    }

    return slivers;
  }

  List<Widget> _buildDayTaskSlivers(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
            child: _buildEmptyDayState(),
          ),
        ),
      ];
    }

    final (:active, :completed) = partitionTasksByCompletion(tasks);
    final prefsKey = CompletedSectionPrefsKeys.hojeDiaSelecionado;
    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          completed.isNotEmpty ? 0 : 48,
        ),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final task = active[index];
              return TaskAppearMotion(
                key: ValueKey('day-a-${task.id}'),
                child: TaskCard(
                  task: task,
                  onToggle: () {
                    ref
                        .read(firebaseServiceProvider)
                        .toggleTaskCompletion(task.id, task.isCompleted);
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
    ];

    if (completed.isNotEmpty) {
      final dayFilterOpts = _homeCompletedFilterOptions(completed);
      final dayEff =
          _effectiveHomeTagFilter(dayFilterOpts, _dayCompletedTagFilter);
      final dayCompletedVisible =
          _filterHomeCompletedByTag(completed, dayEff);

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: CompletedTasksSectionHeader(
              expanded: _dayCompletedExpanded,
              count: dayCompletedVisible.length,
              onToggle: () async {
                final next = !_dayCompletedExpanded;
                setState(() => _dayCompletedExpanded = next);
                await saveCompletedSectionExpanded(prefsKey, next);
              },
            ),
          ),
        ),
      );
      if (_dayCompletedExpanded) {
        if (dayFilterOpts.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: HomeCompletedSectionTagFilterBar(
                  options: dayFilterOpts,
                  selectedCompositeKey: dayEff,
                  onSelect: (k) {
                    setState(() => _dayCompletedTagFilter = k);
                  },
                ),
              ),
            ),
          );
        }
        if (dayCompletedVisible.isEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Text(
                  'Nenhuma tarefa concluída com esta etiqueta.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ),
            ),
          );
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = dayCompletedVisible[index];
                    return TaskAppearMotion(
                      key: ValueKey('day-c-${task.id}'),
                      child: HomeTaskCardWithTags(
                        task: task,
                        showTagChips: true,
                        onToggle: () {
                          ref
                              .read(firebaseServiceProvider)
                              .toggleTaskCompletion(
                                task.id,
                                task.isCompleted,
                              );
                        },
                        onEdit: () => _openTaskForm(task: task),
                        onDelete: () => _confirmAndDeleteTask(task),
                      ),
                    );
                  },
                  childCount: dayCompletedVisible.length,
                ),
              ),
            ),
          );
        }
      } else {
        slivers.add(
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        );
      }
    }

    return slivers;
  }

  Widget _buildCalendar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: EasyDateTimeLine(
          initialDate: _selectedDate,
          onDateChange: (selectedDate) {
            setState(() {
              _selectedDate = selectedDate;
            });
          },
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
                colors: [AppTheme.primaryBlue, Color(0xFF5A189A)],
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

  Widget _buildEmptyDayState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nenhuma tarefa para este dia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B2D42),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Use o botão + ou confira as tarefas sem data acima.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
