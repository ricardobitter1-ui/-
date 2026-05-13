import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/models/tag_model.dart';
import 'package:todo_app/data/services/openrouter_voice_task_service.dart';

void main() {
  group('OpenRouterVoiceTaskService.parseTagAssignmentsResponse', () {
    test('maps by normalized title order', () {
      const tags = [
        TagModel(id: 't1', groupId: 'g', name: 'Secos', color: 1),
      ];
      const raw = '''
{"assignments":[
  {"title":"Arroz","tagName":"Secos"},
  {"title":"Feijão","tagName":null}
]}
''';
      final out = OpenRouterVoiceTaskService.parseTagAssignmentsResponse(
        raw,
        2,
        tags,
        ['Arroz', 'Feijão'],
      );
      expect(out[0], 'Secos');
      expect(out[1], isNull);
    });
  });
}
