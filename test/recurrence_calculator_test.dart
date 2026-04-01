import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/recurrence_calculator.dart';
import 'package:todo_app/data/models/task_recurrence.dart';

void main() {
  group('RecurrenceCalculator', () {
    test('diária: três ocorrências com hora', () {
      final anchor = DateTime(2026, 1, 10);
      final rule = TaskRecurrenceRule(
        interval: 1,
        unit: RecurrenceUnit.day,
        repeatHour: 9,
        repeatMinute: 0,
      );
      final list = RecurrenceCalculator.upcomingOccurrences(
        anchorDate: anchor,
        rule: rule,
        from: DateTime(2026, 1, 10, 0, 0),
        maxCount: 3,
      );
      expect(list.length, 3);
      expect(list[0], DateTime(2026, 1, 10, 9, 0));
      expect(list[1], DateTime(2026, 1, 11, 9, 0));
      expect(list[2], DateTime(2026, 1, 12, 9, 0));
    });

    test('semanal: dois dias da semana', () {
      // 2026-01-05 é segunda
      final anchor = DateTime(2026, 1, 5);
      final mask = (1 << 1) | (1 << 3); // seg e qua (bit 1=seg, 3=qua)
      final rule = TaskRecurrenceRule(
        interval: 1,
        unit: RecurrenceUnit.week,
        weekdayMask: mask,
        repeatHour: 8,
        repeatMinute: 30,
      );
      final list = RecurrenceCalculator.upcomingOccurrences(
        anchorDate: anchor,
        rule: rule,
        from: DateTime(2026, 1, 1),
        maxCount: 4,
      );
      expect(list.length, 4);
      expect(list[0].weekday, DateTime.monday);
      expect(list[1].weekday, DateTime.wednesday);
    });

    test('término após N ocorrências', () {
      final anchor = DateTime(2026, 2, 1);
      final rule = TaskRecurrenceRule(
        interval: 1,
        unit: RecurrenceUnit.day,
        repeatHour: 12,
        repeatMinute: 0,
        endType: RecurrenceEndType.afterCount,
        maxOccurrences: 2,
      );
      final list = RecurrenceCalculator.upcomingOccurrences(
        anchorDate: anchor,
        rule: rule,
        from: DateTime(2026, 1, 1),
        maxCount: 20,
      );
      expect(list.length, 2);
      expect(list[0], DateTime(2026, 2, 1, 12, 0));
      expect(list[1], DateTime(2026, 2, 2, 12, 0));
    });

    test('término em data', () {
      final anchor = DateTime(2026, 3, 1);
      final rule = TaskRecurrenceRule(
        interval: 1,
        unit: RecurrenceUnit.day,
        repeatHour: 10,
        repeatMinute: 0,
        endType: RecurrenceEndType.untilDate,
        endDate: DateTime(2026, 3, 2),
      );
      final list = RecurrenceCalculator.upcomingOccurrences(
        anchorDate: anchor,
        rule: rule,
        from: DateTime(2026, 1, 1),
        maxCount: 10,
      );
      expect(list.length, 2);
      expect(list.last.day, 2);
    });
  });
}
