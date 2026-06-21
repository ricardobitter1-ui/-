import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/shopping_list_cleanup_plan.dart';
import 'package:todo_app/data/models/tag_model.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/data/services/shopping_list_cleanup_service.dart';
import 'package:todo_app/utils/title_search_key.dart';

void main() {
  group('ShoppingListCleanupService.buildPlan', () {
    test('remove duplicados e reativa concluído', () async {
      final service = ShoppingListCleanupService();
      final tasks = [
        TaskModel(
          id: 'a',
          title: 'Arroz',
          description: '',
          resolvedSearchKey: normalizeTitleSearchKey('Arroz'),
          groupId: 'g1',
          isCompleted: true,
        ),
        TaskModel(
          id: 'b',
          title: 'Arroz',
          description: '',
          resolvedSearchKey: normalizeTitleSearchKey('Arroz'),
          groupId: 'g1',
          isCompleted: true,
        ),
      ];

      final plan = await service.buildPlan(tasks: tasks, tags: const []);
      service.dispose();

      expect(plan.deleteTaskIds, {'b'});
      expect(plan.updatesById['a']?.isCompleted, isFalse);
      expect(
        plan.changes.any(
          (c) => c.type == ShoppingListCleanupChangeType.duplicateRemoved,
        ),
        isTrue,
      );
    });

    test('atribui etiqueta a item sem tag', () async {
      final service = ShoppingListCleanupService(
        assignTagsForTest: ({
          required List<String> itemTitles,
          required List<TagModel> tags,
        }) async {
          return itemTitles
              .map((t) => t.toLowerCase().contains('leite') ? 'Frescos' : null)
              .toList();
        },
      );
      const tags = [
        TagModel(id: 't1', name: 'Frescos', color: 0xFF0000, groupId: 'g1'),
        TagModel(id: 't2', name: 'Mercearia', color: 0xFF00FF, groupId: 'g1'),
      ];
      final tasks = [
        TaskModel(
          id: '1',
          title: 'Leite',
          description: '',
          groupId: 'g1',
        ),
      ];

      final plan = await service.buildPlan(tasks: tasks, tags: tags);
      service.dispose();

      expect(plan.updatesById['1']?.tagIds, ['t1']);
      expect(
        plan.changes.any(
          (c) => c.type == ShoppingListCleanupChangeType.tagAssigned,
        ),
        isTrue,
      );
    });
  });
}
