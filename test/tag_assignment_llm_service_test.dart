import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/services/voice/tag_assignment_llm_service.dart';

void main() {
  group('TagAssignmentLlmService.friendlyErrorMessage', () {
    test('429 mostra mensagem de limite', () {
      final err = Exception('OpenRouter tags (429): rate-limited');
      expect(
        TagAssignmentLlmService.friendlyErrorMessage(err),
        contains('Limite de uso'),
      );
    });

    test('404 de modelo mostra dica de config', () {
      final err = Exception(
        'OpenRouter tags (404): No endpoints found for foo',
      );
      expect(
        TagAssignmentLlmService.friendlyErrorMessage(err),
        contains('Modelo de IA'),
      );
    });
  });
}
