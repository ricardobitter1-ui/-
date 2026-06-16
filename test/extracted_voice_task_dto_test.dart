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

    test('parses tagExplicit from JSON', () {
      const raw = '''
{
  "tasks": [
    {
      "title": "Snackbar: falta contexto",
      "tagName": "Exm App",
      "tagExplicit": true,
      "groupName": "Melhorias"
    }
  ]
}
''';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.tagExplicit, isTrue);
      expect(list.single.tagName, 'Exm App');
    });

    test('parses tagExplicito alias', () {
      const raw =
          '{"tasks":[{"title":"X","tagName":"Y","tagExplicito":"sim"}]}';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.tagExplicit, isTrue);
    });

    test('golden explicit tag creation payload', () {
      const raw = '''
{
  "tasks": [
    {
      "title": "Snackbar: falta contexto ao criar",
      "description": "O snackbar não mostra o grupo ao criar tarefa.",
      "date": null,
      "time": null,
      "groupName": "Melhorias",
      "tagName": "Exm App",
      "tagExplicit": true
    }
  ]
}
''';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.length, 1);
      expect(list.first.tagExplicit, isTrue);
      expect(list.first.groupName, 'Melhorias');
    });

    test('golden shopping item without meta verb in title', () {
      const raw = '''
{
  "tasks": [
    {
      "title": "Arroz",
      "description": "",
      "date": null,
      "time": null,
      "groupName": "Mercado",
      "tagName": null,
      "tagExplicit": false
    }
  ]
}
''';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.title, 'Arroz');
      expect(list.single.tagExplicit, isFalse);
    });

    test('golden reminder keeps verb in title', () {
      const raw = '''
{
  "tasks": [
    {
      "title": "Adicionar arroz na receita",
      "description": "",
      "date": "2026-06-12",
      "time": null,
      "groupName": null,
      "tagName": null,
      "tagExplicit": false
    }
  ]
}
''';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.title, 'Adicionar arroz na receita');
      expect(list.single.date, '2026-06-12');
    });

    test('strips markdown fences if model wraps output', () {
      const raw = '```json\n{"tasks":[{"title":"X","description":"","date":null,"time":null,"groupName":null}]}\n```';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.single.title, 'X');
    });
  });
}
