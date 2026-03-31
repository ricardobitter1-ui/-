import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business_logic/providers/task_provider.dart';
import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../data/models/tag_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firebase_service.dart';
import 'custom_avatar.dart';
import '../../data/services/location_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/group_model.dart';
import '../../data/models/task_model.dart';
import '../theme/app_theme.dart';

const _kPresetTagColors = <int>[
  0xFFE53935,
  0xFFD81B60,
  0xFF8E24AA,
  0xFF5E35B1,
  0xFF3949AB,
  0xFF1E88E5,
  0xFF00897B,
  0xFF43A047,
  0xFFFDD835,
  0xFFF4511E,
  0xFF6D4C41,
  0xFF546E7A,
];

class TaskFormModal extends ConsumerStatefulWidget {
  final TaskModel? initialTask;
  final String? forcedGroupId;
  /// Quando preenchido com o grupo da tarefa, permite escolher responsáveis (membros).
  final GroupModel? collaborationGroup;

  const TaskFormModal({
    super.key,
    this.initialTask,
    this.forcedGroupId,
    this.collaborationGroup,
  });

  @override
  ConsumerState<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends ConsumerState<TaskFormModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  String _reminderType = 'none';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _locationTrigger = 'arrival';

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

  /// Grupo para etiquetas: formulário de grupo ou tarefa de grupo editada a partir da Home.
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
        _selectedDate = task.dueDate;
        _selectedTime = TimeOfDay.fromDateTime(task.dueDate!);
      }
      _locationTrigger = task.locationTrigger ?? 'arrival';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      DateTime? finalDueDate;
      if (_reminderType == 'datetime' &&
          _selectedDate != null &&
          _selectedTime != null) {
        finalDueDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      List<String> tagIdsForSave;
      if (_showTagSelector) {
        // Seleção direta; as rules do Firestore validam ids (evita corrida com o stream).
        tagIdsForSave = _selectedTagIds.toList();
      } else {
        tagIdsForSave = widget.initialTask?.tagIds ?? const [];
      }

      double? lat;
      double? lng;
      if (_reminderType == 'location') {
        final position = await ref
            .read(locationServiceProvider)
            .getCurrentLocation();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        } else {
          lat = widget.initialTask?.latitude;
          lng = widget.initialTask?.longitude;
        }
      }

      // titleSearchKey é derivado do título no modelo e reforçado em addTask/updateTask.
      final task = TaskModel(
        id: widget.initialTask?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        isCompleted: widget.initialTask?.isCompleted ?? false,
        latitude: lat,
        longitude: lng,
        reminderType: _reminderType == 'none' ? null : _reminderType,
        dueDate: finalDueDate,
        locationTrigger: _reminderType == 'location' ? _locationTrigger : null,
        ownerId: widget.initialTask?.ownerId,
        groupId: widget.forcedGroupId ?? widget.initialTask?.groupId,
        createdBy: widget.initialTask?.createdBy,
        assigneeIds: _showAssignees
            ? _selectedAssigneeIds.toList()
            : (widget.initialTask?.assigneeIds ?? const []),
        tagIds: tagIdsForSave,
      );

      // Gerenciar Notificação Local
      final ns = ref.read(notificationServiceProvider);

      // Se estamos editando, cancelamos a notificação antiga se ela existia
      // (Para simplificar, usamos o hash do ID como notifId se for edição,
      // ou o milisegundo atual se for novo. Idealmente o TaskModel teria um campo notifId).
      // Vamos usar task.id.hashCode como ID estável para notificações de uma tarefa específica.
      final notifId = task.id.isNotEmpty
          ? task.id.hashCode
          : DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (_reminderType == 'datetime' && finalDueDate != null) {
        if (finalDueDate.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aviso: O horário agendado precisa ser no futuro!'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        try {
          await ns.scheduleTaskReminder(
            notifId,
            task.title,
            task.description.isEmpty
                ? "Hora de completar sua tarefa!"
                : task.description,
            finalDueDate,
          );
        } catch (e) {
          print('Erro no agendamento: $e');
        }
      } else {
        // Se mudou para 'none' ou 'location', remove o alarme de data/hora se existir
        await ns.cancelNotification(notifId);
      }

      final fs = ref.read(firebaseServiceProvider);
      if (_isEditing) {
        await fs.updateTask(task);
      } else {
        await fs.addTask(task);
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

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDate = pickedDate;
      _selectedTime = pickedTime;
    });
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
      builder: (ctx) => const _NewGroupTagDialogContent(),
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
              Text(
                'Etiquetas',
                style: theme.textTheme.titleMedium,
              ),
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 20, left: 24, right: 24, bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? "Editar Tarefa" : "Nova Tarefa",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'O que você precisa fazer?',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        hintText: 'Detalhe a tarefa (opcional)',
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    if (_showTagSelector) ...[
                      const SizedBox(height: 16),
                      _buildTagSelectorSection(context),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      "Me lembre por:",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildReminderTypeSelector(context),
                    if (_reminderType == 'datetime') _buildDateTimeUI(),
                    if (_reminderType == 'location') _buildLocationUI(),
                    if (_showAssignees && profilesAsync != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Responsáveis',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Toque para atribuir membros do grupo.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
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
                        : Text(_isEditing ? "Salvar Alterações" : "Criar Tarefa"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    Widget tile({
      required String value,
      required String label,
      required IconData icon,
    }) {
      final selected = _reminderType == value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => setState(() => _reminderType = value),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryBlue
                      : theme.colorScheme.outline.withValues(alpha: 0.28),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AppTheme.primaryBlue
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? AppTheme.primaryBlue
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile(
          value: 'none',
          label: 'Sem alarme',
          icon: Icons.alarm_off_outlined,
        ),
        tile(
          value: 'datetime',
          label: 'Data e hora',
          icon: Icons.calendar_today_outlined,
        ),
        tile(
          value: 'location',
          label: 'Localização',
          icon: Icons.place_outlined,
        ),
      ],
    );
  }

  Widget _buildDateTimeUI() {
    String dateText = 'Tocar para Escolher';
    if (_selectedDate != null && _selectedTime != null) {
      dateText =
          "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} às ${_selectedTime!.format(context)}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled, color: AppTheme.primaryBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dateText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          TextButton(onPressed: _pickDateTime, child: const Text("ALTERAR")),
        ],
      ),
    );
  }

  Widget _buildLocationUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Disparar alerta invisível por GPS:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text("Ao Chegar"),
                selected: _locationTrigger == 'arrival',
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (val) {
                  if (val) setState(() => _locationTrigger = 'arrival');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text("Ao Sair"),
                selected: _locationTrigger == 'departure',
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (val) {
                  if (val) setState(() => _locationTrigger = 'departure');
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "📍 O lembrete captura sua coordenada atual.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Diálogo com [TextEditingController] próprio — dispose só após a rota fechar (evita IME após dispose).
class _NewGroupTagDialogContent extends StatefulWidget {
  const _NewGroupTagDialogContent();

  @override
  State<_NewGroupTagDialogContent> createState() =>
      _NewGroupTagDialogContentState();
}

class _NewGroupTagDialogContentState extends State<_NewGroupTagDialogContent> {
  late final TextEditingController _nameCtrl;
  late int _pickedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _pickedColor = _kPresetTagColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova etiqueta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Nome (ex.: Verduras)',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kPresetTagColors.map((c) {
                final sel = _pickedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _pickedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (name: name, color: _pickedColor));
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}
