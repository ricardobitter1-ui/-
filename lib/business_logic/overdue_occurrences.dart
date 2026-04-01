import '../data/models/task_model.dart';
import '../utils/scheduled_badge_label.dart';
import 'recurrence_calculator.dart';
import 'task_occurrence_display.dart';
import '../utils/calendar_day_key.dart';

/// Uma linha na lista Atrasadas: tarefa + dia civil da ocorrência em atraso.
class OverdueOccurrenceRow {
  final TaskModel task;
  final DateTime day;

  const OverdueOccurrenceRow({required this.task, required this.day});
}

DateTime _rowOverdueInstant(OverdueOccurrenceRow r) {
  if (!isDatetimeRecurringTask(r.task)) return r.task.dueDate!;
  return occurrenceInstantOnCalendarDayForTask(r.task, r.day) ??
      r.task.dueDate!;
}

/// Ocorrências com instante antes de [now] e não marcadas como concluídas para esse dia.
List<OverdueOccurrenceRow> collectOverdueOccurrenceRows(
  Iterable<TaskModel> tasks,
  DateTime now, {
  int maxDaysBack = 400,
}) {
  final todayStart = DateTime(now.year, now.month, now.day);
  final out = <OverdueOccurrenceRow>[];

  for (final t in tasks) {
    if (t.dueDate == null) continue;

    if (!isDatetimeRecurringTask(t)) {
      if (isDueDateTimePast(t.dueDate!, now) && !t.isCompleted) {
        final d = t.dueDate!;
        out.add(OverdueOccurrenceRow(
          task: t,
          day: DateTime(d.year, d.month, d.day),
        ));
      }
      continue;
    }

    final anchor = t.dueDate!;
    final rule = t.recurrence!;
    final dh = t.dueHasTime ? anchor.hour : null;
    final dm = t.dueHasTime ? anchor.minute : null;

    for (var i = 0; i < maxDaysBack; i++) {
      final d = todayStart.subtract(Duration(days: i));
      if (!RecurrenceCalculator.occursOnCalendarDay(
        anchorDate: anchor,
        rule: rule,
        calendarDay: d,
        dueTimeHour: dh,
        dueTimeMinute: dm,
      )) {
        continue;
      }
      final inst = RecurrenceCalculator.occurrenceInstantOnCalendarDay(
        anchorDate: anchor,
        rule: rule,
        calendarDay: d,
        dueTimeHour: dh,
        dueTimeMinute: dm,
      );
      if (inst == null || !inst.isBefore(now)) continue;
      final key = localCalendarDayKey(d);
      if (t.completedOccurrenceDateKeys.contains(key)) continue;
      out.add(OverdueOccurrenceRow(task: t, day: d));
    }
  }

  out.sort((a, b) => _rowOverdueInstant(a).compareTo(_rowOverdueInstant(b)));
  return out;
}
