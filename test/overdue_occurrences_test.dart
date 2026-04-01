import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/overdue_occurrences.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/data/models/task_recurrence.dart';

void main() {
  test('recorrente diária: ontem não concluído aparece em atrasadas', () {
    final t = TaskModel(
      id: '1',
      title: 'x',
      description: '',
      reminderType: 'datetime',
      dueDate: DateTime(2026, 4, 1, 8, 0),
      dueHasTime: true,
      recurrence: const TaskRecurrenceRule(
        interval: 1,
        unit: RecurrenceUnit.day,
        repeatHour: 8,
        repeatMinute: 0,
      ),
    );
    // Antes das 8h do dia 2: só o dia 1 está em atraso (dia 2 ainda não passou o horário).
    final now = DateTime(2026, 4, 2, 7, 0);
    final rows = collectOverdueOccurrenceRows([t], now, maxDaysBack: 5);
    expect(rows.length, 1);
    expect(rows.first.day, DateTime(2026, 4, 1));
  });

  test('recorrente: dia concluído não entra em atrasadas', () {
    final t = TaskModel(
      id: '1',
      title: 'x',
      description: '',
      reminderType: 'datetime',
      dueDate: DateTime(2026, 4, 1, 8, 0),
      dueHasTime: true,
      recurrence: const TaskRecurrenceRule(
        interval: 1,
        unit: RecurrenceUnit.day,
        repeatHour: 8,
        repeatMinute: 0,
      ),
      completedOccurrenceDateKeys: const ['2026-04-01'],
    );
    final now = DateTime(2026, 4, 2, 7, 0);
    final rows = collectOverdueOccurrenceRows([t], now, maxDaysBack: 5);
    expect(rows, isEmpty);
  });
}
