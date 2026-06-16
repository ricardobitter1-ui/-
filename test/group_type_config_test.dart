import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/group_type_config.dart';
import 'package:todo_app/data/models/group_type.dart';

void main() {
  test('continuous não conta na home e permite re-add', () {
    final cfg = GroupTypeConfig.of(GroupType.continuous);
    expect(cfg.countsInHome, isFalse);
    expect(cfg.reAdd, isTrue);
    expect(cfg.progressCard, isFalse);
  });

  test('tasks padrão conta na home', () {
    final cfg = GroupTypeConfig.of(GroupType.tasks);
    expect(cfg.countsInHome, isTrue);
    expect(cfg.reAdd, isFalse);
    expect(cfg.progressCard, isTrue);
  });
}
