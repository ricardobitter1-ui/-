import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business_logic/complete_task_action.dart';
import '../../business_logic/providers/group_provider.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../constants/geofence_constants.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_recurrence.dart';
import '../../data/services/auth_service.dart';
import '../../data/providers/group_tags_cache_provider.dart';
import '../../data/services/firebase_service.dart';
import 'custom_avatar.dart';
import '../../data/services/location_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../app_navigator.dart';
import '../theme/color_utils.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import '../theme/group_icon.dart';
import 'eximium/eximium.dart';
import 'group_tag_name_color_dialog.dart';
import 'notification_permission_sheet.dart';
import 'task_schedule_dialog.dart';
import 'voice_task_recording_sheet.dart';

class TaskFormModal extends ConsumerStatefulWidget {
  final TaskModel? initialTask;
  final String? forcedGroupId;
  final GroupModel? collaborationGroup;

  /// Atalhos para fluxo de lembrete (notificação).
  final bool showReminderQuickActions;

  /// Abre o diálogo de agendamento ao exibir (ex.: ação Reprogramar na notificação).
  final bool openScheduleDialogOnOpen;

  const TaskFormModal({
    super.key,
    this.initialTask,
    this.forcedGroupId,
    this.collaborationGroup,
    this.showReminderQuickActions = false,
    this.openScheduleDialogOnOpen = false,
    this.onStartVoiceCapture,
  });

  /// Se null, o modal abre o sheet de ditado padrão.
  final VoidCallback? onStartVoiceCapture;

  @override
  ConsumerState<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends ConsumerState<TaskFormModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  final FocusNode _titleFocus = FocusNode();

  bool _showDescriptionSection = false;
  bool _showTagsSection = false;
  bool _showAssigneesSection = false;

  String _reminderType = 'none';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _dueHasTime = false;
  TaskRecurrenceRule? _recurrence;

  String _locationTrigger = 'arrival';
  double? _locationLat;
  double? _locationLng;
  double _locationRadiusMeters = kDefaultGeofenceRadiusMeters;
  String? _locationLabel;

  bool _isLoading = false;
  final Set<String> _selectedAssigneeIds = {};
  final Set<String> _selectedTagIds = {};
  bool _loadingSuggestions = false;
  bool _suggestionsFetched = false;
  List<TagModel> _suggestionTags = [];

  /// Grupo escolhido no picker (nova tarefa ou edição de tarefa sem grupo).
  GroupModel? _selectedGroupForNewTask;

  bool get _isEditing => widget.initialTask != null;

  bool get _editingTaskWithoutGroup =>
      _isEditing &&
      (widget.initialTask?.groupId?.trim().isEmpty ?? true);

  /// Picker de grupo na barra de ícones (criação ou tarefa sem grupo ao editar).
  bool get _canPickGroup {
    final forced = widget.forcedGroupId?.trim();
    if (forced != null && forced.isNotEmpty) return false;
    if (!_isEditing) return true;
    return _editingTaskWithoutGroup;
  }

  /// Grupo cujo contexto de colaboração (membros / responsáveis) está disponível.
  GroupModel? get _activeCollaborationGroup {
    final forced = widget.forcedGroupId?.trim();
    if (forced != null &&
        forced.isNotEmpty &&
        widget.collaborationGroup != null &&
        widget.collaborationGroup!.id == forced) {
      return widget.collaborationGroup;
    }
    final forcedEmpty = forced == null || forced.isEmpty;
    if (forcedEmpty && (!_isEditing || _editingTaskWithoutGroup)) {
      return _selectedGroupForNewTask;
    }
    return null;
  }

  bool get _showAssignees {
    final c = _activeCollaborationGroup;
    final gid = _effectiveGroupId;
    return c != null && gid != null && gid == c.id;
  }

  String? get _effectiveGroupId {
    final f = widget.forcedGroupId?.trim();
    if (f != null && f.isNotEmpty) return f;
    final g = widget.initialTask?.groupId?.trim();
    if (g != null && g.isNotEmpty) return g;
    return _selectedGroupForNewTask?.id;
  }

