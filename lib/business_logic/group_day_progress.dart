import '../data/models/task_model.dart';

/// Progresso de tarefas de um grupo restrito a um único dia civil (`dueDate`).
class GroupDayProgress {
  final int total;
  final int completed;

  const GroupDayProgress({required this.total, required this.completed});

  double get ratio => total > 0 ? completed / total : 0.0;
}

/// Considera apenas tarefas com [TaskModel.dueDate] no dia [day] e [TaskModel.groupId] não vazio.
Map<String, GroupDayProgress> computeGroupProgressForDay(
  Iterable<TaskModel> tasks,
  DateTime day,
) {
  final y = day.year;
  final m = day.month;
  final d = day.day;
  final map = <String, GroupDayProgress>{};

  for (final t in tasks) {
    final due = t.dueDate;
    if (due == null) continue;
    if (due.year != y || due.month != m || due.day != d) continue;
    final gid = t.groupId;
    if (gid == null || gid.isEmpty) continue;

    final prev = map[gid] ?? const GroupDayProgress(total: 0, completed: 0);
    map[gid] = GroupDayProgress(
      total: prev.total + 1,
      completed: prev.completed + (t.isCompleted ? 1 : 0),
    );
  }
  return map;
}
