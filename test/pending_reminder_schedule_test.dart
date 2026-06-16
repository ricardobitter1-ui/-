import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/local/pending_reminder_prefs.dart';

void main() {
  group('maxPendingReminderDiscreteRepeats', () {
    test('limita repetições de 30s até a próxima ocorrência', () {
      final nextFire = DateTime(2026, 6, 16, 10, 0);
      final untilExclusive = nextFire.add(const Duration(hours: 1));

      final count = maxPendingReminderDiscreteRepeats(
        nextFire: nextFire,
        untilExclusive: untilExclusive,
        repeatInterval: const Duration(seconds: 30),
        slotsRemaining: 200,
      );

      expect(count, 120);
    });

    test('respeita slots restantes', () {
      final nextFire = DateTime(2026, 6, 16, 10, 0);
      final untilExclusive = nextFire.add(const Duration(hours: 1));

      final count = maxPendingReminderDiscreteRepeats(
        nextFire: nextFire,
        untilExclusive: untilExclusive,
        repeatInterval: const Duration(seconds: 30),
        slotsRemaining: 10,
      );

      expect(count, 10);
    });

    test('sem untilExclusive usa todos os slots restantes', () {
      final count = maxPendingReminderDiscreteRepeats(
        nextFire: DateTime(2026, 6, 16, 10, 0),
        untilExclusive: null,
        repeatInterval: const Duration(seconds: 30),
        slotsRemaining: 48,
      );

      expect(count, 48);
    });
  });
}
