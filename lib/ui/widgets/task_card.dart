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
import '../theme/app_theme.dart';
import '../theme/group_icon.dart';
import 'custom_avatar.dart';

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

Color _darkenAccent(Color color, [double amount = 0.35]) {
  return Color.lerp(color, const Color(0xFF1A1A2E), amount) ?? color;
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

/// Texto compacto para o bloco lateral (~60px) com data/hora.
String _lateralScheduleLines(DateTime due, DateTime now) {
  final dueD = DateTime(due.year, due.month, due.day);
  final nowDate = DateTime(now.year, now.month, now.day);
  final timeStr = DateFormat.Hm('pt_BR').format(due);

  if (dueD == nowDate) return timeStr;

  final tomorrow = nowDate.add(const Duration(days: 1));
  if (dueD == tomorrow) return 'Amanhã\n$timeStr';

  final dayAfter = nowDate.add(const Duration(days: 2));
  if (dueD == dayAfter) return 'Depois\namanhã';

  if (dueD.isBefore(nowDate)) {
    final days = nowDate.difference(dueD).inDays;
    if (days == 1) return 'Ontem';
    return 'Há $days\ndias';
  }

  if (due.year == now.year) {
    return '${DateFormat('d/M', 'pt_BR').format(due)}\n$timeStr';
  }
  return '${DateFormat('d/M/yy', 'pt_BR').format(due)}\n$timeStr';
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
  static const double _minHeight = 80;
  static const double _lateralWidth = 60;
  static const double _cardRadius = 16;
  static const double _checkSize = 22;
  static const double _checkHitWidth = 44;
  static const double _maxDrag = 112;
  static const double _actionThreshold = 72;

  static const Color _completeSwipeColor = Color(0xFF22C55E);
  static const Color _deleteSwipeColor = Color(0xFFEF4444);

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

  static const Color _neutralLateralBg = Color(0xFFF0F1F5);
  static const Color _neutralIcon = Color(0xFF9CA3AF);
  static const Color _borderColor = Color(0xFFE8EAEF);

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
                child: Icon(icon, color: Colors.white, size: 28),
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
            color: _completeSwipeColor,
            progress: completeProgress,
            iconAlignment: Alignment.centerRight,
            iconPadding: const EdgeInsets.only(right: 16),
            icon: done ? Icons.undo_rounded : Icons.check_rounded,
          ),
        if (deleteWidth > 0)
          _buildSwipeActionLayer(
            layerAlignment: Alignment.centerRight,
            width: deleteWidth,
            color: _deleteSwipeColor,
            progress: deleteProgress,
            iconAlignment: Alignment.centerLeft,
            iconPadding: const EdgeInsets.only(left: 16),
            icon: Icons.delete_outline_rounded,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool done =
        widget.isCompletedOverride ?? widget.task.isCompleted;
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

    final Color scheduleColor = scheduleData != null && scheduleData.isOverdue
        ? Theme.of(context).colorScheme.error
        : AppTheme.brandPrimary;

    final Color? accent = _hasGroup
        ? (widget.groupAccentColor ?? AppTheme.brandPrimary)
        : null;
    final IconData groupIcon = widget.groupIconKey != null
        ? groupIconFromKey(widget.groupIconKey!)
        : Icons.groups_rounded;

    final bool showDateInLateral = _hasGroup && hasSchedule;
    final bool showDateBadgeInMeta = hasSchedule && !showDateInLateral;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  accent: accent,
                  groupIcon: groupIcon,
                  showDateInLateral: showDateInLateral,
                  dueForBadge: dueForBadge,
                  scheduleData: scheduleData,
                  hasRecurrence: hasRecurrence,
                  hasLocation: hasLocation,
                  hasAssignees: hasAssignees,
                  showDateBadgeInMeta: showDateBadgeInMeta,
                  scheduleColor: scheduleColor,
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
    required Color? accent,
    required IconData groupIcon,
    required bool showDateInLateral,
    required DateTime? dueForBadge,
    required ScheduledBadgeData? scheduleData,
    required bool hasRecurrence,
    required bool hasLocation,
    required bool hasAssignees,
    required bool showDateBadgeInMeta,
    required Color scheduleColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LateralBlock(
                hasGroup: _hasGroup,
                hasSchedule: showDateInLateral,
                accent: accent,
                groupIcon: groupIcon,
                scheduleLines: showDateInLateral && dueForBadge != null
                    ? _lateralScheduleLines(dueForBadge, DateTime.now())
                    : null,
                scheduleIsOverdue: scheduleData?.isOverdue ?? false,
              ),
              _buildCheckboxHitArea(
                context,
                done,
                fillColor: accent ?? AppTheme.brandPrimary,
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onEdit,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 12, 12),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: done
                                      ? Colors.grey.shade500
                                      : const Color(0xFF2B2D42),
                                ),
                              ),
                            ),
                            if (widget.onDelete != null)
                              IconButton(
                                onPressed: widget.onDelete,
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.grey.shade400,
                                  size: 18,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_hasGroup &&
                                widget.groupLabel != null &&
                                widget.groupLabel!.isNotEmpty)
                              _GroupChip(
                                label: widget.groupLabel!,
                                icon: groupIcon,
                                color: accent ?? AppTheme.brandPrimary,
                              )
                            else if (!_hasGroup)
                              _NeutralChip(
                                label: 'Sem grupo',
                                icon: Icons.checklist_rounded,
                              ),
                            if (hasRecurrence && task.recurrence != null)
                              _RecurrenceChip(
                                label: _recurrenceChipLabel(task.recurrence!),
                              ),
                            if (hasAssignees) _buildAssigneeStack(context),
                            if (hasLocation)
                              _MetaChip(
                                icon: Icons.location_on_rounded,
                                label: _locationReminderLabel(task),
                                color: Colors.blue,
                              ),
                            if (showDateBadgeInMeta &&
                                scheduleData != null)
                              _MetaChip(
                                icon: Icons.alarm_rounded,
                                label: scheduleData.label,
                                color: scheduleColor,
                              ),
                          ],
                        ),
                        if (widget.tagChips != null &&
                            widget.tagChips!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final tag in widget.tagChips!)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(tag.color)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Color(tag.color),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        tag.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(tag.color),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
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

  Widget _buildCheckboxHitArea(
    BuildContext context,
    bool done, {
    required Color fillColor,
  }) {
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
          child: Center(
            child: _buildCheckboxVisual(
              context,
              done,
              fillColor: fillColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssigneeStack(BuildContext context) {
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
                          border: Border.all(
                            color: AppTheme.cardSurface,
                            width: 2,
                          ),
                        ),
                        child: CustomAvatar(
                          radius: _assigneeRadius,
                          photoUrl: memberPhotoUrl(
                            visible[i],
                            map,
                            selfUid: widget.selfUid,
                            selfPhotoUrl: widget.selfPhotoUrl,
                          ),
                          displayName:
                              memberDisplayLabel(visible[i], map),
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxVisual(
    BuildContext context,
    bool done, {
    required Color fillColor,
  }) {
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
          color: done ? fillColor : Colors.grey.shade400,
          width: 1.5,
        ),
        color: done ? fillColor : Colors.transparent,
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _LateralBlock extends StatelessWidget {
  const _LateralBlock({
    required this.hasGroup,
    required this.hasSchedule,
    required this.accent,
    required this.groupIcon,
    this.scheduleLines,
    this.scheduleIsOverdue = false,
  });

  final bool hasGroup;
  final bool hasSchedule;
  final Color? accent;
  final IconData groupIcon;
  final String? scheduleLines;
  final bool scheduleIsOverdue;

  @override
  Widget build(BuildContext context) {
    if (!hasGroup) {
      return Container(
        width: _TaskCardState._lateralWidth,
        decoration: const BoxDecoration(
          color: _TaskCardState._neutralLateralBg,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(_TaskCardState._cardRadius),
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.checklist_rounded,
            size: 24,
            color: _TaskCardState._neutralIcon,
          ),
        ),
      );
    }

    final Color groupColor = accent ?? AppTheme.brandPrimary;
    final Color textColor = scheduleIsOverdue
        ? Theme.of(context).colorScheme.error
        : _darkenAccent(groupColor);

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        left: Radius.circular(_TaskCardState._cardRadius),
      ),
      child: SizedBox(
        width: _TaskCardState._lateralWidth,
        child: ColoredBox(
          color: groupColor.withValues(alpha: 0.15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -6,
                bottom: -8,
                child: Icon(
                  groupIcon,
                  size: 54,
                  color: groupColor.withValues(alpha: 0.18),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: hasSchedule && scheduleLines != null
                      ? Text(
                          scheduleLines!,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: textColor,
                          ),
                        )
                      : Icon(
                          groupIcon,
                          size: 23,
                          color: _darkenAccent(groupColor, 0.25),
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

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _darkenAccent(color, 0.2)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _darkenAccent(color, 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({required this.label});

  final String label;

  static const Color _purple = Color(0xFF7F77DD);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh_rounded,
            size: 13,
            color: _purple.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _purple.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeutralChip extends StatelessWidget {
  const _NeutralChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _TaskCardState._neutralIcon),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
