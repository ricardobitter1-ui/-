import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/geofence_constants.dart';
import '../../data/models/task_recurrence.dart';
import '../../data/services/location_service.dart';
import '../screens/location_picker_screen.dart';
import '../screens/task_recurrence_screen.dart';
import '../theme/eximium_colors.dart';
import '../theme/eximium_effects.dart';
import '../theme/eximium_spacing.dart';
import '../theme/eximium_typography.dart';
import 'eximium/ex_button.dart';

/// Estado de agendamento devolvido pelo popup (espelha o que o [TaskFormModal] persiste).
class TaskScheduleDialogResult {
  final String reminderType;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final bool dueHasTime;
  final TaskRecurrenceRule? recurrence;
  final String locationTrigger;
  final double? locationLat;
  final double? locationLng;
  final double locationRadiusMeters;
  final String? locationLabel;

  const TaskScheduleDialogResult({
    required this.reminderType,
    this.selectedDate,
    this.selectedTime,
    this.dueHasTime = false,
    this.recurrence,
    this.locationTrigger = 'arrival',
    this.locationLat,
    this.locationLng,
    this.locationRadiusMeters = kDefaultGeofenceRadiusMeters,
    this.locationLabel,
  });
}

String taskRecurrenceSummary(TaskRecurrenceRule? r) {
  if (r == null) return 'Não repetir';
  final u = switch (r.unit) {
    RecurrenceUnit.day => r.interval == 1 ? 'dia' : '${r.interval} dias',
    RecurrenceUnit.week => r.interval == 1 ? 'semana' : '${r.interval} semanas',
    RecurrenceUnit.month => r.interval == 1 ? 'mês' : '${r.interval} meses',
    RecurrenceUnit.year => r.interval == 1 ? 'ano' : '${r.interval} anos',
  };
  return 'Cada $u';
}

Future<TaskScheduleDialogResult?> showTaskScheduleDialog(
  BuildContext context,
  WidgetRef ref, {
  required TaskScheduleDialogResult initial,
}) {
  return showModalBottomSheet<TaskScheduleDialogResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => TaskScheduleDialog(initial: initial, parentRef: ref),
  );
}

class TaskScheduleDialog extends StatefulWidget {
  final TaskScheduleDialogResult initial;
  final WidgetRef parentRef;

  const TaskScheduleDialog({
    super.key,
    required this.initial,
    required this.parentRef,
  });

  @override
  State<TaskScheduleDialog> createState() => _TaskScheduleDialogState();
}

