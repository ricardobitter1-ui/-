import '../data/models/task_model.dart';

class GroupProgress {
  final int total;
  final int completed;

  const GroupProgress({required this.total, required this.completed});

  double get ratio => total > 0 ? completed / total : 0.0;
}

/// Progresso agregado de cada grupo (todas as tarefas, independente de data).
Map<String, GroupProgress> computeGroupProgress(Iterable<TaskModel> tasks) {
  final map = <String, GroupProgress>{};

  for (final t in tasks) {
    final gid = t.groupId;
    if (gid == null || gid.isEmpty) continue;

    final prev = map[gid] ?? const GroupProgress(total: 0, completed: 0);
    map[gid] = GroupProgress(
      total: prev.total + 1,
      completed: prev.completed + (t.isCompleted ? 1 : 0),
    );
  }
  return map;
}

/// Progresso restrito a um único dia civil.
Map<String, GroupProgress> computeGroupProgressForDay(
  Iterable<TaskModel> tasks,
  DateTime day,
) {
  final y = day.year;
  final m = day.month;
  final d = day.day;
  final map = <String, GroupProgress>{};

  for (final t in tasks) {
    final due = t.dueDate;
    if (due == null) continue;
    if (due.year != y || due.month != m || due.day != d) continue;
    final gid = t.groupId;
    if (gid == null || gid.isEmpty) continue;

    final prev = map[gid] ?? const GroupProgress(total: 0, completed: 0);
    map[gid] = GroupProgress(
      total: prev.total + 1,
      completed: prev.completed + (t.isCompleted ? 1 : 0),
    );
  }
  return map;
}
