import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_task_title_sanitizer.dart';

void main() {
  group('VoiceTaskTitleSanitizer', () {
    test('removes tomorrow and morning period from title', () {
      final title = VoiceTaskTitleSanitizer.sanitize(
        'Comprar ração pro Chico amanhã, da manhã',
        stripDateHints: true,
        stripTimeHints: true,
      );
      expect(title, 'Comprar ração pro Chico');
    });

    test('removes time with às preposition', () {
      final title = VoiceTaskTitleSanitizer.sanitize(
        'Cortar o cabelo amanhã às 10',
        stripDateHints: true,
        stripTimeHints: true,
      );
      expect(title, 'Cortar o cabelo');
    });

    test('sanitizeShoppingItemTitle strips comprar prefix', () {
      expect(
        VoiceTaskTitleSanitizer.sanitizeShoppingItemTitle('Comprar macarrão'),
        'Macarrão',
      );
      expect(
        VoiceTaskTitleSanitizer.sanitizeShoppingItemTitle('pegar o feijão'),
        'Feijão',
      );
      expect(
        VoiceTaskTitleSanitizer.sanitizeShoppingItemTitle('Arroz integral'),
        'Arroz integral',
      );
    });
  });
}
