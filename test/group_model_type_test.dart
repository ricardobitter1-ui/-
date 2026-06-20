import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/models/group_model.dart';
import 'package:todo_app/data/models/group_type.dart';

void main() {
  test('fromMap sem type usa tasks', () {
    final g = GroupModel.fromMap('g1', {
      'name': 'Casa',
      'ownerId': 'u1',
      'members': ['u1'],
      'createdAt': Timestamp.now(),
    });
    expect(g.type, GroupType.tasks);
    expect(g.typeConfig.countsInHome, isTrue);
  });

  test('fromMap com continuous', () {
    final g = GroupModel.fromMap('g2', {
      'name': 'Mercado',
      'ownerId': 'u1',
      'members': ['u1'],
      'type': 'continuous',
      'createdAt': Timestamp.now(),
    });
    expect(g.type, GroupType.continuous);
    expect(g.typeConfig.countsInHome, isFalse);
    expect(g.typeConfig.reAdd, isTrue);
  });

  test('toMap grava type', () {
    final g = GroupModel(
      id: 'g3',
      name: 'Lista',
      icon: 'cart',
      color: '#fff',
      ownerId: 'u1',
      members: ['u1'],
      type: GroupType.continuous,
      createdAt: DateTime(2026, 1, 1),
    );
    expect(g.toMap()['type'], 'continuous');
  });
}
