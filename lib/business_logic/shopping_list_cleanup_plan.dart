import '../data/models/tag_model.dart';
import '../data/models/task_model.dart';

enum ShoppingListCleanupChangeType {
  tagAssigned,
  duplicateRemoved,
  duplicateReopened,
}

class ShoppingListCleanupChange {
  final ShoppingListCleanupChangeType type;
  final TaskModel task;
  final TaskModel? relatedTask;
  final String? previousTagName;
  final String? newTagName;

  const ShoppingListCleanupChange({
    required this.type,
    required this.task,
    this.relatedTask,
    this.previousTagName,
    this.newTagName,
  });
}

class ShoppingListCleanupPlan {
  final List<ShoppingListCleanupChange> changes;
  final Map<String, TaskModel> updatesById;
  final Set<String> deleteTaskIds;

  const ShoppingListCleanupPlan({
    required this.changes,
    required this.updatesById,
    required this.deleteTaskIds,
  });

  bool get isEmpty =>
      changes.isEmpty && updatesById.isEmpty && deleteTaskIds.isEmpty;
}

String? tagNameForTask(TaskModel task, List<TagModel> tags) {
  if (task.tagIds.isEmpty) return null;
  final byId = {for (final t in tags) t.id: t};
  for (final id in task.tagIds) {
    final tag = byId[id];
    if (tag != null) return tag.name;
  }
  return null;
}

bool taskHasResolvedTag(TaskModel task, List<TagModel> tags) {
  if (task.tagIds.isEmpty) return false;
  final byId = {for (final t in tags) t.id: t};
  return task.tagIds.any(byId.containsKey);
}
