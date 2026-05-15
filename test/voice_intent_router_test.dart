import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/business_logic/voice_intent_router.dart';

void main() {
  group('VoiceIntentRouter', () {
    test('forced group routes to shopping', () {
      final c = VoiceIntentRouter.classify(
        transcript: 'arroz e feijão',
        hasForcedGroup: true,
      );
      expect(c.mode, VoiceExtractMode.shoppingOrGeneral);
      expect(c.intentLabel, 'shopping_llm');
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
  });
}
