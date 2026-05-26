import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_intent_router.dart';

void main() {
  group('VoiceIntentRouter', () {
    test('supermercado forced group routes to shopping', () {
      final c = VoiceIntentRouter.classify(
        transcript: 'arroz e feijão',
        hasForcedGroup: true,
        forcedGroupName: 'Supermercado',
        contextGroupName: 'Supermercado',
      );
      expect(c.mode, VoiceExtractMode.shoppingOrGeneral);
      expect(c.intentLabel, 'shopping_llm');
    });

    test('melhorias forced group routes to note capture', () {
      final c = VoiceIntentRouter.classify(
        transcript:
            'O snackbar quando crio tarefa não mostra o grupo porque fica confuso',
        hasForcedGroup: true,
        forcedGroupName: 'Melhorias',
        contextGroupName: 'Melhorias',
      );
      expect(c.mode, VoiceExtractMode.noteCapture);
      expect(c.intentLabel, 'note_llm');
    });

    test('reminder inside melhorias group', () {
      final c = VoiceIntentRouter.classify(
        transcript: 'me lembre de comer daqui duas horas',
        hasForcedGroup: true,
        forcedGroupName: 'Melhorias',
      );
      expect(c.mode, VoiceExtractMode.reminder);
      expect(c.intentLabel, 'reminder_fast');
    });

    test('reminder phrase routes to reminder fast', () {
      final c = VoiceIntentRouter.classify(
        transcript: 'me lembre de cortar o cabelo amanhã às 10',
        hasForcedGroup: false,
      );
      expect(c.mode, VoiceExtractMode.reminder);
      expect(c.intentLabel, 'reminder_fast');
    });

    test('long list routes to shopping', () {
      final c = VoiceIntentRouter.classify(
        transcript: 'adicione arroz, feijão, leite, ovos e pão',
        hasForcedGroup: false,
      );
      expect(c.intentLabel, 'shopping_llm');
    });

    test('generic forced group is not shopping', () {
      final c = VoiceIntentRouter.classify(
        transcript: 'revisar documentação do projeto',
        hasForcedGroup: true,
        forcedGroupName: 'Trabalho',
      );
      expect(c.intentLabel, 'forced_group_general');
    });
  });
}
