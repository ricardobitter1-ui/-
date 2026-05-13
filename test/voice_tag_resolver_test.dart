import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_tag_resolver.dart';
import 'package:todo_app/data/models/tag_model.dart';

void main() {
  group('resolveTagIdByName', () {
    test('matches ignoring case and accents', () {
      final tags = [
        const TagModel(id: 'a', groupId: 'g', name: 'Mercearia seca', color: 1),
        const TagModel(id: 'b', groupId: 'g', name: 'Frescos', color: 2),
      ];
      expect(resolveTagIdByName('mercearia seca', tags), 'a');
      expect(resolveTagIdByName('FRESCOS', tags), 'b');
    });

    test('returns null when unknown', () {
      final tags = [
        const TagModel(id: 'a', groupId: 'g', name: 'X', color: 1),
      ];
      expect(resolveTagIdByName('Y', tags), isNull);
    });
  });
}
