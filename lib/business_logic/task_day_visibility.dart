import '../data/models/task_model.dart';
import 'recurrence_calculator.dart';

bool _sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isTodayAt(DateTime d, DateTime now) =>
    d.year == now.year && d.month == now.month && d.day == now.day;

bool _noGroup(TaskModel t) {
  final id = t.groupId?.trim();
  return id == null || id.isEmpty;
}

/// Inbox pessoal: sem data e fora de grupo; aparece em "Hoje" só no dia civil atual.
bool _personalInboxUndatedVisibleOnDay(
  TaskModel t,
  DateTime day, {
  required DateTime now,
}) {
  if (t.dueDate != null || !_noGroup(t)) return false;
  final today = DateTime(now.year, now.month, now.day);
  return _sameCalendarDay(day, today);
}

/// Tarefa com data visível no dia civil [day] (lista "Hoje" / timeline).
/// [now] só para testes; fora de testes usa o relógio do dispositivo.
bool taskVisibleOnDay(TaskModel t, DateTime day, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  if (_personalInboxUndatedVisibleOnDay(t, day, now: clock)) return true;
  if (t.dueDate == null) return false;
  if (t.reminderType == 'datetime' && t.recurrence != null) {
    final anchor = t.dueDate!;
    return RecurrenceCalculator.occursOnCalendarDay(
      anchorDate: anchor,
      rule: t.recurrence!,
      calendarDay: day,
      dueTimeHour: t.dueHasTime ? anchor.hour : null,
      dueTimeMinute: t.dueHasTime ? anchor.minute : null,
    );
  }
  return _sameCalendarDay(t.dueDate!, day);
}

/// Lista "Agendadas": pontuais fora de hoje; recorrentes datetime uma vez se ainda há ocorrência futura.
/// [clock] permite testes determinísticos; padrão `DateTime.now()`.
bool taskMatchesScheduledFilter(TaskModel t, {DateTime? clock}) {
  final now = clock ?? DateTime.now();
  if (t.dueDate == null) return false;
  if (t.reminderType == 'datetime' && t.recurrence != null) {
    final anchor = t.dueDate!;
    return RecurrenceCalculator.upcomingOccurrences(
      anchorDate: anchor,
      rule: t.recurrence!,
      from: now,
      dueTimeHour: t.dueHasTime ? anchor.hour : null,
      dueTimeMinute: t.dueHasTime ? anchor.minute : null,
      maxCount: 1,
    ).isNotEmpty;
  }
  return !_isTodayAt(t.dueDate!, now);
}
