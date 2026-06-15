import '../data/models/group_model.dart';
import '../data/models/task_model.dart';
import 'task_day_visibility.dart';
import 'task_list_partition.dart';

bool countsTaskInHome(
  TaskModel task, {
  Map<String, GroupModel>? groupById,
}) {
  final gid = task.groupId?.trim();
  if (gid == null || gid.isEmpty) return true;
  if (groupById == null) return true;
  final g = groupById[gid];
  if (g == null) return true;
  return g.typeConfig.countsInHome;
}

Iterable<TaskModel> homeEligibleTasks(
  Iterable<TaskModel> allTasks, {
  Map<String, GroupModel>? groupById,
}) {
  return allTasks.where((t) => countsTaskInHome(t, groupById: groupById));
}

List<TaskModel> tasksVisibleOnHomeDay(
  Iterable<TaskModel> allTasks,
  DateTime day, {
  DateTime? now,
  Map<String, GroupModel>? groupById,
}) {
  final eligible = homeEligibleTasks(allTasks, groupById: groupById);
  return eligible.where((t) => taskVisibleOnDay(t, day, now: now)).toList();
}

List<TaskModel> activeTasksForDay(
  Iterable<TaskModel> allTasks,
  DateTime day, {
  DateTime? now,
  Map<String, GroupModel>? groupById,
}) {
  final dayTasks = tasksVisibleOnHomeDay(
    allTasks,
    day,
    now: now,
    groupById: groupById,
  );
  return partitionTasksByCompletionForCalendarDay(dayTasks, day).active;
}

int pendingTodayCount(
  Iterable<TaskModel> allTasks, {
  DateTime? now,
  Map<String, GroupModel>? groupById,
}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  return activeTasksForDay(
    allTasks,
    today,
    now: clock,
    groupById: groupById,
  ).length;
}

int pendingScheduledCount(
  Iterable<TaskModel> allTasks, {
  DateTime? now,
  Map<String, GroupModel>? groupById,
}) {
  final clock = now ?? DateTime.now();
  return homeEligibleTasks(allTasks, groupById: groupById)
      .where((t) => taskMatchesScheduledFilter(t, clock: clock))
      .where((t) => !t.isCompleted)
      .length;
}

int pendingAllCount(
  Iterable<TaskModel> allTasks, {
  Map<String, GroupModel>? groupById,
}) {
  return homeEligibleTasks(allTasks, groupById: groupById)
      .where((t) => !t.isCompleted)
      .length;
}
