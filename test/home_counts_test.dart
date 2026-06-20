import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/home_counts.dart';
import 'package:todo_app/data/models/group_model.dart';
import 'package:todo_app/data/models/group_type.dart';
import 'package:todo_app/data/models/task_model.dart';

TaskModel _task({
  required String id,
  bool completed = false,
  DateTime? dueDate,
  String? groupId,
}) {
  return TaskModel(
    id: id,
    title: 't$id',
    description: '',
    isCompleted: completed,
    dueDate: dueDate,
    reminderType: dueDate != null ? 'datetime' : null,
    groupId: groupId,
  );
}

GroupModel _group(String id, GroupType type) {
  return GroupModel(
    id: id,
    name: id,
    icon: 'group',
    color: '#cccccc',
    ownerId: 'u1',
    members: const ['u1'],
    type: type,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final now = DateTime(2026, 6, 12, 10);

  test('pendingAllCount conta só ativas', () {
    final tasks = [
      _task(id: '1'),
      _task(id: '2', completed: true),
    ];
    expect(pendingAllCount(tasks), 1);
  });

  test('pendingTodayCount usa só pendentes do dia', () {
    final today = DateTime(2026, 6, 12);
    final tasks = [
      _task(id: '1', dueDate: today),
      _task(id: '2', dueDate: today, completed: true),
      _task(id: '3', dueDate: today.add(const Duration(days: 1))),
    ];
    expect(pendingTodayCount(tasks, now: now), 1);
  });

  test('exclui grupo continuous das contagens', () {
    final groupById = {'shop': _group('shop', GroupType.continuous)};
    final tasks = [
      _task(id: '1', groupId: 'shop'),
      _task(id: '2'),
    ];
    expect(pendingAllCount(tasks, groupById: groupById), 1);
  });
}
