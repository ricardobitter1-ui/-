import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/task_day_visibility.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/data/models/task_recurrence.dart';

TaskModel _task({
  required String id,
  DateTime? dueDate,
  String? reminderType,
  bool dueHasTime = false,
  TaskRecurrenceRule? recurrence,
  String? groupId,
}) {
  return TaskModel(
    id: id,
    title: 't',
    description: '',
    dueDate: dueDate,
    reminderType: reminderType,
    dueHasTime: dueHasTime,
    recurrence: recurrence,
    groupId: groupId,
  );
}

void main() {
  group('taskVisibleOnDay', () {
    test('pontual: só no dia da dueDate', () {
      final t = _task(
        id: '1',
        dueDate: DateTime(2026, 4, 15, 10, 0),
        reminderType: 'datetime',
      );
      expect(taskVisibleOnDay(t, DateTime(2026, 4, 15)), isTrue);
      expect(taskVisibleOnDay(t, DateTime(2026, 4, 16)), isFalse);
    });

    test('recorrente diária aparece em dias seguintes', () {
      final t = _task(
        id: '2',
        dueDate: DateTime(2026, 4, 1, 8, 0),
        reminderType: 'datetime',
        dueHasTime: true,
        recurrence: const TaskRecurrenceRule(
          interval: 1,
          unit: RecurrenceUnit.day,
        ),
      );
      expect(taskVisibleOnDay(t, DateTime(2026, 4, 1)), isTrue);
      expect(taskVisibleOnDay(t, DateTime(2026, 4, 2)), isTrue);
      expect(taskVisibleOnDay(t, DateTime(2026, 4, 3)), isTrue);
    });

    test('sem dueDate: pessoal (sem grupo) aparece só no dia atual', () {
      final clock = DateTime(2026, 4, 1, 10, 0);
      final t = _task(id: '3', reminderType: 'datetime');
      expect(
        taskVisibleOnDay(t, DateTime(2026, 4, 1), now: clock),
        isTrue,
      );
      expect(
        taskVisibleOnDay(t, DateTime(2026, 4, 2), now: clock),
        isFalse,
      );
    });

    test('sem dueDate em grupo não entra em Hoje por inbox', () {
      final clock = DateTime(2026, 4, 1, 10, 0);
      final t = _task(
        id: '3b',
        reminderType: 'datetime',
        groupId: 'g1',
      );
      expect(taskVisibleOnDay(t, DateTime(2026, 4, 1), now: clock), isFalse);
    });
  });

  group('taskMatchesScheduledFilter', () {
    final clock = DateTime(2026, 4, 10, 12, 0);

    test('pontual com vencimento hoje fica fora', () {
      final t = _task(
        id: 'a',
        dueDate: DateTime(2026, 4, 10, 9, 0),
        reminderType: 'datetime',
      );
      expect(taskMatchesScheduledFilter(t, clock: clock), isFalse);
    });

    test('pontual com vencimento amanhã entra', () {
      final t = _task(
        id: 'b',
        dueDate: DateTime(2026, 4, 11, 9, 0),
        reminderType: 'datetime',
      );
      expect(taskMatchesScheduledFilter(t, clock: clock), isTrue);
    });

    test('recorrente com âncora hoje ainda tem próxima ocorrência', () {
      final t = _task(
        id: 'c',
        dueDate: DateTime(2026, 4, 10, 8, 0),
        reminderType: 'datetime',
        dueHasTime: true,
        recurrence: const TaskRecurrenceRule(
          interval: 1,
          unit: RecurrenceUnit.day,
          repeatHour: 8,
          repeatMinute: 0,
        ),
      );
      expect(taskMatchesScheduledFilter(t, clock: clock), isTrue);
    });
  });
}
