import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../constants/geofence_constants.dart';
import '../../data/models/task_recurrence.dart';
import '../../data/services/location_service.dart';
import '../screens/location_picker_screen.dart';
import '../screens/task_recurrence_screen.dart';
import '../theme/app_theme.dart';

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
  return showDialog<TaskScheduleDialogResult>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Theme(
      data: AppTheme.lightTheme,
      child: TaskScheduleDialog(initial: initial, parentRef: ref),
    ),
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

  DateTime _calendarInitialDate() {
    final sel = _selectedDate ?? DateTime.now();
    if (sel.year == _displayMonth.year && sel.month == _displayMonth.month) {
      if (sel.isBefore(_firstCal)) return _firstCal;
      if (sel.isAfter(_lastCal)) return _lastCal;
      return sel;
    }
    final firstOfMonth = DateTime(_displayMonth.year, _displayMonth.month, 1);
    if (firstOfMonth.isBefore(_firstCal)) return _firstCal;
    if (firstOfMonth.isAfter(_lastCal)) return _lastCal;
    return firstOfMonth;
  }

  void _shiftMonth(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta, 1);
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

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) =>
          Theme(data: AppTheme.lightTheme, child: child!),
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

  Widget _locationDetail() {
    final theme = Theme.of(context);
    final hasPoint = _locationLat != null && _locationLng != null;
    final summary = hasPoint
        ? '${_locationLat!.toStringAsFixed(5)}, ${_locationLng!.toStringAsFixed(5)} · ${_locationRadiusMeters.round()} m'
        : 'Nenhum ponto escolhido';
    final labelLine =
        (_locationLabel != null && _locationLabel!.isNotEmpty) ? _locationLabel! : null;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.brandPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Geofence (Android)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.brandPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'O app avisa ao entrar ou sair da área. '
            'No máximo $kMaxRegisteredGeofences lembretes ativos por dispositivo.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _canGoPrev ? () => _shiftMonth(-1) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _monthTitle(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2B2D42),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoNext ? () => _shiftMonth(1) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CalendarDatePicker(
                      key: ValueKey(
                        '${_displayMonth.year}-${_displayMonth.month}',
                      ),
                      initialDate: _calendarInitialDate(),
                      firstDate: _firstCal,
                      lastDate: _lastCal,
                      onDateChanged: (d) {
                        setState(() {
                          _selectedDate = d;
                          _reminderType = 'datetime';
                          _locationLat = null;
                          _locationLng = null;
                          _locationLabel = null;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.access_time_rounded),
                      title: const Text('Definir hora'),
                      subtitle: Text(
                        _dueHasTime && _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Opcional — sem hora',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6C757D),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_dueHasTime)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedTime = null;
                                  _dueHasTime = false;
                                });
                              },
                              child: const Text('Remover'),
                            ),
                          TextButton(
                            onPressed: _pickTime,
                            child: const Text('Definir'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.repeat_rounded),
                      title: const Text('Repetição'),
                      subtitle: Text(
                        taskRecurrenceSummary(_recurrence),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6C757D),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _openRecurrence,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: const Text('Localização'),
                      subtitle: Text(
                        _locationSubtitle(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6C757D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _openMap,
                    ),
                    if (_reminderType == 'location') _locationDetail(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.notifications_off_outlined, size: 20),
                        label: const Text('Limpar agendamento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brandPrimary,
                    ),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: _onConfirm,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.brandPrimary,
                    ),
                    child: const Text('Concluído'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
