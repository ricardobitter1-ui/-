import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_task_duplicate_finder.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/utils/title_search_key.dart';

void main() {
  group('findDuplicateGroupTaskByTitle', () {
    test('finds by titleSearchKey', () {
      final existing = TaskModel(
        id: '1',
        title: 'Arroz',
        description: '',
        resolvedSearchKey: normalizeTitleSearchKey('Arroz'),
        groupId: 'g1',
        isCompleted: true,
      );
      final list = [existing];
      expect(
        findDuplicateGroupTaskByTitle(list, 'ARROZ')?.id,
        '1',
      );
    });

    test('returns null when no match', () {
      expect(
        findDuplicateGroupTaskByTitle(const [], 'Feijão'),
        isNull,
      );
    });
  });
}
