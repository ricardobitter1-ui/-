import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/task_schedule_sort.dart';
import 'package:todo_app/data/models/task_model.dart';

TaskModel _task({
  required String id,
  DateTime? dueDate,
  bool dueHasTime = false,
}) {
  return TaskModel(
    id: id,
    title: id,
    description: '',
    dueDate: dueDate,
    dueHasTime: dueHasTime,
    reminderType: dueDate != null ? 'datetime' : null,
  );
}

void main() {
  group('compareTasksByScheduleOrder', () {
    final day = DateTime(2026, 5, 16);

    test('tasks without time appear before tasks with time', () {
      final noTime = _task(
        id: 'a',
        dueDate: DateTime(2026, 5, 16),
        dueHasTime: false,
      );
      final atNine = _task(
        id: 'b',
        dueDate: DateTime(2026, 5, 16, 9),
        dueHasTime: true,
      );
      expect(
        compareTasksByScheduleOrder(noTime, atNine, calendarDay: day),
        lessThan(0),
      );
    });

    test('earlier time appears before later time', () {
      final atEight = _task(
        id: 'a',
        dueDate: DateTime(2026, 5, 16, 8),
        dueHasTime: true,
      );
      final atNine = _task(
        id: 'b',
        dueDate: DateTime(2026, 5, 16, 9),
        dueHasTime: true,
      );
      expect(
        compareTasksByScheduleOrder(atEight, atNine, calendarDay: day),
        lessThan(0),
      );
    });

    test('sortTasksByScheduleOrder orders a list', () {
      final tasks = [
        _task(
          id: 'nine',
          dueDate: DateTime(2026, 5, 16, 9),
          dueHasTime: true,
        ),
        _task(
          id: 'no-time',
          dueDate: DateTime(2026, 5, 16),
          dueHasTime: false,
        ),
        _task(
          id: 'eight',
          dueDate: DateTime(2026, 5, 16, 8),
          dueHasTime: true,
        ),
      ];
      sortTasksByScheduleOrder(tasks, calendarDay: day);
      expect(tasks.map((t) => t.id).toList(), ['no-time', 'eight', 'nine']);
    });
  });
}
