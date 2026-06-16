import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/group_activity_feed.dart';
import 'package:todo_app/data/models/task_model.dart';
import 'package:todo_app/data/models/user_public_profile.dart';

void main() {
  test('agrupa adições por autor no mesmo dia', () {
    final now = DateTime(2026, 6, 12, 10);
    final tasks = [
      TaskModel(
        id: '1',
        title: 'Leite',
        description: '',
        createdBy: 'alice',
        createdAt: now,
      ),
      TaskModel(
        id: '2',
        title: 'Pão',
        description: '',
        createdBy: 'alice',
        createdAt: now.add(const Duration(hours: 1)),
      ),
    ];
    final events = buildGroupActivityFeed(
      tasks: tasks,
      profiles: {
        'alice': const UserPublicProfile(
          uid: 'alice',
          displayName: 'Alice',
        ),
      },
      now: now.add(const Duration(hours: 2)),
    );
    expect(events, hasLength(1));
    expect(events.first.label, 'Alice adicionou 2 itens');
  });
}
