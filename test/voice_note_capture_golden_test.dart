import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/models/extracted_voice_task_dto.dart';

void main() {
  group('note capture JSON parsing', () {
    test('single note with title and polished description', () {
      const raw = '''
{
  "tasks": [
    {
      "title": "Snackbar: falta contexto ao criar tarefa",
      "description": "Ao criar a tarefa, o snackbar não mostra o grupo.",
      "date": null,
      "time": null,
      "groupName": "Melhorias"
    }
  ]
}
''';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.length, 1);
      expect(list.first.title, contains('Snackbar'));
      expect(list.first.description, isNotEmpty);
      expect(list.first.groupName, 'Melhorias');
    });

    test('two notes from explicit split', () {
      const raw = '''
{
  "tasks": [
    {
      "title": "Snackbar: pouca informação",
      "description": "Falta contexto ao criar tarefa.",
      "groupName": "Melhorias"
    },
    {
      "title": "Hoje: rail corta último ícone",
      "description": "O rail de grupos corta o último ícone no ecrã Hoje.",
      "groupName": "Melhorias"
    }
  ]
}
''';
      final list = ExtractedVoiceTaskDto.parseTasksJson(raw);
      expect(list.length, 2);
      expect(list[0].title, contains('Snackbar'));
      expect(list[1].title, contains('Hoje'));
    });
  });
}
