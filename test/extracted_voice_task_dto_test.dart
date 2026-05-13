import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/models/extracted_voice_task_dto.dart';

void main() {
  group('ExtractedVoiceTaskDto.parseTasksJson', () {
    test('parses tasks with title and groupName', () {
      const raw = '''
{
  "tasks": [
    { "title": "Arroz", "description": "", "date": null, "time": null, "groupName": "Mercado" },
    { "title": "Feijão", "description": "", "date": null, "time": null, "groupName": "Mercado" }
  ]
}
''';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.length, 2);
      expect(list[0].title, 'Arroz');
      expect(list[0].groupName, 'Mercado');
      expect(list[1].title, 'Feijão');
    });

    test('accepts titulo and data keys', () {
      const raw = '{"tasks":[{"titulo":"Passear cão","data":"2026-05-11","hora":"08:00","grupo":null}]}';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.title, 'Passear cão');
      expect(list.single.date, '2026-05-11');
      expect(list.single.time, '08:00');
      expect(list.single.groupName, isNull);
    });

    test('parses optional tagName from JSON', () {
      const raw =
          '{"tasks":[{"title":"Leite","tagName":"Laticínios","groupName":null}]}';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.tagName, 'Laticínios');
    });

    test('strips markdown fences if model wraps output', () {
      const raw = '```json\n{"tasks":[{"title":"X","description":"","date":null,"time":null,"groupName":null}]}\n```';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.title, 'X');
    });
  });
}
