import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/reschedule_overdue_batch.dart';
import 'package:todo_app/data/models/task_model.dart';

void main() {
  test('taskRescheduledToDay preserva hora', () {
    final task = TaskModel(
      id: '1',
      title: 'Reunião',
      description: '',
      dueDate: DateTime(2026, 6, 1, 15, 30),
      dueHasTime: true,
      reminderType: 'datetime',
    );
    final target = DateTime(2026, 6, 15);
    final updated = taskRescheduledToDay(task, target);
    expect(updated.dueDate?.year, 2026);
    expect(updated.dueDate?.month, 6);
    expect(updated.dueDate?.day, 15);
    expect(updated.dueDate?.hour, 15);
    expect(updated.dueDate?.minute, 30);
  });
}
