import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_extraction_plan.dart';
import 'package:todo_app/data/models/extracted_voice_task_dto.dart';
import 'package:todo_app/data/models/group_model.dart';
import 'package:todo_app/data/models/tag_model.dart';

GroupModel _group(String id, String name) => GroupModel(
      id: id,
      name: name,
      icon: 'group',
      color: '#7B8CDE',
      ownerId: 'u1',
      members: const ['u1'],
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('buildVoiceExtractionPlan', () {
    test('detects explicit tag to create when missing', () {
      const dto = ExtractedVoiceTaskDto(
        title: 'Snackbar: falta contexto',
        description: 'Detalhe',
        groupName: 'Melhorias',
        tagName: 'Exm App',
        tagExplicit: true,
      );
      final plan = buildVoiceExtractionPlan(
        tasks: const [dto],
        groups: [_group('g1', 'Melhorias')],
        forcedGroupId: 'g1',
        tagsByGroupId: const {'g1': []},
      );
      expect(plan.tagsToCreate.length, 1);
      expect(plan.tagsToCreate.single.name, 'Exm App');
      expect(plan.tagsToCreate.single.groupId, 'g1');
    });

    test('skips tag when already exists', () {
      const dto = ExtractedVoiceTaskDto(
        title: 'Arroz',
        groupName: 'Mercado',
        tagName: 'Mercearia',
        tagExplicit: true,
      );
      final plan = buildVoiceExtractionPlan(
        tasks: const [dto],
        groups: [_group('g2', 'Mercado')],
        forcedGroupId: 'g2',
        tagsByGroupId: {
          'g2': [
            const TagModel(
              id: 't1',
              groupId: 'g2',
              name: 'Mercearia',
              color: 0xFF1E88E5,
            ),
          ],
        },
      );
      expect(plan.tagsToCreate, isEmpty);
    });

    test('ignores non-explicit tag suggestions', () {
      const dto = ExtractedVoiceTaskDto(
        title: 'Arroz',
        groupName: 'Mercado',
        tagName: 'Mercearia',
        tagExplicit: false,
      );
      final plan = buildVoiceExtractionPlan(
        tasks: const [dto],
        groups: [_group('g2', 'Mercado')],
        forcedGroupId: 'g2',
        tagsByGroupId: const {'g2': []},
      );
      expect(plan.tagsToCreate, isEmpty);
    });
  });

  group('canonicalizeTaskTagNames', () {
    test('preserves explicit tag name when missing from list', () {
      const dto = ExtractedVoiceTaskDto(
        title: 'Nota',
        groupName: 'Melhorias',
        tagName: 'Exm App',
        tagExplicit: true,
      );
      final out = canonicalizeTaskTagNames(
        tasks: const [dto],
        groups: [_group('g1', 'Melhorias')],
        forcedGroupId: 'g1',
        tagsByGroupId: const {'g1': []},
      );
      expect(out.single.tagName, 'Exm App');
    });

    test('clears inferred tag when not found', () {
      const dto = ExtractedVoiceTaskDto(
        title: 'Arroz',
        groupName: 'Mercado',
        tagName: 'Mercearia',
        tagExplicit: false,
      );
      final out = canonicalizeTaskTagNames(
        tasks: const [dto],
        groups: [_group('g2', 'Mercado')],
        forcedGroupId: 'g2',
        tagsByGroupId: const {'g2': []},
      );
      expect(out.single.tagName, isNull);
    });
  });
}
