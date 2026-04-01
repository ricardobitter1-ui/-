import '../data/models/task_model.dart';
import 'task_occurrence_display.dart';

/// Separa [tasks] em pendentes e concluídas, **preservando a ordem** do stream.
({List<TaskModel> active, List<TaskModel> completed})
    partitionTasksByCompletion(List<TaskModel> tasks) {
  final active = <TaskModel>[];
  final completed = <TaskModel>[];
  for (final t in tasks) {
    if (t.isCompleted) {
      completed.add(t);
    } else {
      active.add(t);
    }
  }
  return (active: active, completed: completed);
}

/// Como [partitionTasksByCompletion], mas para tarefas recorrentes datetime usa conclusão por dia civil.
({List<TaskModel> active, List<TaskModel> completed})
    partitionTasksByCompletionForCalendarDay(
  List<TaskModel> tasks,
  DateTime day,
) {
  final active = <TaskModel>[];
  final completed = <TaskModel>[];
  for (final t in tasks) {
    if (isOccurrenceCompletedOnCalendarDay(t, day)) {
      completed.add(t);
    } else {
      active.add(t);
    }
  }
  return (active: active, completed: completed);
}
