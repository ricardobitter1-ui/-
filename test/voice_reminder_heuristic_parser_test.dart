import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_reminder_heuristic_parser.dart';

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

    test('returns not confident without date or time', () {
      final r = VoiceReminderHeuristicParser.parse(
        transcript: 'me lembre de comprar presente',
        referenceDate: DateTime(2026, 5, 15),
      );
      expect(r.confident, isFalse);
    });
  });
}
