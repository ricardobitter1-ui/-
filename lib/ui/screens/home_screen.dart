import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../business_logic/task_list_partition.dart';
import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../utils/scheduled_badge_label.dart';
import '../theme/app_theme.dart';
import '../widgets/task_appear_motion.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';
import 'filtered_task_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
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
                color: AppTheme.brandPrimary,
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
          persist: false,
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
          duration: const Duration(seconds: 3),
        ),
      );
    }

    await fs.deleteTask(task.id);
    await ns.cancelNotification(task.id.hashCode);
  }

  // ── helpers de contagem ────────────────────────────────────────────────

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  static String _homeTodayAssigneeCacheKey(List<TaskModel> todayActive) {
    final n = todayActive.length > 5 ? 5 : todayActive.length;
    final ids = <String>{};
    for (var i = 0; i < n; i++) {
      ids.addAll(todayActive[i].assigneeIds);
    }
    return memberUidsCacheKey(ids);
  }

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final user = ref.watch(authStateProvider).value;

    final homeAssigneeKey = tasksAsync.maybeWhen(
      data: (allTasks) {
        final todayTasks = allTasks
            .where((t) => t.dueDate != null && _isToday(t.dueDate!))
            .toList();
        final todayActive = partitionTasksByCompletion(todayTasks).active;
        return _homeTodayAssigneeCacheKey(todayActive);
      },
      orElse: () => '',
    );
    final assigneeProfileMap =
        ref.watch(groupMemberProfilesProvider(homeAssigneeKey)).value ?? {};

    return Scaffold(
      body: SafeArea(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro: $err')),
          data: (allTasks) {
            final now = DateTime.now();
            final todayTasks = allTasks
                .where((t) => t.dueDate != null && _isToday(t.dueDate!))
                .toList();
            final scheduledTasks = allTasks
                .where((t) =>
                    t.dueDate != null && !_isToday(t.dueDate!))
                .toList();
            final overdueTasks = allTasks
                .where((t) =>
                    t.dueDate != null &&
                    isDueDateTimePast(t.dueDate!, now) &&
                    !t.isCompleted)
                .toList();

            final todayActive =
                partitionTasksByCompletion(todayTasks).active;

            return CustomScrollView(
              slivers: [
                _buildHeader(user),
                _buildQuadrantsGrid(
                  todayCount: todayTasks.length,
                  scheduledCount: scheduledTasks.length,
                  allCount: allTasks.length,
                  overdueCount: overdueTasks.length,
                ),
                _buildSectionTitle('Tarefas de hoje'),
                if (todayActive.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _buildEmptyTodayState(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = todayActive[index];
                          return TaskAppearMotion(
                            key: ValueKey('home-today-${task.id}'),
                            child: TaskCard(
                              task: task,
                              assigneeProfiles: assigneeProfileMap,
                              selfUid: user?.uid,
                              selfPhotoUrl: user?.photoURL,
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
                        childCount:
                            todayActive.length > 5 ? 5 : todayActive.length,
                      ),
                    ),
                  ),
                if (todayActive.length > 5)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                      child: TextButton(
                        onPressed: () => _navigateToFilter(TaskFilterType.today),
                        child: Text(
                          'Ver todas as ${todayActive.length} tarefas de hoje',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
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

  // ── header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(dynamic user) {
    final String greeting =
        "Olá, ${user?.displayName?.split(' ')[0] ?? 'Usuário'}";

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Row(
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
                    'Veja o resumo das suas tarefas.',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
      ),
    );
  }

  // ── quadrants grid ─────────────────────────────────────────────────────

  Widget _buildQuadrantsGrid({
    required int todayCount,
    required int scheduledCount,
    required int allCount,
    required int overdueCount,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _DashboardTile(
              icon: Icons.today_rounded,
              label: 'Hoje',
              count: todayCount,
              gradient: const [Color(0xFF7B8CDE), Color(0xFF9FAEE6)],
              onTap: () => _navigateToFilter(TaskFilterType.today),
            ),
            _DashboardTile(
              icon: Icons.schedule_rounded,
              label: 'Agendadas',
              count: scheduledCount,
              gradient: const [Color(0xFFE8C547), Color(0xFFF0D86E)],
              onTap: () => _navigateToFilter(TaskFilterType.scheduled),
            ),
            _DashboardTile(
              icon: Icons.checklist_rounded,
              label: 'Todas',
              count: allCount,
              gradient: const [Color(0xFF7DCFB6), Color(0xFFA0DFCD)],
              onTap: () => _navigateToFilter(TaskFilterType.all),
            ),
            _DashboardTile(
              icon: Icons.warning_amber_rounded,
              label: 'Atrasadas',
              count: overdueCount,
              gradient: const [Color(0xFFE8A0BF), Color(0xFFF0BDD4)],
              onTap: () => _navigateToFilter(TaskFilterType.overdue),
            ),
          ],
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

  // ── section title ──────────────────────────────────────────────────────

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

  // ── empty today state ──────────────────────────────────────────────────

  Widget _buildEmptyTodayState() {
    return Column(
      children: [
        const SizedBox(height: 16),
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
        const Text(
          'Nenhuma tarefa pendente para hoje',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2B2D42),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _navigateToFilter(TaskFilterType.scheduled),
          child: const Text(
            'Ver tarefas agendadas',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.brandPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Dashboard Tile ─────────────────────────────────────────────────────

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
