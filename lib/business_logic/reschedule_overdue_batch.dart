import '../data/models/task_model.dart';
import 'overdue_occurrences.dart';
import 'task_occurrence_display.dart';

/// Linhas de atraso que podem ser reagendadas em lote (tarefas pontuais, não recorrentes).
List<OverdueOccurrenceRow> reschedulableOverdueRows(
  Iterable<TaskModel> tasks,
  DateTime now,
) {
  return collectOverdueOccurrenceRows(tasks, now)
      .where((r) => !isDatetimeRecurringTask(r.task))
      .toList();
}

/// Nova data de vencimento preservando hora quando existir.
DateTime dueDateRescheduledToDay(TaskModel task, DateTime targetDay) {
  final due = task.dueDate;
  if (due == null) {
    return DateTime(targetDay.year, targetDay.month, targetDay.day);
  }
  if (task.dueHasTime) {
    return DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
      due.hour,
      due.minute,
    );
  }
  return DateTime(targetDay.year, targetDay.month, targetDay.day);
}

TaskModel taskRescheduledToDay(TaskModel task, DateTime targetDay) {
  return task.copyWith(dueDate: dueDateRescheduledToDay(task, targetDay));
}
