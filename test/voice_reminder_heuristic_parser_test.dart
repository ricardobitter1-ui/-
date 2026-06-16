import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_reminder_heuristic_parser.dart';
import 'package:todo_app/data/models/group_model.dart';

GroupModel _group(String id, String name) => GroupModel(
      id: id,
      name: name,
      icon: 'group',
      color: '#0052FF',
      ownerId: 'o1',
      members: const ['o1'],
      createdAt: DateTime(2024),
    );

void main() {
  group('VoiceReminderHeuristicParser', () {
    test('parses reminder with time and tomorrow', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de cortar o cabelo amanhã às 10',
        referenceDate: DateTime(2026, 5, 15),
      );
      expect(r.confident, isTrue);
      expect(r.task, isNotNull);
      expect(r.task!.title.toLowerCase(), contains('cortar'));
      expect(r.task!.date, '2026-05-16');
      expect(r.task!.time, '10:00');
    });

    test('parses relative minutes ("em 2 minutos")', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de comprar leite em 2 minutos',
        referenceDate: DateTime(2026, 5, 15, 10, 0),
      );
      expect(r.confident, isTrue);
      expect(r.task, isNotNull);
      expect(r.task!.date, '2026-05-15');
      expect(r.task!.time, '10:02');
    });

    test('parses relative hours ("daqui a 2 horas")', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de pagar aluguel daqui a 2 horas',
        referenceDate: DateTime(2026, 5, 15, 10, 0),
      );
      expect(r.confident, isTrue);
      expect(r.task, isNotNull);
      expect(r.task!.date, '2026-05-15');
      expect(r.task!.time, '12:00');
    });

    test('parses "daqui um minuto"', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de desligar a panela daqui um minuto',
        referenceDate: DateTime(2026, 6, 16, 14, 30),
      );
      expect(r.confident, isTrue);
      expect(r.task, isNotNull);
      expect(r.task!.title.toLowerCase(), contains('desligar'));
      expect(r.task!.title.toLowerCase(), isNot(contains('minuto')));
      expect(r.task!.date, '2026-06-16');
      expect(r.task!.time, '14:31');
    });

    test('parses "daqui 3 minutos" without "a"', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de desligar a panela daqui 3 minutos',
        referenceDate: DateTime(2026, 6, 16, 14, 30),
      );
      expect(r.confident, isTrue);
      expect(r.task!.time, '14:33');
    });

    test('parses "daqui duas horas" with word number', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de comer daqui duas horas',
        referenceDate: DateTime(2026, 6, 16, 10, 0),
      );
      expect(r.confident, isTrue);
      expect(r.task!.time, '12:00');
    });

    test('parses Chico group and strips schedule from title', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript:
            'me lembre de comprar a ração para o Chico amanhã às 10 da manhã',
        referenceDate: DateTime(2026, 5, 15),
        groups: [_group('p', 'Pessoal'), _group('c', 'Chico')],
      );
      expect(r.confident, isTrue);
      expect(r.task!.groupName, 'Chico');
      expect(r.task!.title.toLowerCase(), isNot(contains('amanh')));
      expect(r.task!.title.toLowerCase(), isNot(contains('manhã')));
      expect(r.task!.date, '2026-05-16');
      expect(r.task!.time, '10:00');
    });

    test('returns not confident without date or time', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de comprar presente',
        referenceDate: DateTime(2026, 5, 15),
      );
      expect(r.confident, isFalse);
    });
  });
}
