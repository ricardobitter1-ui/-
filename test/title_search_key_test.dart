import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/utils/title_search_key.dart';

void main() {
  group('normalizeTitleSearchKey', () {
    test('trim, minúsculas e remove acentos', () {
      expect(normalizeTitleSearchKey(' Comprar Café  '), 'comprar cafe');
    });

    test('título vazio', () {
      expect(normalizeTitleSearchKey(''), '');
      expect(normalizeTitleSearchKey('   '), '');
    });

    test('CAFÉ vira cafe', () {
      expect(normalizeTitleSearchKey('CAFÉ'), 'cafe');
    });
  });
}