class _TaskScheduleDialogState extends State<TaskScheduleDialog> {
  static const int _rangeYearsBack = 365 * 5;
  static const List<String> _weekdayLabels = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
    'DOM',
  ];

  late DateTime _firstCal;
  late DateTime _lastCal;

  late String _reminderType;
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  late bool _dueHasTime;
  late TaskRecurrenceRule? _recurrence;
  late String _locationTrigger;
  late double? _locationLat;
  late double? _locationLng;
  late double _locationRadiusMeters;
  late String? _locationLabel;

  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _reminderType = i.reminderType;
    _selectedDate = i.selectedDate;
    _selectedTime = i.selectedTime;
    _dueHasTime = i.dueHasTime;
    _recurrence = i.recurrence;
    _locationTrigger = i.locationTrigger;
    _locationLat = i.locationLat;
    _locationLng = i.locationLng;
    _locationRadiusMeters = i.locationRadiusMeters;
    _locationLabel = i.locationLabel;

    final now = DateTime.now();
    _firstCal = now.subtract(const Duration(days: _rangeYearsBack));
    _lastCal = DateTime(2035);

    final anchor = _selectedDate ?? now;
    _displayMonth = DateTime(anchor.year, anchor.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _displayMonth =
          DateTime(_displayMonth.year, _displayMonth.month + delta, 1);
    });
  }

  bool get _canGoPrev {
    final prev = DateTime(_displayMonth.year, _displayMonth.month - 1, 1);
    final minM = DateTime(_firstCal.year, _firstCal.month, 1);
    return !prev.isBefore(minM);
  }

  bool get _canGoNext {
    final next = DateTime(_displayMonth.year, _displayMonth.month + 1, 1);
    final maxM = DateTime(_lastCal.year, _lastCal.month, 1);
    return !next.isAfter(maxM);
  }

  String _monthTitle() {
    final d = DateTime(_displayMonth.year, _displayMonth.month, 1);
    return DateFormat.yMMMM('pt_BR').format(d);
  }

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  List<List<int?>> _buildWeeks() {
    final first = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final daysInMonth = _daysInMonth(_displayMonth);
    final offset = first.weekday - 1;
    final cells = <int?>[];
    for (var i = 0; i < offset; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(d);
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <List<int?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    return weeks;
  }

  bool _isDaySelectable(int day) {
    final d = DateTime(_displayMonth.year, _displayMonth.month, day);
    return !d.isBefore(_firstCal) && !d.isAfter(_lastCal);
  }

  bool _isDaySelected(int day) {
    final sel = _selectedDate;
    if (sel == null) return false;
    return sel.year == _displayMonth.year &&
        sel.month == _displayMonth.month &&
        sel.day == day;
  }

  void _onDayTap(int day) {
    if (!_isDaySelectable(day)) return;
    setState(() {
      _selectedDate = DateTime(_displayMonth.year, _displayMonth.month, day);
      _reminderType = 'datetime';
      _locationLat = null;
      _locationLng = null;
      _locationLabel = null;
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (t != null && mounted) {
      setState(() {
        _selectedDate ??= DateTime.now();
        _selectedTime = t;
        _dueHasTime = true;
        _reminderType = 'datetime';
        _locationLat = null;
        _locationLng = null;
        _locationLabel = null;
      });
    }
  }

  Future<void> _openRecurrence() async {
    final start = _selectedDate ?? DateTime.now();
    final result = await Navigator.of(context).push<TaskRecurrenceRule?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => TaskRecurrenceScreen(
          initialRule: _recurrence,
          startDate: start,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _recurrence = result;
      if (result != null) {
        _selectedDate ??= DateTime.now();
        _reminderType = 'datetime';
        _locationLat = null;
        _locationLng = null;
        _locationLabel = null;
      }
    });
  }

  Future<void> _openMap() async {
    final loc = widget.parentRef.read(locationServiceProvider);
    final ok = await loc.ensureWhenInUseLocationPermission();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permita acesso à localização para marcar o ponto no mapa.',
          ),
        ),
      );
      return;
    }
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationPickerScreen(
          initialLatitude: _locationLat,
          initialLongitude: _locationLng,
          initialRadiusMeters: _locationRadiusMeters,
          initialLabel: _locationLabel,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _locationLat = result.latitude;
        _locationLng = result.longitude;
        _locationRadiusMeters = result.radiusMeters;
        _locationLabel = result.locationLabel;
        _reminderType = 'location';
        _recurrence = null;
        _dueHasTime = false;
        _selectedTime = null;
      });
    }
  }

  void _clearAll() {
    setState(() {
      _reminderType = 'none';
      _selectedDate = null;
      _selectedTime = null;
      _dueHasTime = false;
      _recurrence = null;
      _locationLat = null;
      _locationLng = null;
      _locationLabel = null;
      _locationTrigger = 'arrival';
      _displayMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    });
  }

  TaskScheduleDialogResult _buildResult() {
    return TaskScheduleDialogResult(
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
    );
  }

  void _onConfirm() {
    if (_reminderType == 'location') {
      if (_locationLat == null || _locationLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escolha o local no mapa antes de concluir.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }
    if (_reminderType == 'datetime') {
      _selectedDate ??= DateTime.now();
    }
    Navigator.of(context).pop(_buildResult());
  }

  /// Resumo curto do agendamento atual (chip verde no topo).
  String? _scheduleSummary() {
    if (_reminderType == 'location') {
      if (_locationLabel != null && _locationLabel!.trim().isNotEmpty) {
        return _locationLabel!.trim();
      }
      if (_locationLat != null && _locationLng != null) {
        return 'Local · ${_locationRadiusMeters.round()} m';
      }
      return null;
    }
    if (_reminderType == 'datetime' && _selectedDate != null) {
      final parts = <String>[];
      parts.add(DateFormat('EEE, d MMM', 'pt_BR').format(_selectedDate!));
      if (_dueHasTime && _selectedTime != null) {
        parts.add(_selectedTime!.format(context));
      }
      if (_recurrence != null) {
        parts.add(taskRecurrenceSummary(_recurrence));
      }
      return parts.join(' · ');
    }
    return null;
  }

  Widget _locationDetail() {
    final c = context.ex;
    final theme = Theme.of(context);
    final hasPoint = _locationLat != null && _locationLng != null;
    final summary = hasPoint
        ? '${_locationLat!.toStringAsFixed(5)}, ${_locationLng!.toStringAsFixed(5)} · ${_locationRadiusMeters.round()} m'
        : 'Nenhum ponto escolhido';
    final labelLine =
        (_locationLabel != null && _locationLabel!.isNotEmpty)
            ? _locationLabel!
            : null;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: ExSpace.s3),
      decoration: BoxDecoration(
        color: ExColors.brandGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(ExRadius.md),
        border: Border.all(color: c.borderAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Geofence (Android)', style: ExText.h3(c.textAccent)),
          const SizedBox(height: 6),
          Text(
            'O app avisa ao entrar ou sair da área. '
            'No máximo $kMaxRegisteredGeofences lembretes ativos por dispositivo.',
            style: theme.textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Ao chegar'),
                selected: _locationTrigger == 'arrival',
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (val) {
                  if (val) setState(() => _locationTrigger = 'arrival');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Ao sair'),
                selected: _locationTrigger == 'departure',
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (val) {
                  if (val) setState(() => _locationTrigger = 'departure');
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (labelLine != null) ...[
            const SizedBox(height: 4),
            Text(labelLine, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _locationSubtitle() {
    if (_locationLat != null &&
        _locationLng != null &&
        _locationLabel != null &&
        _locationLabel!.trim().isNotEmpty) {
      return _locationLabel!.trim();
    }
    if (_locationLat != null && _locationLng != null) {
      return '${_locationLat!.toStringAsFixed(4)}, ${_locationLng!.toStringAsFixed(4)}';
    }
    return 'Toque para escolher no mapa';
  }

  Widget _buildHandle(ExColors c) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: c.surface3,
          borderRadius: BorderRadius.circular(ExRadius.pill),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required ExColors c,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: c.surface2,
      shape: CircleBorder(side: BorderSide(color: c.border)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? c.textMuted : c.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(ExColors c) {
    final weeks = _buildWeeks();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildCircleIconButton(
              c: c,
              icon: Icons.chevron_left_rounded,
              onPressed: _canGoPrev ? () => _shiftMonth(-1) : null,
            ),
            Expanded(
              child: Text(
                _monthTitle(),
                textAlign: TextAlign.center,
                style: ExText.h3(c.textPrimary),
              ),
            ),
            _buildCircleIconButton(
              c: c,
              icon: Icons.chevron_right_rounded,
              onPressed: _canGoNext ? () => _shiftMonth(1) : null,
            ),
          ],
        ),
        const SizedBox(height: ExSpace.s3),
        Row(
          children: _weekdayLabels
              .map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: ExText.label(c.textMuted),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: ExSpace.s2),
        ...weeks.map((week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: week.map((day) => Expanded(child: _buildDayCell(c, day))).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDayCell(ExColors c, int? day) {
    if (day == null) {
      return const SizedBox(height: 36);
    }

    final date = DateTime(_displayMonth.year, _displayMonth.month, day);
    final selectable = _isDaySelectable(day);
    final selected = _isDaySelected(day);
    final isSunday = date.weekday == DateTime.sunday;

    Color textColor;
    if (selected) {
      textColor = ExColors.onBrandGreen;
    } else if (!selectable) {
      textColor = c.textMuted.withValues(alpha: 0.5);
    } else if (isSunday) {
      textColor = c.textMuted;
    } else {
      textColor = c.textSecondary;
    }

    Widget dayChild = Text(
      '$day',
      style: ExText.bodyLg(textColor).copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        fontSize: 14,
      ),
    );

    if (selected) {
      dayChild = DecoratedBox(
        decoration: BoxDecoration(
          color: ExColors.brandGreen,
          shape: BoxShape.circle,
          boxShadow: ExEffects.glowMd,
        ),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(child: dayChild),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: Center(
        child: selectable
            ? InkWell(
                onTap: () => _onDayTap(day),
                customBorder: const CircleBorder(),
                child: dayChild,
              )
            : dayChild,
      ),
    );
  }

  Widget _buildIconTile({
    required Color bg,
    required Color fg,
    required IconData icon,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: fg),
    );
  }

  Widget _buildGroupedDivider(ExColors c) {
    return Divider(
      height: 1,
      thickness: 1,
      color: c.border,
      indent: 60,
    );
  }

  Widget _buildGroupedOptions(ExColors c) {
    final timeValue = _dueHasTime && _selectedTime != null
        ? _selectedTime!.format(context)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              child: Row(
                children: [
                  _buildIconTile(
                    bg: ExColors.brandGreen.withValues(alpha: 0.14),
                    fg: c.textAccent,
                    icon: Icons.access_time_rounded,
                  ),
                  const SizedBox(width: ExSpace.s3),
                  Expanded(
                    child: Text('Hora', style: ExText.h3(c.textPrimary)),
                  ),
                  if (timeValue != null) ...[
                    Text(
                      timeValue,
                      style: ExText.mono(size: 14, color: c.textPrimary),
                    ),
                    const SizedBox(width: ExSpace.s1),
                    _buildClearTimeButton(c),
                  ] else
                    Text(
                      'Opcional — sem hora',
                      style: ExText.body(c.textSecondary),
                    ),
                ],
              ),
            ),
          ),
          _buildGroupedDivider(c),
          InkWell(
            onTap: _openRecurrence,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              child: Row(
                children: [
                  _buildIconTile(
                    bg: ExColors.lavender.withValues(alpha: 0.14),
                    fg: ExColors.lavender,
                    icon: Icons.repeat_rounded,
                  ),
                  const SizedBox(width: ExSpace.s3),
                  Expanded(
                    child: Text('Repetição', style: ExText.h3(c.textPrimary)),
                  ),
                  Text(
                    taskRecurrenceSummary(_recurrence),
                    style: ExText.body(c.textSecondary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 18),
                ],
              ),
            ),
          ),
          _buildGroupedDivider(c),
          InkWell(
            onTap: _openMap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              child: Row(
                children: [
                  _buildIconTile(
                    bg: c.surface3,
                    fg: c.textSecondary,
                    icon: Icons.place_outlined,
                  ),
                  const SizedBox(width: ExSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Localização', style: ExText.h3(c.textPrimary)),
                        const SizedBox(height: 1),
                        Text(
                          _locationSubtitle(),
                          style: ExText.small(c.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearTimeButton(ExColors c) {
    return Material(
      color: c.surface3,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTime = null;
            _dueHasTime = false;
          });
        },
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(Icons.close_rounded, size: 13, color: c.textSecondary),
        ),
      ),
    );
  }

  Widget _buildSummaryChip(ExColors c, String summary) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: ExColors.brandGreen.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(ExRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 15, color: c.textAccent),
          const SizedBox(width: ExSpace.s2),
          Flexible(
            child: Text(
              summary,
              overflow: TextOverflow.ellipsis,
              style: ExText.mono(size: 13, color: c.textAccent)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ex;
    final summary = _scheduleSummary();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ExRadius.xl),
        ),
        boxShadow: c.shadowFloat,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(ExSpace.s5, ExSpace.s3, ExSpace.s5, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHandle(c),
                const SizedBox(height: ExSpace.s4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Agendar lembrete',
                        style: ExText.h2(c.textPrimary),
                      ),
                    ),
                    _buildCircleIconButton(
                      c: c,
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (summary != null) ...[
                  const SizedBox(height: ExSpace.s4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildSummaryChip(c, summary),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                ExSpace.s5,
                ExSpace.s4,
                ExSpace.s5,
                ExSpace.s2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMonthCalendar(c),
                  const SizedBox(height: ExSpace.s4),
                  _buildGroupedOptions(c),
                  if (_reminderType == 'location') _locationDetail(),
                  const SizedBox(height: ExSpace.s3),
                  ExButton(
                    label: 'Limpar agendamento',
                    icon: Icons.notifications_off_outlined,
                    variant: ExButtonVariant.danger,
                    expand: true,
                    onPressed: _clearAll,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: c.border),
          Padding(
            padding: EdgeInsets.fromLTRB(
              ExSpace.s5,
              ExSpace.s3,
              ExSpace.s5,
              ExSpace.s4 + bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ExButton(
                    label: 'Cancelar',
                    variant: ExButtonVariant.secondary,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: ExSpace.s3),
                Expanded(
                  child: ExButton(
                    label: 'Concluído',
                    variant: ExButtonVariant.primary,
                    expand: true,
                    onPressed: _onConfirm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
