import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../business_logic/complete_task_action.dart';
import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import '../../data/services/notification_service.dart';
import '../../utils/title_search_key.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../widgets/eximium/eximium.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

class TaskSearchScreen extends ConsumerStatefulWidget {
  const TaskSearchScreen({super.key});

  @override
  ConsumerState<TaskSearchScreen> createState() => _TaskSearchScreenState();
}

class _TaskSearchScreenState extends ConsumerState<TaskSearchScreen> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();

  /// Buscas recentes da sessão (apenas em memória, sem persistência).
  final List<String> _recentSearches = <String>[];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<TaskModel> _filterTasks(List<TaskModel> all, String q) {
    if (q.isEmpty) return [];
    return all
        .where((t) => !t.isCompleted && t.titleSearchKey.contains(q))
        .take(50)
        .toList();
  }

  void _rememberSearch(String raw) {
    final term = raw.trim();
    if (term.isEmpty) return;
    setState(() {
      _recentSearches.removeWhere((e) => e.toLowerCase() == term.toLowerCase());
      _recentSearches.insert(0, term);
      if (_recentSearches.length > 8) {
        _recentSearches.removeRange(8, _recentSearches.length);
      }
    });
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

  Future<void> _toggleTask(TaskModel task) async {
    final fs = ref.read(firebaseServiceProvider);
    final ns = ref.read(notificationServiceProvider);
    await completeTaskToggle(fs: fs, ns: ns, task: task);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final tasksAsync = ref.watch(tasksStreamProvider);
    final groups =
        ref.watch(groupsStreamProvider).value ?? const <GroupModel>[];
    final groupById = {for (final g in groups) g.id: g};
    final q = normalizeTitleSearchKey(_queryController.text);
    final me = ref.watch(authStateProvider).value;

    return Scaffold(
      body: ExAppBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchField(context),
              Expanded(
                child: tasksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Erro: $e', style: ExText.body(c.errorText)),
                  ),
                  data: (all) {
                    final results = _filterTasks(all, q);
                    if (q.isEmpty) {
                      return _buildIdleState(context);
                    }
                    if (results.isEmpty) {
                      return _buildNoResults(context);
                    }
                    final assigneeKey = memberUidsCacheKey(
                      results.expand((t) => t.assigneeIds).toSet(),
                    );
                    final profiles = ref
                            .watch(groupMemberProfilesProvider(assigneeKey))
                            .value ??
                        {};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            ExSpace.s5,
                            ExSpace.s2,
                            ExSpace.s5,
                            ExSpace.s3,
                          ),
                          child: ExSectionLabel(
                            label: results.length == 1
                                ? 'Resultado'
                                : 'Resultados',
                            count: results.length,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              ExSpace.s5,
                              0,
                              ExSpace.s5,
                              ExSpace.s6,
                            ),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final task = results[index];
                              final gid = task.groupId?.trim();
                              final g = gid != null ? groupById[gid] : null;
                              return TaskCard(
                                task: task,
                                groupLabel: g?.name,
                                groupAccentColor:
                                    g != null ? parseAppHexColor(g.color) : null,
                                groupIconKey: g?.icon,
                                assigneeProfiles: profiles,
                                selfUid: me?.uid,
                                selfPhotoUrl: me?.photoURL,
                                onToggle: () => _toggleTask(task),
                                onEdit: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        TaskFormModal(initialTask: task),
                                  );
                                },
                                onDelete: () => _deleteTask(task),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final c = context.ex;
    final focused = _focusNode.hasFocus;
    final accent = focused ? ExColors.brandGreen : c.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ExSpace.s4,
        ExSpace.s3,
        ExSpace.s4,
        ExSpace.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(ExRadius.md),
                border: Border.all(
                  color: focused ? ExColors.brandGreen : c.border,
                  width: focused ? 1.5 : 1,
                ),
                boxShadow: focused ? ExEffects.focusRing : null,
              ),
              child: Row(
                children: [
                  const SizedBox(width: ExSpace.s3 + 2),
                  Icon(Icons.search_rounded, size: 18, color: accent),
                  const SizedBox(width: ExSpace.s2),
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: ExText.bodyLg(c.textPrimary),
                      cursorColor: ExColors.brandGreen,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: ExSpace.s3 + 1,
                        ),
                        hintText: 'Buscar por título…',
                        hintStyle: ExText.bodyLg(c.textMuted),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _rememberSearch,
                    ),
                  ),
                  if (_queryController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear_rounded,
                          size: 18, color: c.textSecondary),
                      onPressed: () {
                        _queryController.clear();
                        setState(() {});
                      },
                    )
                  else
                    const SizedBox(width: ExSpace.s2),
                ],
              ),
            ),
          ),
          const SizedBox(width: ExSpace.s2),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text('Cancelar', style: ExText.h3(c.textAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState(BuildContext context) {
    final c = context.ex;
    if (_recentSearches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ExSpace.s12),
          child: Text(
            'Digite para buscar tarefas ativas.',
            textAlign: TextAlign.center,
            style: ExText.body(c.textMuted),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ExSpace.s5,
            ExSpace.s4,
            ExSpace.s5,
            ExSpace.s3,
          ),
          child: const ExSectionLabel(label: 'Buscas recentes'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ExSpace.s5),
          child: Wrap(
            spacing: ExSpace.s2,
            runSpacing: ExSpace.s2,
            children: [
              for (final term in _recentSearches)
                _RecentSearchChip(
                  label: term,
                  onTap: () {
                    _queryController.text = term;
                    _queryController.selection = TextSelection.fromPosition(
                      TextPosition(offset: term.length),
                    );
                    _focusNode.requestFocus();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final c = context.ex;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ExSpace.s12),
        child: Text(
          'Nenhuma tarefa encontrada.',
          textAlign: TextAlign.center,
          style: ExText.body(c.textMuted),
        ),
      ),
    );
  }
}

class _RecentSearchChip extends StatelessWidget {
  const _RecentSearchChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ExRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(ExRadius.pill),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 13, color: c.textSecondary),
              const SizedBox(width: ExSpace.s2 - 2),
              Text(
                label,
                style: ExText.body(c.textSecondary).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
