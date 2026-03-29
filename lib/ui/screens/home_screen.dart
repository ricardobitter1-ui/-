import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/task_form_modal.dart';
import '../widgets/custom_avatar.dart';
import '../widgets/daily_progress_indicator.dart';
import '../widgets/task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  
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

  void _showPermissionSheet(NotificationService ns, bool needsNotif, bool needsAlarm) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_active_rounded, size: 64, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              const Text("Não perca suas tarefas!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                child: const Text("Agora não", style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final tasksAsyncValue = ref.watch(tasksStreamProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      body: SafeArea(
        child: tasksAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Erro: $err')),
          data: (tasks) {
            // Filtragem por data
            final filteredTasks = tasks.where((task) {
              if (task.dueDate == null) return false;
              return task.dueDate!.year == _selectedDate.year &&
                     task.dueDate!.month == _selectedDate.month &&
                     task.dueDate!.day == _selectedDate.day;
            }).toList();

            // Cálculo do progresso (Apenas para hoje se estiver selecionado, ou para o dia selecionado)
            final total = filteredTasks.length;
            final completed = filteredTasks.where((t) => t.isCompleted).length;
            final progress = total > 0 ? completed / total : 0.0;

            return CustomScrollView(
              slivers: [
                _buildHeader(user, progress),
                _buildCalendar(),
                if (filteredTasks.isNotEmpty) _buildFocusSection(filteredTasks.first),
                _buildTaskList(filteredTasks),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskForm(),
        tooltip: 'Adicionar nova tarefa',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(dynamic user, double progress) {
    final String greeting = "Olá, ${user?.displayName?.split(' ')[0] ?? 'Usuário'}";
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                    const Text(
                      "Suas tarefas de hoje estão quase prontas!",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => ref.read(authServiceProvider).signOut(),
                  child: CustomAvatar(
                    photoUrl: user?.photoURL,
                    displayName: user?.displayName ?? user?.email,
                    radius: 28,
                  ),
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

  Widget _buildFocusSection(TaskModel task) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Em progresso",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2B2D42)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tarefa em Foco",
                        style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.auto_awesome, color: Colors.amber.shade300, size: 18),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description.isNotEmpty ? task.description : "Sem descrição adicional",
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: task.isCompleted ? 1.0 : 0.3,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildTaskList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(context),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final task = tasks[index];
            return TaskCard(
              task: task,
              onToggle: () {
                ref.read(firebaseServiceProvider).toggleTaskCompletion(task.id, task.isCompleted);
              },
              onEdit: () => _openTaskForm(task: task),
              onDelete: () async {
                final fs = ref.read(firebaseServiceProvider);
                final ns = ref.read(notificationServiceProvider);
                
                // Salvar contexto para o Undo antes de deletar
                final deletedTask = task;
                
                // Premium Experience: Snackbar de Confirmação com Desfazer
                if (mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tarefa "${task.title}" removida.'),
                      action: SnackBarAction(
                        label: 'Desfazer',
                        onPressed: () {
                          // Se desfizer, recriamos no Firebase
                          fs.addTask(deletedTask);
                          // Reagendar notificação se necessário
                          if (deletedTask.reminderType == 'datetime' && deletedTask.dueDate != null) {
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
                    ),
                  );
                }

                // Efetuar a deleção no Firestore
                await fs.deleteTask(task.id);
                // Cancelar notificação local se houver
                await ns.cancelNotification(task.id.hashCode);
              },
            );
          },
          childCount: tasks.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_today_outlined, size: 64, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            "Nenhuma tarefa para este dia",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2B2D42)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Aproveite o seu tempo livre ou\nadicione algo novo!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