  GroupModel? _resolveEffectiveGroup(WidgetRef ref) {
    final gid = _effectiveGroupId?.trim();
    if (gid == null || gid.isEmpty) return null;

    final forced = widget.forcedGroupId?.trim();
    if (forced != null &&
        forced == gid &&
        widget.collaborationGroup != null &&
        widget.collaborationGroup!.id == gid) {
      return widget.collaborationGroup;
    }
    if (_selectedGroupForNewTask?.id == gid) {
      return _selectedGroupForNewTask;
    }
    final groups = ref.read(groupsStreamProvider).value ?? const <GroupModel>[];
    for (final g in groups) {
      if (g.id == gid) return g;
    }
    return widget.collaborationGroup;
  }

  bool _isContinuousListGroup(WidgetRef ref) {
    return _resolveEffectiveGroup(ref)?.typeConfig.continuous ?? false;
  }

  void _clearScheduleState() {
    _reminderType = 'none';
    _selectedDate = null;
    _selectedTime = null;
    _dueHasTime = false;
    _recurrence = null;
    _locationLat = null;
    _locationLng = null;
    _locationLabel = null;
  }

  bool get _showTagSelector => _effectiveGroupId != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    if (task?.assigneeIds.isNotEmpty ?? false) {
      _selectedAssigneeIds.addAll(task!.assigneeIds);
    }
    if (task?.tagIds.isNotEmpty ?? false) {
      _selectedTagIds.addAll(task!.tagIds);
    }

    if (task != null) {
      _reminderType = task.reminderType ?? 'none';
      if (task.dueDate != null) {
        final d = task.dueDate!;
        _selectedDate = DateTime(d.year, d.month, d.day);
        _dueHasTime = task.dueHasTime;
        if (_dueHasTime) {
          _selectedTime = TimeOfDay(hour: d.hour, minute: d.minute);
        }
      }

      _recurrence = task.recurrence;
      _locationTrigger = task.locationTrigger ?? 'arrival';
      if (task.reminderType == 'location') {
        _locationLat = task.latitude;
        _locationLng = task.longitude;
        _locationRadiusMeters = effectiveGeofenceRadiusMeters(task);
        _locationLabel = task.locationLabel;
      }
    }

    if (task?.description.isNotEmpty == true) {
      _showDescriptionSection = true;
    }

