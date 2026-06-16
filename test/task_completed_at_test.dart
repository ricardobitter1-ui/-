import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/models/task_model.dart';

void main() {
  test('toMap inclui completedAt quando definido', () {
    final at = DateTime(2026, 6, 12, 15, 30);
    final task = TaskModel(
      id: 't1',
      title: 'Comprar leite',
      description: '',
      isCompleted: true,
      completedAt: at,
    );
    final map = task.toMap();
    expect(map['completedAt'], isA<Timestamp>());
    expect((map['completedAt'] as Timestamp).toDate(), at);
  });

  test('toMap omite completedAt quando null', () {
    final task = TaskModel(
      id: 't1',
      title: 'Tarefa',
      description: '',
    );
    expect(task.toMap().containsKey('completedAt'), isFalse);
  });

  test('copyWith limpa completedAt ao reabrir', () {
    final task = TaskModel(
      id: 't1',
      title: 'Tarefa',
      description: '',
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    final reopened = task.copyWith(isCompleted: false, completedAt: null);
    expect(reopened.isCompleted, isFalse);
    expect(reopened.completedAt, isNull);
  });
}
