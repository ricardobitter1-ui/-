import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:todo_app/utils/scheduled_badge_label.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  /// Quarta-feira 12 de junho de 2024, meio-dia (local).
  final DateTime anchor = DateTime(2024, 6, 12, 12, 0);
  /// Domingo como primeiro dia da semana (Material index 0).
  const int firstDaySunday = 0;

  group('formatScheduledBadge', () {
    test('atrasada um dia', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 11, 9, 0),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, true);
      expect(r.label, 'há 1 dia');
    });

    test('atrasada três dias', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 9, 22, 0),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, true);
      expect(r.label, 'há 3 dias');
    });

    test('hoje com horário', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 12, 15, 30),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, false);
      expect(r.label, 'hoje, 15:30');
    });

    test('hoje com horário já passado (mesmo dia)', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 12, 8, 0),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, true);
      expect(r.label, 'hoje, 08:00');
    });

    test('isDueDateTimePast', () {
      expect(
        isDueDateTimePast(
          DateTime(2024, 6, 12, 8, 0),
          DateTime(2024, 6, 12, 12, 0),
        ),
        true,
      );
      expect(
        isDueDateTimePast(
          DateTime(2024, 6, 12, 15, 0),
          DateTime(2024, 6, 12, 12, 0),
        ),
        false,
      );
    });

    test('amanhã', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 13, 8, 5),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, false);
      expect(r.label, 'amanhã, 08:05');
    });

    test('depois de amanhã', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 14, 10, 0),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, false);
      expect(r.label, 'depois de amanhã, 10:00');
    });

    test('mesma semana (sábado) nome do dia', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 15, 18, 0),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, false);
      expect(r.label, 'sábado, 18:00');
    });

    test('outra semana data abreviada (mesmo ano sem repetir ano)', () {
      final r = formatScheduledBadge(
        due: DateTime(2024, 6, 18, 11, 15),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, false);
      expect(r.label, contains('11:15'));
      expect(r.label, contains('18'));
      expect(r.label, isNot(contains('2024')));
    });

    test('ano diferente inclui ano na data', () {
      final r = formatScheduledBadge(
        due: DateTime(2027, 1, 3, 14, 0),
        now: anchor,
        firstDayOfWeekIndex: firstDaySunday,
      );
      expect(r.isOverdue, false);
      expect(r.label, contains('2027'));
      expect(r.label, contains('14:00'));
    });
  });
}