    _titleFocus.addListener(_onTitleFocusChanged);

    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    } else if (widget.openScheduleDialogOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isContinuousListGroup(ref)) _openScheduleDialog();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isContinuousListGroup(ref)) {
        setState(_clearScheduleState);
      }
    });
  }

  void _onTitleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_onTitleFocusChanged);
    _titleFocus.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _openScheduleDialog() async {
    if (_isContinuousListGroup(ref)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showTaskScheduleDialog(
      context,
      ref,
      initial: TaskScheduleDialogResult(
        reminderType: _reminderType,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        dueHasTime: _dueHasTime,
        recurrence: _recurrence,
        locationTrigger: _locationTrigger,
        locationLat: _locationLat,
        locationLng: _locationLng,
        locationRadiusMeters: _locationRadiusMeters,
        locationLabel: _locationLabel,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _reminderType = result.reminderType;
      _selectedDate = result.selectedDate;
      _selectedTime = result.selectedTime;
      _dueHasTime = result.dueHasTime;
      _recurrence = result.recurrence;
      _locationTrigger = result.locationTrigger;
      _locationLat = result.locationLat;
      _locationLng = result.locationLng;
      _locationRadiusMeters = result.locationRadiusMeters;
      _locationLabel = result.locationLabel;
    });
  }

  void _applyPickedGroup(GroupModel? g) {
    setState(() {
      if (g?.id != _selectedGroupForNewTask?.id) {
        _selectedTagIds.clear();
        _selectedAssigneeIds.clear();
      }
      _selectedGroupForNewTask = g;
      if (g?.typeConfig.continuous ?? false) {
        _clearScheduleState();
      }
    });
  }

  Future<void> _openGroupPickerSheet() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final asyncGroups = ref.read(groupsStreamProvider);
    if (asyncGroups.isLoading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carregando grupos…')),
        );
      }
      return;
    }
    if (asyncGroups.hasError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${asyncGroups.error}')),
        );
      }
      return;
    }
    final groups = List<GroupModel>.from(asyncGroups.value ?? const []);
    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = ctx.ex;
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.surface1,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ExRadius.xl),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Grupo da tarefa (opcional)',
                    style: ExText.h3(c.textPrimary),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.person_outline, color: c.textSecondary),
                  title: Text('Nenhum', style: ExText.body(c.textPrimary)),
                  subtitle: Text(
                    'Só para mim',
                    style: ExText.small(c.textMuted),
                  ),
                  trailing: _selectedGroupForNewTask == null
                      ? Icon(Icons.check, color: c.textAccent)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _applyPickedGroup(null);
                  },
                ),
                Divider(height: 1, color: c.border),
                if (groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Você ainda não tem grupos. Crie um na aba Grupos.',
                      textAlign: TextAlign.center,
                      style: ExText.body(c.textSecondary),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: groups.length,
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        final sel = _selectedGroupForNewTask?.id == g.id;
                        final tint = parseAppHexColor(g.color);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: tint.withValues(alpha: 0.2),
                            child: Icon(groupIconFromKey(g.icon), color: tint),
                          ),
                          title: Text(g.name, style: ExText.body(c.textPrimary)),
                          subtitle: g.isPersonal
                              ? Text(
                                  'Grupo pessoal',
                                  style: ExText.small(c.textMuted),
                                )
                              : null,
                          trailing: sel
                              ? Icon(Icons.check, color: c.textAccent)
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            _applyPickedGroup(g);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _quickMarkComplete() async {
    final task = widget.initialTask;
    if (task == null || task.id.isEmpty) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (isOccurrenceCompletedOnCalendarDay(task, today)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarefa já está concluída.')),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final fs = ref.read(firebaseServiceProvider);
      final ns = ref.read(notificationServiceProvider);
      await completeTaskToggle(
        fs: fs,
        ns: ns,
        task: task,
        occurrenceCalendarDay: today,
      );
      if (!mounted) return;
      final root = rootNavigatorKey.currentContext;
      if (root != null) {
        ScaffoldMessenger.of(root).showSnackBar(
          const SnackBar(content: Text('Tarefa concluída.')),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    var popped = false;
    try {
      final continuous = _isContinuousListGroup(ref);
      if (continuous) {
        _clearScheduleState();
      }

      DateTime? finalDueDate;
      TaskRecurrenceRule? recurrenceForSave;
      if (!continuous &&
          _reminderType == 'datetime' &&
          _selectedDate != null) {
        final d = _selectedDate!;
        if (_dueHasTime && _selectedTime != null) {
          finalDueDate = DateTime(
            d.year,
            d.month,
            d.day,
            _selectedTime!.hour,
            _selectedTime!.minute,
          );
        } else {
          finalDueDate = DateTime(d.year, d.month, d.day);
        }
        recurrenceForSave = _recurrence;
      }

      List<String> tagIdsForSave;
      if (_showTagSelector) {
        tagIdsForSave = _selectedTagIds.toList();
      } else {
        tagIdsForSave = widget.initialTask?.tagIds ?? const [];
      }

      double? lat;
      double? lng;
      double? geofenceRadius;
      String? locationLabel;
      if (!continuous && _reminderType == 'location') {
        if (_locationLat == null || _locationLng == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Escolha o local no mapa antes de salvar.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
        if (!kIsWeb && Platform.isAndroid) {
          final bgOk = await ref
              .read(locationServiceProvider)
              .ensureBackgroundLocationPermission();
          if (!bgOk && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Para lembretes ao chegar/sair, permita localização '
                  '“o tempo todo” nas configurações.',
                ),
                action: SnackBarAction(
                  label: 'Abrir',
                  onPressed: () => ref
                      .read(locationServiceProvider)
                      .openSystemLocationSettings(),
                ),
              ),
            );
          }
        }
        lat = _locationLat;
        lng = _locationLng;
        geofenceRadius = _locationRadiusMeters;
        locationLabel = _locationLabel;
      }

      final reminderType = continuous ? 'none' : _reminderType;
      final dueHasTimeForSave = !continuous &&
          reminderType == 'datetime' &&
          _dueHasTime &&
          _selectedTime != null;

      final task = TaskModel(
        id: widget.initialTask?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        isCompleted: widget.initialTask?.isCompleted ?? false,
        completedOccurrenceDateKeys:
            widget.initialTask?.completedOccurrenceDateKeys ?? const [],
        latitude: lat,
        longitude: lng,
        geofenceRadiusMeters: geofenceRadius,
        locationLabel: locationLabel,
        reminderType: reminderType == 'none' ? null : reminderType,
        dueDate: continuous ? null : finalDueDate,
        dueHasTime: dueHasTimeForSave,
        locationTrigger:
            reminderType == 'location' ? _locationTrigger : null,
        ownerId: widget.initialTask?.ownerId,
        groupId: _effectiveGroupId,
        createdBy: widget.initialTask?.createdBy,
        assigneeIds: _showAssignees
            ? _selectedAssigneeIds.toList()
            : (widget.initialTask?.assigneeIds ?? const []),
        tagIds: tagIdsForSave,
        recurrence: reminderType == 'datetime' ? recurrenceForSave : null,
      );

      final ns = ref.read(notificationServiceProvider);

      if (!continuous &&
          reminderType == 'datetime' &&
          dueHasTimeForSave &&
          finalDueDate != null &&
          finalDueDate.isBefore(DateTime.now()) &&
          task.recurrence == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('O horário agendado precisa ser no futuro!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      if (!continuous &&
          (reminderType == 'datetime' || reminderType == 'location')) {
        final ns = ref.read(notificationServiceProvider);
        if (mounted) {
          await ensureNotificationPermissionsIfNeeded(context, ns);
        }
      }

      final fs = ref.read(firebaseServiceProvider);
      late final String savedId;
      if (_isEditing) {
        await fs.updateTask(task);
        savedId = task.id;
      } else {
        savedId = await fs.addTask(task);
      }

      final persisted = task.copyWith(id: savedId);
      // Fechar o sheet imediatamente — não aguardar sync de notificações.
      if (mounted) {
        Navigator.of(context).pop();
        popped = true;
      }

      // Sincronizar notificações em background (fire-and-forget).
      if (!continuous && reminderType == 'datetime') {
        ns.syncTaskDatetimeReminders(persisted).catchError((e) {
          debugPrint('Erro no agendamento: $e');
        });
      } else {
        ns.cancelAllTaskReminderSlots(savedId).catchError((e) {
          debugPrint('Erro ao cancelar notificações: $e');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted && !popped) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSuggestions(String currentGroupId) async {
    setState(() => _loadingSuggestions = true);
    try {
      final list = await ref
          .read(firebaseServiceProvider)
          .fetchSuggestionTagsExcludingGroup(currentGroupId);
      if (mounted) {
        setState(() {
          _suggestionTags = list;
          _loadingSuggestions = false;
          _suggestionsFetched = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingSuggestions = false;
          _suggestionsFetched = true;
        });
      }
    }
  }

  Future<void> _importSuggestion(String gid, TagModel suggestion) async {
    try {
      final id = await ref.read(firebaseServiceProvider).addGroupTag(
            groupId: gid,
            name: suggestion.name,
            color: suggestion.color,
          );
      ref.read(groupTagsCacheProvider.notifier).invalidate(gid);
      if (mounted) {
        setState(() => _selectedTagIds.add(id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _showNewTagDialog(String groupId) async {
    final result = await showDialog<({String name, int color})>(
      context: context,
      builder: (ctx) => const GroupTagNameColorDialog(),
    );
    if (result == null || !mounted) return;
    try {
      final id = await ref.read(firebaseServiceProvider).addGroupTag(
            groupId: groupId,
            name: result.name,
            color: result.color,
          );
      ref.read(groupTagsCacheProvider.notifier).invalidate(groupId);
      setState(() => _selectedTagIds.add(id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Widget _buildTagSelectorSection(BuildContext context) {
    final gid = _effectiveGroupId!;
    final theme = Theme.of(context);
    return ref.watch(groupTagsStreamProvider(gid)).when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(
            'Etiquetas: $e',
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
          data: (tags) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Etiquetas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Opcional. Toque para marcar; até 10 por tarefa.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...tags.map((tag) {
                    final sel = _selectedTagIds.contains(tag.id);
                    return FilterChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(tag.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(tag.name),
                        ],
                      ),
                      selected: sel,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            if (_selectedTagIds.length >= 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Máximo de 10 etiquetas.'),
                                ),
                              );
                              return;
                            }
                            _selectedTagIds.add(tag.id);
                          } else {
                            _selectedTagIds.remove(tag.id);
                          }
                        });
                      },
                    );
                  }),
                  ActionChip(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Nova etiqueta'),
                    onPressed: () => _showNewTagDialog(gid),
                  ),
                ],
              ),
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Sugestões de outros grupos'),
                  onExpansionChanged: (exp) {
                    if (exp && !_suggestionsFetched && !_loadingSuggestions) {
                      _loadSuggestions(gid);
                    }
                  },
                  children: [
                    if (_loadingSuggestions)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (!_suggestionsFetched)
                      const SizedBox.shrink()
                    else if (_suggestionTags.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Nenhuma etiqueta em outros grupos.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestionTags.map((st) {
                            return ActionChip(
                              avatar: CircleAvatar(
                                backgroundColor: Color(st.color),
                                radius: 10,
                              ),
                              label: Text(st.name),
                              onPressed: () => _importSuggestion(gid, st),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildOptionalSections(
    BuildContext context,
    AsyncValue<Map<String, UserPublicProfile?>>? profilesAsync,
    User? me,
    GroupModel? collaborationForAssignees,
  ) {
    final children = <Widget>[];

    if (_showDescriptionSection) {
      children.add(
        TextField(
          controller: _descController,
          decoration: const InputDecoration(
            hintText: 'Detalhe a tarefa (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      );
    }

    if (_showTagsSection && _showTagSelector) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
        children.add(const Divider(height: 1));
        children.add(const SizedBox(height: 12));
      }
      children.add(_buildTagSelectorSection(context));
    }

    if (_showAssigneesSection &&
        _showAssignees &&
        profilesAsync != null &&
        collaborationForAssignees != null) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
        children.add(const Divider(height: 1));
        children.add(const SizedBox(height: 12));
      }
      children.add(
        _buildAssigneesPanel(context, profilesAsync, me, collaborationForAssignees),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  void _toggleDescriptionSection() {
    final opening = !_showDescriptionSection;
    if (opening) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    setState(() => _showDescriptionSection = !_showDescriptionSection);
  }

  void _toggleTagsSection() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showTagsSection = !_showTagsSection);
  }

  void _toggleAssigneesSection() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showAssigneesSection = !_showAssigneesSection);
  }

  void _openVoiceFromForm() {
    if (widget.onStartVoiceCapture != null) {
      widget.onStartVoiceCapture!();
      return;
    }
    final groups = ref.read(groupsStreamProvider).value ?? const [];
    final forced = widget.forcedGroupId?.trim();
    GroupModel? contextGroup = widget.collaborationGroup;
    if (contextGroup == null && forced != null && forced.isNotEmpty) {
      for (final g in groups) {
        if (g.id == forced) {
          contextGroup = g;
          break;
        }
      }
    }
    Navigator.of(context).pop();
    showVoiceTaskRecordingSheet(
      context: context,
      groups: groups,
      forcedGroupId: forced,
      contextGroup: contextGroup,
    );
  }

  Widget _buildAssigneesPanel(
    BuildContext context,
    AsyncValue<Map<String, UserPublicProfile?>> profilesAsync,
    User? me,
    GroupModel group,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Responsáveis', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Toque para atribuir membros do grupo.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 6),
        profilesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text(
            'Erro ao carregar nomes: $e',
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
          data: (profileMap) => Wrap(
            spacing: 6,
            runSpacing: 6,
            children: group.members.map((mid) {
              final selected = _selectedAssigneeIds.contains(mid);
              final label = memberDisplayLabel(mid, profileMap);
              return FilterChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                avatar: CustomAvatar(
                  photoUrl: memberPhotoUrl(
                    mid,
                    profileMap,
                    selfUid: me?.uid,
                    selfPhotoUrl: me?.photoURL,
                  ),
                  displayName: label,
                  radius: 12,
                ),
                label: Text(label),
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _selectedAssigneeIds.add(mid);
                    } else {
                      _selectedAssigneeIds.remove(mid);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  bool get _anyOptionalSectionOpen =>
      _showDescriptionSection ||
      _showTagsSection ||
      _showAssigneesSection;

  @override
  Widget build(BuildContext context) {
    final collab = _activeCollaborationGroup;
    final profilesAsync = collab != null && _showAssignees
        ? ref.watch(
            groupMemberProfilesProvider(
              memberUidsCacheKey(collab.members),
            ),
          )
        : null;
    final me = ref.watch(authStateProvider).value;
    final continuous = _isContinuousListGroup(ref);

    final c = context.ex;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool titleFocused = _titleFocus.hasFocus;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ExRadius.xl),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: ExSpace.s3,
            left: ExSpace.s6,
            right: ExSpace.s6,
            bottom: bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(ExRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: ExSpace.s5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      continuous
                          ? (_isEditing ? 'Editar item' : 'Novo item')
                          : (_isEditing ? 'Editar tarefa' : 'Nova tarefa'),
                      style: ExText.h2(c.textPrimary),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: ExSpace.s4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(ExRadius.md),
                  border: titleFocused
                      ? ExEffects.focusBorder()
                      : Border.all(color: c.border),
                  boxShadow: titleFocused ? ExEffects.focusRing : null,
                ),
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  autofocus: false,
                  style: ExText.h3(c.textPrimary),
                  decoration: InputDecoration(
                    hintText: continuous
                        ? 'O que falta comprar?'
                        : 'O que você precisa fazer?',
                    hintStyle: ExText.h3(c.textMuted),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ExSpace.s4,
                      vertical: ExSpace.s4,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              if (widget.showReminderQuickActions && _isEditing) ...[
                const SizedBox(height: ExSpace.s3),
                Row(
                  children: [
                    Expanded(
                      child: ExButton(
                        label: 'Marcar como concluída',
                        variant: ExButtonVariant.secondary,
                        size: ExButtonSize.sm,
                        expand: true,
                        onPressed: _isLoading ? null : _quickMarkComplete,
                      ),
                    ),
                    const SizedBox(width: ExSpace.s2),
                    Expanded(
                      child: ExButton(
                        label: 'Reprogramar',
                        variant: ExButtonVariant.secondary,
                        size: ExButtonSize.sm,
                        expand: true,
                        onPressed: _isLoading ? null : _openScheduleDialog,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: ExSpace.s4),
              Wrap(
                spacing: ExSpace.s2,
                runSpacing: ExSpace.s2,
                children: [
                  _ActionChip(
                    icon: Icons.notes_rounded,
                    label: 'Descrição',
                    selected: _showDescriptionSection,
                    onTap: _toggleDescriptionSection,
                  ),
                  if (!continuous)
                    _ActionChip(
                      icon: Icons.event_rounded,
                      label: 'Lembrete',
                      selected: _reminderType != 'none',
                      onTap: _openScheduleDialog,
                    ),
                  if (_canPickGroup)
                    _ActionChip(
                      icon: Icons.group_rounded,
                      label: 'Grupo',
                      selected: _selectedGroupForNewTask != null,
                      onTap: _openGroupPickerSheet,
                    ),
                  if (_showTagSelector)
                    _ActionChip(
                      icon: Icons.label_rounded,
                      label: 'Etiquetas',
                      selected: _showTagsSection,
                      onTap: _toggleTagsSection,
                    ),
                  if (_showAssignees)
                    _ActionChip(
                      icon: Icons.people_rounded,
                      label: 'Responsáveis',
                      selected: _showAssigneesSection,
                      onTap: _toggleAssigneesSection,
                    ),
                ],
              ),
              if (_anyOptionalSectionOpen) ...[
                const SizedBox(height: ExSpace.s3),
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildOptionalSections(
                      context,
                      profilesAsync,
                      me,
                      collab,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: ExSpace.s4),
              Divider(height: 1, color: c.border),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: ExSpace.s3, bottom: ExSpace.s2),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.mic_rounded,
                        accent: true,
                        onTap: _openVoiceFromForm,
                      ),
                      const SizedBox(width: ExSpace.s3),
                      Expanded(
                        child: ExButton(
                          label: _isLoading
                              ? 'Salvando…'
                              : (_isEditing
                                  ? 'Salvar alterações'
                                  : 'Salvar tarefa'),
                          variant: ExButtonVariant.primary,
                          size: ExButtonSize.lg,
                          expand: true,
                          onPressed: _isLoading ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão circular (fechar / microfone) do sheet de tarefa.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    return Material(
      color: accent ? Colors.transparent : c.surface2,
      shape: CircleBorder(
        side: BorderSide(color: accent ? c.borderAccent : c.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            size: 22,
            color: accent ? c.textAccent : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Chip de ação (pill) que abre/seleciona uma seção opcional.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final fg = selected ? c.textAccent : c.textSecondary;
    return Material(
      color: selected
          ? ExColors.brandGreen.withValues(alpha: 0.14)
          : c.surface2,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? c.borderAccent : c.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ExSpace.s3,
            vertical: ExSpace.s2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: ExSpace.s2),
              Text(
                label,
                style: ExText.body(fg).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
