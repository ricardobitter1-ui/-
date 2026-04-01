import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business_logic/complete_task_action.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/task_occurrence_display.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../constants/geofence_constants.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_recurrence.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import 'custom_avatar.dart';
import '../../data/services/location_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_public_profile.dart';
import '../../app_navigator.dart';
import '../theme/app_theme.dart';
import 'group_tag_name_color_dialog.dart';
import 'task_schedule_dialog.dart';

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
  });

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

  bool get _isEditing => widget.initialTask != null;

  bool get _showAssignees =>
      widget.collaborationGroup != null &&
      widget.forcedGroupId != null &&
      widget.forcedGroupId == widget.collaborationGroup!.id;

  String? get _effectiveGroupId {
    final f = widget.forcedGroupId?.trim();
    if (f != null && f.isNotEmpty) return f;
    final g = widget.initialTask?.groupId?.trim();
    if (g != null && g.isNotEmpty) return g;
    return null;
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

    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocus.requestFocus();
      });
    } else if (widget.openScheduleDialogOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openScheduleDialog();
      });
    }
  }

  @override
  void dispose() {
    _titleFocus.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _openScheduleDialog() async {
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

    try {
      DateTime? finalDueDate;
      TaskRecurrenceRule? recurrenceForSave;
      if (_reminderType == 'datetime' && _selectedDate != null) {
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
      if (_reminderType == 'location') {
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

      final dueHasTimeForSave =
          _reminderType == 'datetime' && _dueHasTime && _selectedTime != null;

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
        reminderType: _reminderType == 'none' ? null : _reminderType,
        dueDate: finalDueDate,
        dueHasTime: dueHasTimeForSave,
        locationTrigger: _reminderType == 'location' ? _locationTrigger : null,
        ownerId: widget.initialTask?.ownerId,
        groupId: widget.forcedGroupId ?? widget.initialTask?.groupId,
        createdBy: widget.initialTask?.createdBy,
        assigneeIds: _showAssignees
            ? _selectedAssigneeIds.toList()
            : (widget.initialTask?.assigneeIds ?? const []),
        tagIds: tagIdsForSave,
        recurrence: _reminderType == 'datetime' ? recurrenceForSave : null,
      );

      final ns = ref.read(notificationServiceProvider);

      if (_reminderType == 'datetime' &&
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

      final fs = ref.read(firebaseServiceProvider);
      late final String savedId;
      if (_isEditing) {
        await fs.updateTask(task);
        savedId = task.id;
      } else {
        savedId = await fs.addTask(task);
      }

      final persisted = task.copyWith(id: savedId);
      if (_reminderType == 'datetime') {
        try {
          await ns.syncTaskDatetimeReminders(persisted);
        } catch (e) {
          print('Erro no agendamento: $e');
        }
      } else {
        await ns.cancelAllTaskReminderSlots(savedId);
      }

      if (mounted) Navigator.of(context).pop();
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
      if (mounted) setState(() => _isLoading = false);
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
                          'Nenhuma etiqueta noutros grupos.',
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

    if (_showAssigneesSection && _showAssignees && profilesAsync != null) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
        children.add(const Divider(height: 1));
        children.add(const SizedBox(height: 12));
      }
      children.add(_buildAssigneesPanel(context, profilesAsync, me));
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

  Widget _buildAssigneesPanel(
    BuildContext context,
    AsyncValue<Map<String, UserPublicProfile?>> profilesAsync,
    User? me,
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
            children: widget.collaborationGroup!.members.map((mid) {
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
    final profilesAsync = _showAssignees
        ? ref.watch(
            groupMemberProfilesProvider(
              memberUidsCacheKey(widget.collaborationGroup!.members),
            ),
          )
        : null;
    final me = ref.watch(authStateProvider).value;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Theme(
      data: AppTheme.lightTheme,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Editar Tarefa' : 'Nova Tarefa',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                focusNode: _titleFocus,
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'O que você precisa fazer?',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              if (widget.showReminderQuickActions && _isEditing) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _quickMarkComplete,
                        child: const Text('Marcar como concluída'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _openScheduleDialog,
                        child: const Text('Reprogramar'),
                      ),
                    ),
                  ],
                ),
              ],
              if (_anyOptionalSectionOpen) ...[
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildOptionalSections(context, profilesAsync, me),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _iconBarItem(
                    icon: Icons.notes_outlined,
                    tooltip: 'Descrição',
                    selected: _showDescriptionSection,
                    onTap: _toggleDescriptionSection,
                  ),
                  _iconBarItem(
                    icon: Icons.event_outlined,
                    tooltip: 'Agendamento',
                    selected: _reminderType != 'none',
                    onTap: _openScheduleDialog,
                  ),
                  if (_showTagSelector)
                    _iconBarItem(
                      icon: Icons.label_outline,
                      tooltip: 'Etiquetas',
                      selected: _showTagsSection,
                      onTap: _toggleTagsSection,
                    ),
                  if (_showAssignees)
                    _iconBarItem(
                      icon: Icons.people_outline,
                      tooltip: 'Responsáveis',
                      selected: _showAssigneesSection,
                      onTap: _toggleAssigneesSection,
                    ),
                ],
              ),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_isEditing ? 'Salvar Alterações' : 'Criar Tarefa'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBarItem({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = selected ? AppTheme.brandPrimary : Colors.grey.shade600;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: c, size: 26),
    );
  }
}
