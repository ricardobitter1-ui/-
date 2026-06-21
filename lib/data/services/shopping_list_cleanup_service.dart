import '../../business_logic/shopping_list_cleanup_plan.dart';
import '../../business_logic/voice_tag_resolver.dart';
import '../models/tag_model.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'voice/tag_assignment_llm_service.dart';
import 'voice_api_config.dart';

/// Planeia limpeza automática de lista de compras (tags + duplicados).
class ShoppingListCleanupService {
  ShoppingListCleanupService({
    TagAssignmentLlmService? tagService,
    Future<List<String?>> Function({
      required List<String> itemTitles,
      required List<TagModel> tags,
    })? assignTagsForTest,
  })  : _tagService = tagService ??
            (VoiceApiConfig.hasGroqKey || VoiceApiConfig.hasOpenRouterKey
                ? TagAssignmentLlmService()
                : null),
        _assignTagsForTest = assignTagsForTest;

  final TagAssignmentLlmService? _tagService;
  final Future<List<String?>> Function({
    required List<String> itemTitles,
    required List<TagModel> tags,
  })? _assignTagsForTest;

  Future<ShoppingListCleanupPlan> buildPlan({
    required List<TaskModel> tasks,
    required List<TagModel> tags,
  }) async {
    final changes = <ShoppingListCleanupChange>[];
    final updatesById = <String, TaskModel>{};
    final deleteTaskIds = <String>{};

    final liveTasks = tasks.where((t) => !deleteTaskIds.contains(t.id)).toList();
    _planDuplicateHandling(
      tasks: liveTasks,
      changes: changes,
      updatesById: updatesById,
      deleteTaskIds: deleteTaskIds,
    );

    final survivors = tasks
        .where((t) => !deleteTaskIds.contains(t.id))
        .map((t) => updatesById[t.id] ?? t)
        .toList();

    await _planTagAssignments(
      tasks: survivors,
      tags: tags,
      changes: changes,
      updatesById: updatesById,
    );

    return ShoppingListCleanupPlan(
      changes: changes,
      updatesById: updatesById,
      deleteTaskIds: deleteTaskIds,
    );
  }

  void _planDuplicateHandling({
    required List<TaskModel> tasks,
    required List<ShoppingListCleanupChange> changes,
    required Map<String, TaskModel> updatesById,
    required Set<String> deleteTaskIds,
  }) {
    final byKey = <String, List<TaskModel>>{};
    for (final t in tasks) {
      final key = t.titleSearchKey;
      if (key.isEmpty) continue;
      byKey.putIfAbsent(key, () => []).add(t);
    }

    for (final group in byKey.values) {
      if (group.length <= 1) continue;

      final sorted = List<TaskModel>.from(group)
        ..sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return a.id.compareTo(b.id);
        });
      final keeper = sorted.first;

      if (keeper.isCompleted) {
        final reopened = keeper.copyWith(
          isCompleted: false,
          completedOccurrenceDateKeys: keeper.recurrence != null
              ? <String>[]
              : keeper.completedOccurrenceDateKeys,
        );
        updatesById[keeper.id] = reopened;
        changes.add(
          ShoppingListCleanupChange(
            type: ShoppingListCleanupChangeType.duplicateReopened,
            task: reopened,
            relatedTask: keeper,
          ),
        );
      }

      for (var i = 1; i < sorted.length; i++) {
        final dup = sorted[i];
        deleteTaskIds.add(dup.id);
        changes.add(
          ShoppingListCleanupChange(
            type: ShoppingListCleanupChangeType.duplicateRemoved,
            task: dup,
            relatedTask: updatesById[keeper.id] ?? keeper,
          ),
        );
      }
    }
  }

  Future<void> _planTagAssignments({
    required List<TaskModel> tasks,
    required List<TagModel> tags,
    required List<ShoppingListCleanupChange> changes,
    required Map<String, TaskModel> updatesById,
  }) async {
    if (tags.isEmpty) return;

    final untagged = tasks
        .where((t) => !taskHasResolvedTag(t, tags))
        .toList(growable: false);
    if (untagged.isEmpty) return;

    final assigned = await _assignTags(
      itemTitles: untagged.map((t) => t.title).toList(),
      tags: tags,
    );
    if (assigned == null) return;

    for (var i = 0; i < untagged.length; i++) {
      final tagName = i < assigned.length ? assigned[i] : null;
      final tagId = resolveTagIdByName(tagName, tags);
      if (tagId == null) continue;

      final base = updatesById[untagged[i].id] ?? untagged[i];
      if (base.tagIds.contains(tagId)) continue;

      final updated = base.copyWith(tagIds: [tagId]);
      updatesById[base.id] = updated;
      changes.add(
        ShoppingListCleanupChange(
          type: ShoppingListCleanupChangeType.tagAssigned,
          task: updated,
          previousTagName: tagNameForTask(base, tags),
          newTagName: tags.firstWhere((t) => t.id == tagId).name,
        ),
      );
    }
  }

  Future<List<String?>?> _assignTags({
    required List<String> itemTitles,
    required List<TagModel> tags,
  }) async {
    if (_assignTagsForTest != null) {
      return _assignTagsForTest(
        itemTitles: itemTitles,
        tags: tags,
      );
    }
    if (_tagService == null) return null;
    return _tagService.assignShoppingTags(
      itemTitles: itemTitles,
      tags: tags,
    );
  }

  void dispose() => _tagService?.close();
}

Future<void> applyShoppingListCleanupPlan({
  required ShoppingListCleanupPlan plan,
  required FirebaseService firebase,
  required NotificationService notification,
}) async {
  for (final entry in plan.updatesById.entries) {
    await firebase.updateTask(entry.value);
    if (entry.value.reminderType == 'datetime') {
      await notification.syncTaskDatetimeReminders(entry.value);
    }
  }
  for (final id in plan.deleteTaskIds) {
    await firebase.deleteTask(id);
    await notification.cancelAllTaskReminderSlots(id);
  }
}
