import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_task_group_resolver.dart';
import 'package:todo_app/data/models/group_model.dart';

GroupModel _g(String id, String name) => GroupModel(
      id: id,
      name: name,
      icon: 'group',
      color: '#0052FF',
      ownerId: 'o1',
      members: const ['o1'],
      createdAt: DateTime(2024),
    );

void main() {
  group('resolveGroupId', () {
    test('matches name ignoring case and accents', () {
      final groups = [_g('1', 'Mercado'), _g('2', 'Trabalho')];
      expect(
        resolveGroupId(
          groupNameFromLlm: 'mercado',
          groups: groups,
          forcedGroupId: null,
        ),
        '1',
      );
      expect(
        resolveGroupId(
          groupNameFromLlm: 'São Paulo',
          groups: [_g('3', 'São Paulo')],
          forcedGroupId: null,
        ),
        '3',
      );
    });

    test('uses forcedGroupId when groupName empty', () {
      final groups = [_g('1', 'Mercado')];
      expect(
        resolveGroupId(
          groupNameFromLlm: null,
          groups: groups,
          forcedGroupId: '1',
        ),
        '1',
      );
    });

    test('fuzzy unique substring', () {
      final groups = [_g('9', 'Supermercado Central')];
      expect(
        resolveGroupId(
          groupNameFromLlm: 'supermercado',
          groups: groups,
          forcedGroupId: null,
        ),
        '9',
      );
    });
  });
}
