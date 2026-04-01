import '../data/models/task_model.dart';
import '../utils/calendar_day_key.dart';
import 'recurrence_calculator.dart';

bool isDatetimeRecurringTask(TaskModel t) =>
    t.reminderType == 'datetime' &&
    t.recurrence != null &&
    t.dueDate != null;

/// Conclusão efetiva no dia civil [day] (lista Hoje / grupo “hoje”).
bool isOccurrenceCompletedOnCalendarDay(TaskModel t, DateTime day) {
  if (!isDatetimeRecurringTask(t)) return t.isCompleted;
  return t.completedOccurrenceDateKeys.contains(localCalendarDayKey(day));
}

/// Instantâneo da ocorrência em [calendarDay], ou null.
DateTime? occurrenceInstantOnCalendarDayForTask(TaskModel t, DateTime calendarDay) {
  if (!isDatetimeRecurringTask(t)) return null;
  final anchor = t.dueDate!;
  return RecurrenceCalculator.occurrenceInstantOnCalendarDay(
    anchorDate: anchor,
    rule: t.recurrence!,
    calendarDay: calendarDay,
    dueTimeHour: t.dueHasTime ? anchor.hour : null,
    dueTimeMinute: t.dueHasTime ? anchor.minute : null,
  );
}

/// Data/hora a mostrar no badge para a lista no dia [calendarDay].
DateTime? displayDueForTaskOnCalendarDay(TaskModel t, DateTime calendarDay) {
  if (!isDatetimeRecurringTask(t)) return t.dueDate;
  return occurrenceInstantOnCalendarDayForTask(t, calendarDay) ?? t.dueDate;
}
