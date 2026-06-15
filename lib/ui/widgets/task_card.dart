import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../business_logic/providers/user_public_profile_provider.dart';
import '../../constants/geofence_constants.dart';
import '../../data/models/tag_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/task_recurrence.dart';
import '../../data/models/user_public_profile.dart';
import '../../utils/scheduled_badge_label.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'custom_avatar.dart';
import 'eximium/eximium.dart';

String _locationReminderLabel(TaskModel task) {
  final trigger =
      task.locationTrigger == 'departure' ? 'Ao sair' : 'Ao chegar';
  final r = effectiveGeofenceRadiusMeters(task).round();
  final name = task.locationLabel?.trim();
  if (name != null && name.isNotEmpty) {
    return '$name · ${r}m · $trigger';
  }
  return '$trigger · ${r}m';
}

String _recurrenceChipLabel(TaskRecurrenceRule r) {
  if (r.interval == 1) {
    return switch (r.unit) {
      RecurrenceUnit.day => 'diário',
      RecurrenceUnit.week => 'semanal',
      RecurrenceUnit.month => 'mensal',
      RecurrenceUnit.year => 'anual',
    };
  }
  return TaskRecurrenceRule.shortLabel(r);
}

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  /// Etiquetas a mostrar no cartão (ex.: concluídas com tags do grupo).
  final List<TagModel>? tagChips;
  /// Perfis públicos dos membros (uid → perfil); pode ser vazio — usa-se fallback de rótulo/inicial.
  final Map<String, UserPublicProfile?>? assigneeProfiles;
  final String? selfUid;
  final String? selfPhotoUrl;
  /// Nome do grupo para o chip; omitir na lista dentro de um grupo se não quiser duplicar.
  final String? groupLabel;
  /// Cor do grupo; opcional (cinza se nula).
  final Color? groupAccentColor;
  /// Chave do ícone do grupo ([GroupModel.icon]).
  final String? groupIconKey;
  /// Sobrepõe [TaskModel.dueDate] no badge de agenda (ex.: ocorrência do dia na timeline).
  final DateTime? displayDueOverride;
  /// Sobrepõe [TaskModel.isCompleted] (ex.: conclusão por dia em recorrentes).
  final bool? isCompletedOverride;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onEdit,
    this.onDelete,
    this.tagChips,
    this.assigneeProfiles,
    this.selfUid,
    this.selfPhotoUrl,
    this.groupLabel,
    this.groupAccentColor,
    this.groupIconKey,
    this.displayDueOverride,
    this.isCompletedOverride,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  static const double _minHeight = 64;
  static const double _cardRadius = ExRadius.lg;
  static const double _checkSize = 24;
  static const double _checkHitWidth = 44;
  static const double _maxDrag = 112;
  static const double _actionThreshold = 72;

  double _dragOffset = 0;
  AnimationController? _snapController;
  bool _isDragging = false;

  @override
  void dispose() {
    _stopSnapAnimation();
    super.dispose();
  }

  void _stopSnapAnimation() {
    _snapController?.dispose();
    _snapController = null;
  }

  TaskModel get task => widget.task;
  VoidCallback get onToggle => widget.onToggle;
  VoidCallback? get onEdit => widget.onEdit;
  VoidCallback? get onDelete => widget.onDelete;

  static const double _assigneeRadius = 12;
  static const double _assigneeOverlapStep = 14;
  static const int _maxAssigneeAvatars = 3;

  bool get _hasGroup {
    final id = task.groupId?.trim();
    return id != null && id.isNotEmpty;
  }

  bool get _canSwipeDelete => widget.onDelete != null;

  void _onHorizontalDragStart(DragStartDetails details) {
    _stopSnapAnimation();
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      var next = _dragOffset + details.delta.dx;
      if (!_canSwipeDelete && next < 0) next = 0;
      _dragOffset = next.clamp(-_maxDrag, _maxDrag);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final bool commitComplete = _dragOffset >= _actionThreshold ||
        (velocity > 700 && _dragOffset > _actionThreshold * 0.45);
    final bool commitDelete = _canSwipeDelete &&
        (_dragOffset <= -_actionThreshold ||
            (velocity < -700 && _dragOffset < -_actionThreshold * 0.45));

    if (commitComplete) {
      _finishSwipe(complete: true);
      return;
    }
    if (commitDelete) {
      _finishSwipe(complete: false);
      return;
    }
    _animateOffsetTo(0);
  }

  void _onHorizontalDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _animateOffsetTo(0);
  }

  void _finishSwipe({required bool complete}) {
    if (complete) {
      _animateOffsetTo(_maxDrag, onSettled: () {
        widget.onToggle();
        if (mounted) setState(() => _dragOffset = 0);
      });
    } else {
      _animateOffsetTo(-_maxDrag, onSettled: () {
        widget.onDelete?.call();
        if (mounted) setState(() => _dragOffset = 0);
      });
    }
  }

  void _animateOffsetTo(double target, {VoidCallback? onSettled}) {
    if (_isDragging) return;
    _stopSnapAnimation();

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _snapController = controller;
    final animation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    animation.addListener(() {
      if (!mounted || _isDragging) return;
      setState(() => _dragOffset = animation.value);
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onSettled?.call();
        if (_snapController == controller) _stopSnapAnimation();
      }
    });
    controller.forward();
  }

  Widget _buildSwipeActionLayer({
    required Alignment layerAlignment,
    required double width,
    required Color color,
    required double progress,
    required Alignment iconAlignment,
    required EdgeInsets iconPadding,
    required IconData icon,
    required Color iconColor,
  }) {
    if (width <= 0) return const SizedBox.shrink();

    return Align(
      alignment: layerAlignment,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: ColoredBox(
          color: color.withValues(alpha: 0.12 + 0.88 * progress),
          child: Align(
            alignment: iconAlignment,
            child: Padding(
              padding: iconPadding,
              child: Opacity(
                opacity: progress,
                child: Icon(icon, color: iconColor, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeUnderlay(bool done) {
    final completeWidth = _dragOffset.clamp(0.0, _maxDrag);
    final deleteWidth = _canSwipeDelete
        ? (-_dragOffset).clamp(0.0, _maxDrag)
        : 0.0;
    final completeProgress = completeWidth / _maxDrag;
    final deleteProgress = deleteWidth / _maxDrag;

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        if (completeWidth > 0)
          _buildSwipeActionLayer(
            layerAlignment: Alignment.centerLeft,
            width: completeWidth,
            color: ExColors.brandGreen,
            progress: completeProgress,
            iconAlignment: Alignment.centerRight,
            iconPadding: const EdgeInsets.only(right: 16),
            icon: done ? Icons.undo_rounded : Icons.check_rounded,
            iconColor: ExColors.onBrandGreen,
          ),
        if (deleteWidth > 0)
          _buildSwipeActionLayer(
            layerAlignment: Alignment.centerRight,
            width: deleteWidth,
            color: ExColors.error,
            progress: deleteProgress,
            iconAlignment: Alignment.centerLeft,
            iconPadding: const EdgeInsets.only(left: 16),
            icon: Icons.delete_outline_rounded,
            iconColor: Colors.white,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final bool done = widget.isCompletedOverride ?? widget.task.isCompleted;
    final DateTime? dueForBadge =
        widget.displayDueOverride ?? widget.task.dueDate;
    final bool hasSchedule = dueForBadge != null;

    final bool hasLocation = task.reminderType == 'location';
    final bool hasRecurrence =
        task.recurrence != null && task.reminderType == 'datetime';
    final bool hasAssignees = task.assigneeIds.isNotEmpty;

    final int firstDayIndex =
        MaterialLocalizations.of(context).firstDayOfWeekIndex;

    ScheduledBadgeData? scheduleData;
    if (dueForBadge != null) {
      scheduleData = formatScheduledBadge(
        due: dueForBadge,
        now: DateTime.now(),
        firstDayOfWeekIndex: firstDayIndex,
      );
    }

    final bool isOverdue = scheduleData?.isOverdue ?? false;
    final Color scheduleColor = isOverdue ? c.errorText : c.textAccent;

    // Cor do grupo usada só como ponto (acento mínimo).
    final Color groupDotColor = widget.groupAccentColor ?? ExColors.lavender;

    final bool isToday = dueForBadge != null &&
        DateUtils.isSameDay(dueForBadge, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: ExSpace.s3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: _buildSwipeUnderlay(done)),
            GestureDetector(
              dragStartBehavior: DragStartBehavior.down,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onHorizontalDragCancel: _onHorizontalDragCancel,
              behavior: HitTestBehavior.opaque,
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: _buildCardSurface(
                  context,
                  done: done,
                  groupDotColor: groupDotColor,
                  hasSchedule: hasSchedule,
                  dueForBadge: dueForBadge,
                  scheduleData: scheduleData,
                  scheduleColor: scheduleColor,
                  isOverdue: isOverdue,
                  isToday: isToday,
                  hasRecurrence: hasRecurrence,
                  hasLocation: hasLocation,
                  hasAssignees: hasAssignees,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSurface(
    BuildContext context, {
    required bool done,
    required Color groupDotColor,
    required bool hasSchedule,
    required DateTime? dueForBadge,
    required ScheduledBadgeData? scheduleData,
    required Color scheduleColor,
    required bool isOverdue,
    required bool isToday,
    required bool hasRecurrence,
    required bool hasLocation,
    required bool hasAssignees,
  }) {
    final c = context.ex;

    final String? timeLabel = hasSchedule && dueForBadge != null
        ? DateFormat.Hm('pt_BR').format(dueForBadge)
        : null;

    final surface = Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: isOverdue ? c.errorText.withValues(alpha: 0.35) : c.border,
        ),
        boxShadow: c.shadowCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onEdit,
          borderRadius: BorderRadius.circular(_cardRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ExSpace.s3,
              ExSpace.s3 + 2,
              ExSpace.s4,
              ExSpace.s3 + 2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckboxHitArea(context, done),
                const SizedBox(width: ExSpace.s1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: ExText.bodyLg(
                                done ? c.textMuted : c.textPrimary,
                              ).copyWith(
                                fontWeight: FontWeight.w500,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: c.textMuted,
                              ),
                            ),
                          ),
                          if (timeLabel != null) ...[
                            const SizedBox(width: ExSpace.s2),
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                timeLabel,
                                style: ExText.mono(
                                  size: 12,
                                  color: scheduleColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: ExSpace.s1),
                        Text(
                          task.description,
                          style: ExText.body(c.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      _buildMetaRow(
                        context,
                        groupDotColor: groupDotColor,
                        scheduleData: scheduleData,
                        scheduleColor: scheduleColor,
                        showDateChip: hasSchedule && !isToday,
                        hasRecurrence: hasRecurrence,
                        hasLocation: hasLocation,
                        hasAssignees: hasAssignees,
                      ),
                      if (widget.tagChips != null &&
                          widget.tagChips!.isNotEmpty) ...[
                        const SizedBox(height: ExSpace.s2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in widget.tagChips!)
                              ExGroupChip(
                                label: tag.name,
                                color: Color(tag.color),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Opacity(opacity: done ? 0.7 : 1, child: surface);
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required Color groupDotColor,
    required ScheduledBadgeData? scheduleData,
    required Color scheduleColor,
    required bool showDateChip,
    required bool hasRecurrence,
    required bool hasLocation,
    required bool hasAssignees,
  }) {
    final c = context.ex;
    final chips = <Widget>[];

    if (_hasGroup &&
        widget.groupLabel != null &&
        widget.groupLabel!.isNotEmpty) {
      chips.add(ExGroupChip(label: widget.groupLabel!, color: groupDotColor));
    } else if (!_hasGroup) {
      chips.add(ExMetaChip(
        icon: Icons.checklist_rounded,
        label: 'Sem grupo',
        color: c.textMuted,
      ));
    }

    if (hasRecurrence && task.recurrence != null) {
      chips.add(ExRecurrenceChip(label: _recurrenceChipLabel(task.recurrence!)));
    }

    if (hasAssignees) chips.add(_buildAssigneeStack(context));

    if (hasLocation) {
      chips.add(ExMetaChip(
        icon: Icons.location_on_rounded,
        label: _locationReminderLabel(task),
        color: c.infoText,
      ));
    }

    if (showDateChip && scheduleData != null) {
      chips.add(ExMetaChip(
        icon: Icons.alarm_rounded,
        label: scheduleData.label,
        color: scheduleColor,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: ExSpace.s2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }

  Widget _buildCheckboxHitArea(BuildContext context, bool done) {
    return Semantics(
      button: true,
      label: done
          ? 'Marcar tarefa como pendente'
          : 'Marcar tarefa como concluída',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onToggle,
        child: SizedBox(
          width: _checkHitWidth,
          child: Center(child: _buildCheckboxVisual(context, done)),
        ),
      ),
    );
  }

  Widget _buildAssigneeStack(BuildContext context) {
    final c = context.ex;
    final ids = task.assigneeIds;
    if (ids.isEmpty) return const SizedBox.shrink();

    final map =
        widget.assigneeProfiles ?? const <String, UserPublicProfile?>{};
    final names = ids.map((id) => memberDisplayLabel(id, map)).join(', ');
    final visible = ids.take(_maxAssigneeAvatars).toList();
    final overflow = ids.length - visible.length;
    final stackWidth = visible.isEmpty
        ? 0.0
        : 2 * _assigneeRadius + (visible.length - 1) * _assigneeOverlapStep;

    return Tooltip(
      message: names,
      child: Semantics(
        label: 'Responsáveis: $names',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: stackWidth,
              height: 2 * _assigneeRadius,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < visible.length; i++)
                    Positioned(
                      left: i * _assigneeOverlapStep,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface1, width: 2),
                        ),
                        child: CustomAvatar(
                          radius: _assigneeRadius,
                          photoUrl: memberPhotoUrl(
                            visible[i],
                            map,
                            selfUid: widget.selfUid,
                            selfPhotoUrl: widget.selfPhotoUrl,
                          ),
                          displayName: memberDisplayLabel(visible[i], map),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '+$overflow',
                  style: ExText.body(c.textSecondary).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxVisual(BuildContext context, bool done) {
    final c = context.ex;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      width: _checkSize,
      height: _checkSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? ExColors.brandGreen : c.textMuted,
          width: 1.5,
        ),
        color: done ? ExColors.brandGreen : Colors.transparent,
      ),
      child: done
          ? const Icon(Icons.check, size: 15, color: ExColors.onBrandGreen)
          : null,
    );
  }
}
