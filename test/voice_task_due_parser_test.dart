import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_task_due_parser.dart';

void main() {
  group('VoiceTaskDueParser', () {
    test('date only', () {
      final r = VoiceTaskDueParser.parse('2026-05-11', null);
      expect(r.reminderType, 'datetime');
      expect(r.dueHasTime, false);
      expect(r.dueDate, DateTime(2026, 5, 11));
    });

    test('date and time', () {
      final r = VoiceTaskDueParser.parse('2026-05-11', '08:30');
      expect(r.dueHasTime, true);
      expect(r.dueDate, DateTime(2026, 5, 11, 8, 30));
    });

    test('invalid date yields empty', () {
      final r = VoiceTaskDueParser.parse('not-a-date', '12:00');
      expect(r.dueDate, isNull);
      expect(r.reminderType, isNull);
    });
  });
}
