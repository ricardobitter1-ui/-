import '../data/models/task_model.dart';
import 'task_occurrence_display.dart';

/// Sem hora agendada primeiro; com hora, da mais cedo para a mais tarde.
int compareTasksByScheduleOrder(
  TaskModel a,
  TaskModel b, {
  DateTime? calendarDay,
}) {
  final aDue = _effectiveDue(a, calendarDay);
  final bDue = _effectiveDue(b, calendarDay);

  final dayCmp = _dayStamp(aDue).compareTo(_dayStamp(bDue));
  if (dayCmp != 0) return dayCmp;

  final aHasTime = _hasScheduledTime(a, aDue);
  final bHasTime = _hasScheduledTime(b, bDue);
  if (aHasTime != bHasTime) return aHasTime ? 1 : -1;

  if (!aHasTime) return 0;

  return _minutesOfDay(aDue!).compareTo(_minutesOfDay(bDue!));
}

void sortTasksByScheduleOrder(
  List<TaskModel> tasks, {
  DateTime? calendarDay,
}) {
  tasks.sort(
    (a, b) => compareTasksByScheduleOrder(
      a,
      b,
      calendarDay: calendarDay,
    ),
  );
}

DateTime? _effectiveDue(TaskModel task, DateTime? calendarDay) {
  if (calendarDay != null) {
    return displayDueForTaskOnCalendarDay(task, calendarDay);
  }
  return task.dueDate;
}

bool _hasScheduledTime(TaskModel task, DateTime? due) =>
    task.dueHasTime && due != null;

int _dayStamp(DateTime? due) {
  if (due == null) return 0;
  return due.year * 10000 + due.month * 100 + due.day;
}

int _minutesOfDay(DateTime due) => due.hour * 60 + due.minute;
